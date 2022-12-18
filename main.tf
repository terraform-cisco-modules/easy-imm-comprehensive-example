locals {
  model = yamldecode(data.utils_yaml_merge.model.output)
}

data "utils_yaml_merge" "model" {
  input = concat([
    for file in fileset(path.module, "defaults/*.yaml") : file(file)], [
    for file in fileset(path.module, "policies/*.yaml") : file(file)], [
    for file in fileset(path.module, "pools/*.yaml") : file(file)], [
    for file in fileset(path.module, "profiles/*.yaml") : file(file)], [
    for file in fileset(path.module, "templates/*.yaml") : file(file)]
  )
  merge_list_items = false
}

module "pools" {
  #source = "../terraform-intersight-pools"
  source       = "terraform-cisco-modules/pools/intersight"
  version      = "= 1.0.12"
  model        = local.model
  organization = var.organization
  tags         = var.tags
}

module "domain_profiles" {
  depends_on = [
    #module.policies,
    module.pools
  ]
  #source = "../terraform-intersight-profiles-domain"
  source       = "terraform-cisco-modules/profiles-domain/intersight"
  version      = "1.0.10"
  model        = local.model
  moids        = var.moids
  organization = var.organization
  #policies     = module.policies
  pools = module.pools
  tags  = var.tags
}

module "policies" {
  #source = "../terraform-intersight-policies"
  source       = "terraform-cisco-modules/policies/intersight"
  version      = "1.0.12"
  domains      = module.domain_profiles.domains
  model        = local.model
  organization = var.organization
  pools        = module.pools
  tags         = var.tags
  # Certificate Management Sensitive Variables
  base64_certificate_1 = var.base64_certificate_1
  base64_certificate_2 = var.base64_certificate_2
  base64_certificate_3 = var.base64_certificate_3
  base64_certificate_5 = var.base64_certificate_4
  base64_certificate_4 = var.base64_certificate_5
  base64_private_key_1 = var.base64_private_key_1
  base64_private_key_2 = var.base64_private_key_2
  base64_private_key_3 = var.base64_private_key_3
  base64_private_key_4 = var.base64_private_key_4
  base64_private_key_5 = var.base64_private_key_5
  # IPMI Sensitive Variables
  ipmi_key_1 = var.ipmi_key
  # iSCSI Boot Sensitive Variable
  iscsi_boot_password = var.iscsi_boot_password
  # LDAP Sensitive Variable
  binding_parameters_password = var.binding_parameters_password
  # Local User Sensitive Variables
  local_user_password_1 = var.local_user_password_1
  local_user_password_2 = var.local_user_password_2
  local_user_password_3 = var.local_user_password_3
  local_user_password_4 = var.local_user_password_4
  local_user_password_5 = var.local_user_password_5
  # Persistent Memory Sensitive Variable
  persistent_passphrase = var.persistent_passphrase
  # SNMP Sensitive Variables
  access_community_string_1 = var.access_community_string_1
  access_community_string_2 = var.access_community_string_2
  access_community_string_3 = var.access_community_string_3
  access_community_string_4 = var.access_community_string_4
  access_community_string_5 = var.access_community_string_5
  snmp_auth_password_1      = var.snmp_auth_password_1
  snmp_auth_password_2      = var.snmp_auth_password_2
  snmp_auth_password_3      = var.snmp_auth_password_3
  snmp_auth_password_4      = var.snmp_auth_password_4
  snmp_auth_password_5      = var.snmp_auth_password_5
  snmp_privacy_password_1   = var.snmp_privacy_password_1
  snmp_privacy_password_2   = var.snmp_privacy_password_2
  snmp_privacy_password_3   = var.snmp_privacy_password_3
  snmp_privacy_password_4   = var.snmp_privacy_password_4
  snmp_privacy_password_5   = var.snmp_privacy_password_5
  snmp_trap_community_1     = var.snmp_trap_community_1
  snmp_trap_community_2     = var.snmp_trap_community_2
  snmp_trap_community_3     = var.snmp_trap_community_3
  snmp_trap_community_4     = var.snmp_trap_community_4
  snmp_trap_community_5     = var.snmp_trap_community_5
  # Virtual Media Sensitive Variable
  vmedia_password_1 = var.vmedia_password_1
  vmedia_password_2 = var.vmedia_password_2
  vmedia_password_3 = var.vmedia_password_3
  vmedia_password_4 = var.vmedia_password_4
  vmedia_password_5 = var.vmedia_password_5
}

