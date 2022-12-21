#_________________________________________________________________________________________
#
# Data Model Merge Process - Merge YAML Files into HCL Format
#_________________________________________________________________________________________
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

#_________________________________________________________________________________________
#
# Intersight:Pools
# GUI Location: Infrastructure Service > Configure > Pools
#_________________________________________________________________________________________
module "pools" {
  source       = "terraform-cisco-modules/pools/intersight"
  version      = "1.0.12"
  model        = local.model
  organization = var.organization
  tags         = var.tags
}

#_________________________________________________________________________________________
#
# Intersight:UCS Domain Profiles
# GUI Location: Infrastructure Service > Configure > Profiles : UCS Domain Profiles
#_________________________________________________________________________________________
module "domain_profiles" {
  source       = "terraform-cisco-modules/profiles-domain/intersight"
  version      = "1.0.11"
  model        = local.model
  moids        = var.moids
  organization = var.organization
  #policies     = module.policies
  pools = module.pools
  tags  = var.tags
}

#_________________________________________________________________________________________
#
# Intersight:Policies
# GUI Location: Infrastructure Service > Configure > Policies
#_________________________________________________________________________________________
module "policies" {
  source       = "terraform-cisco-modules/policies/intersight"
  version      = "1.0.13"
  domains      = module.domain_profiles.switch_profiles
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

#_________________________________________________________________________________________
#
# Intersight: UCS Domain Profiles
# GUI Location: Infrastructure Service > Configure > Profiles : UCS Domain Profiles
#_________________________________________________________________________________________
resource "intersight_fabric_switch_profile" "switch_profiles" {
  depends_on = [
    module.policies
  ]
  for_each = module.domain_profiles.switch_profiles
  action = length(regexall(
    "^[A-Z]{3}[2-3][\\d]([0][1-9]|[1-4][0-9]|[5][1-3])[\\dA-Z]{4}$", each.value.serial_number)
  ) > 0 ? each.value.action : "No-op"
  lifecycle {
    ignore_changes = [
      action_params,
      ancestors,
      assigned_switch,
      create_time,
      description,
      domain_group_moid,
      mod_time,
      owners,
      parent,
      permission_resources,
      policy_bucket,
      running_workflows,
      shared_scope,
      src_template,
      tags,
      version_context
    ]
  }
  name = each.value.name
  switch_cluster_profile {
    moid = module.domain_profiles.domains[each.value.domain_profile]
  }
  wait_for_completion = module.domain_profiles.switch_profiles[
    element(keys(module.domain_profiles.switch_profiles), length(keys(module.domain_profiles.switch_profiles)
  ) - 1)].name == each.value.name ? true : false
}

#_________________________________________________________________________________________
#
# Sleep Timer between Deploying the Domain and Waiting for Server Discovery
#_________________________________________________________________________________________
resource "time_sleep" "wait_for_server_discovery" {
  depends_on = [intersight_fabric_switch_profile.switch_profiles]
  create_duration = length([
    for v in keys(module.domain_profiles.switch_profiles) : 1 if module.domain_profiles.switch_profiles[v
  ].action == "Deploy"]) > 0 ? "30m" : "1s"
  triggers = {
    always_run = "${timestamp()}"
  }
}

#_________________________________________________________________________________________
#
# Intersight:UCS Chassis and Server Profiles
# GUI Location: Infrastructure Service > Configure > Profiles
#_________________________________________________________________________________________
module "profiles" {
  source       = "terraform-cisco-modules/profiles/intersight"
  version      = "1.0.19"
  model        = local.model
  moids        = var.moids
  organization = var.organization
  policies     = module.policies
  pools        = module.pools
  tags         = var.tags
  time_sleep   = time_sleep.wait_for_server_discovery.id
}

#_________________________________________________________________________________________
#
# Intersight: UCS Chassis Profiles
# GUI Location: Infrastructure Service > Configure > Profiles : UCS Chassis Profiles
#_________________________________________________________________________________________
resource "intersight_chassis_profile" "chassis" {
  depends_on = [
    module.profiles
  ]
  for_each = module.profiles.chassis
  action = length(regexall(
    "^[A-Z]{3}[2-3][\\d]([0][1-9]|[1-4][0-9]|[5][1-3])[\\dA-Z]{4}$", each.value.serial_number)
  ) > 0 ? each.value.action : "No-op"
  lifecycle {
    ignore_changes = [
      action_params,
      ancestors,
      create_time,
      description,
      domain_group_moid,
      mod_time,
      owners,
      parent,
      permission_resources,
      policy_bucket,
      running_workflows,
      shared_scope,
      src_template,
      tags,
      version_context
    ]
  }
  name            = each.value.name
  target_platform = each.value.target_platform
  organization {
    moid = module.pools.orgs[each.value.organization]
  }
}

#_________________________________________________________________________________________
#
# Intersight: UCS Server Profiles
# GUI Location: Infrastructure Service > Configure > Profiles : UCS Server Profiles
#_________________________________________________________________________________________
resource "intersight_server_profile" "server" {
  depends_on = [
    module.profiles
  ]
  for_each = module.profiles.server
  action = length(regexall(
    "^[A-Z]{3}[2-3][\\d]([0][1-9]|[1-4][0-9]|[5][1-3])[\\dA-Z]{4}$", each.value.serial_number)
  ) > 0 ? each.value.action : "No-op"
  lifecycle {
    ignore_changes = [
      action_params,
      ancestors,
      assigned_server,
      associated_server,
      associated_server_pool,
      create_time,
      description,
      domain_group_moid,
      mod_time,
      owners,
      parent,
      permission_resources,
      policy_bucket,
      reservation_references,
      running_workflows,
      server_assignment_mode,
      server_pool,
      shared_scope,
      src_template,
      tags,
      uuid,
      uuid_address_type,
      uuid_lease,
      uuid_pool,
      version_context
    ]
  }
  name            = each.value.name
  target_platform = each.value.target_platform
  organization {
    moid = module.pools.orgs[each.value.organization]
  }
}

