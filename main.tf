locals {
  model = yamldecode(data.utils_yaml_merge.model.output)
}

data "utils_yaml_merge" "model" {
  input = concat([
    for file in fileset(path.module, "policies/*.yaml") : file(file)], [
    for file in fileset(path.module, "pools/*.yaml") : file(file)], [
    for file in fileset(path.module, "profiles/*.yaml") : file(file)], [
    for file in fileset(path.module, "templates/*.yaml") : file(file)], [
    file("${path.module}/defaults/defaults_policies.yaml")], [
    file("${path.module}/defaults/defaults_pools.yaml")], [
    file("${path.module}/defaults/defaults_profiles.yaml")]
  )
  merge_list_items = false
}

module "pools" {
  source       = "terraform-cisco-modules/pools/intersight"
  version      = ">= 1.0.11"
  model        = local.model
  organization = var.organization
  tags         = var.tags
}

module "policies" {
  depends_on = [
    module.pools
  ]
  source       = "terraform-cisco-modules/policies/intersight"
  version      = ">= 1.0.11"
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

module "domain_profiles" {
  depends_on = [
    module.policies
  ]
  source = "../terraform-cisco-modules/terraform-intersight-profiles-domain"
  #source       = "terraform-cisco-modules/profiles-domain/intersight"
  #version      = ">= 1.0.9"
  model        = local.model
  organization = var.organization
  orgs         = module.pools.orgs
  policies     = module.policies
  tags         = var.tags
}

#locals {
#  tag_complete_script = <<-EOF
#  #!/bin/bash
#  EOF
#  #instance_id="${TOKEN=`curl -X PUT \\"http://169.254.169.254/latest/api/token\\" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id}" aws ec2 create-tags --resources "$instance_id" --tags 'Key=trajano/terraform-docker-swarm-aws/cloudinit-complete,Value=true'
#}

#resource "null_resource" "deploy_domain_profile" {
#  depends_on = [
#    module.domain_profiles
#  ]
#  for_each = module.domain_profiles.switch_profiles
#  provisioner "local-exec" {
#    command = <<-EOF
#    ./intersight.sh ${var.endpoint} ${var.apikey} ${var.secretkey} 'POST' ${each.value.moid} {"Action": "Deploy"}
#    EOF
#  }
#}

#resource "null_resource" "wait_for_domain_profile" {
#  depends_on = [
#    module.domain_profiles
#  ]
#  for_each = module.domain_profiles.switch_profiles
#  provisioner "local-exec" {
#    command = <<-EOF
#    #!/bin/bash
#    json_results=./intersight.sh ${var.endpoint} ${var.apikey} ${var.secretkey} 'POST' ${each.value.moid} {"Action": "Deploy"}
#    config_state=grep
#    while [[ ]]
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
  source       = "terraform-cisco-modules/profiles/intersight"
  version      = ">= 1.0.15"
  model        = local.model
  moids        = var.moids
  organization = var.organization
  policies     = module.policies
  pools        = module.pools
  tags         = var.tags
}