resource "null_resource" "chmod_intersight" {
  depends_on = [
    module.domain_profiles
  ]
  for_each = { for v in ["intersight.sh"] : v => v if var.operating_system == "Linux" && length(
    module.domain_profiles.depoy_switch_profiles
  ) > 0 }
  provisioner "local-exec" {
    command    = "chmod 755 intersight.sh"
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "deploy_domain_profiles" {
  depends_on = [
    module.domain_profiles
  ]
  for_each = {
    for k, v in module.domain_profiles.depoy_switch_profiles : k => v if var.operating_system == "Linux"
  }
  provisioner "local-exec" {
    command    = "./intersight.sh ${var.endpoint} 'PATCH' '/api/v1/fabric/SwitchProfiles/${each.value.moid}'"
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

#resource "null_resource" "wait_for_domain_profile" {
#  depends_on = [
#    module.domain_profiles
#  ]
#  for_each = module.domain_profiles.deploy_switch_profiles
#  provisioner "local-exec" {
#    command = <<-EOF
#    #/bin/bash
#    json_results=./intersight.sh ${var.endpoint} 'GET' '/api/v1/fabric/SwitchProfiles/${each.value.moid}'
#    config_state="$(grep ConfigState json_results)"
#    control_action="$(grep controlAction json_results)"
#    action="      "ControlAction": "No-op","
#    state="      "ConfigState": "Associated","
#    while (( "$control_action" != "$action" || "$config_state" != "$state")) ; do
#      $json_=
#    poll_tags="aws ec2 describe-tags --filters 'Name=resource-id,Values=${join(",", aws_instance.managers[*].id)}' 'Name=key,Values=trajano/terraform-docker-swarm-aws/cloudinit-complete' --output text --query 'Tags[*].Value'"
#    expected='${join(",", formatlist("true", aws_instance.managers[*].id))}'
#    $tags="$($poll_tags)"
#    while [[ "$tags" != "$expected" ]] ; do
#      $tags="$($poll_tags)"
#    done
#    EOF
#  }
#}

module "profiles" {
  depends_on = [
    module.policies
  ]
  #source = "../terraform-intersight-profiles"
  source       = "terraform-cisco-modules/profiles/intersight"
  version      = "1.0.18"
  model        = local.model
  moids        = var.moids
  organization = var.organization
  policies     = module.policies
  pools        = module.pools
  tags         = var.tags
}

resource "null_resource" "chmod_intersight2" {
  depends_on = [
    module.domain_profiles
  ]
  for_each = { for v in ["intersight.sh"] : v => v if var.operating_system == "Linux" && length(
    module.profiles.deploy_chassis) + length(module.profiles.deploy_servers
  ) > 0 }
  provisioner "local-exec" {
    command    = "chmod 755 intersight.sh"
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "deploy_chassis_profiles" {
  depends_on = [
    module.profiles
  ]
  for_each = {
    for k, v in module.profiles.deploy_chassis : k => v if var.operating_system == "Linux"
  }
  provisioner "local-exec" {
    command    = "./intersight.sh ${var.endpoint} 'PATCH' '/api/v1/chassis/Profiles/${each.value}'"
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "deploy_server_profiles" {
  depends_on = [
    module.profiles
  ]
  for_each = {
    for k, v in module.profiles.deploy_servers : k => v if var.operating_system == "Linux"
  }
  provisioner "local-exec" {
    command    = "./intersight.sh ${var.endpoint} 'PATCH' '/api/v1/server/Profiles/${each.value}'"
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}
