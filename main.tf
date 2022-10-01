locals {
  model = yamldecode(data.utils_yaml_merge.model.output)
}

data "utils_yaml_merge" "model" {
  input = concat([
    for file in fileset(path.module, "policies/*.yaml") : file(file)], [
    for file in fileset(path.module, "pools/*.yaml") : file(file)], [
    for file in fileset(path.module, "profiles/*.yaml") : file(file)], [
    for file in fileset(path.module, "templates/*.yaml") : file(file)], [
    file("${path.module}/defaults/defaults.yaml")]
  )
}

module "pools" {
  source  = "terraform-cisco-modules/pools/intersight"
  version = ">= 1.0.2"
  model   = local.model
}

module "domain_profiles" {
  depends_on = [
    module.pools
  ]
  source  = "terraform-cisco-modules/ucs-domain-profiles/intersight"
  version = ">= 1.0.3"
  model   = local.model
  orgs    = module.pools.orgs
}

module "policies" {
  depends_on = [
    module.domain_profiles
  ]
  source  = "terraform-cisco-modules/policies/intersight"
  version = ">= 1.0.4"
  model   = local.model
  domains = module.domain_profiles.domains
  pools   = module.pools
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
  ipmi_key_1 = var.ipmi_key_1
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
  secure_passphrase = var.secure_passphrase
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

module "profiles" {
  depends_on = [
    module.policies
  ]
  source   = "terraform-cisco-modules/profiles/intersight"
  version  = ">= 1.0.4"
  model    = local.model
  pools    = module.pools
  policies = module.policies
}
