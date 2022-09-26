locals {
  model = yamldecode(data.utils_yaml_merge.model.output)
}

data "utils_yaml_merge" "model" {
  input = concat([for file in fileset(path.module, "data/*.yaml") : file(file)], [file("${path.module}/defaults/defaults.yaml"), file("${path.module}/modules/modules.yaml")])
}

module "pools" {
  source = "../terraform-intersight-pools"
  # source  = "terraform-cisco-modules/pools/intersight"
  # version = ">= 1.0.1"
  model = local.model
}

module "domain_profiles" {
  depends_on = [
    module.pools
  ]
  source = "../terraform-intersight-ucs-domain-profiles"
  # source  = "terraform-cisco-modules/ucs-domain-profiles/intersight"
  # version = ">= 1.0.1"
  model = local.model
  orgs  = module.pools.orgs
}

module "policies" {
  depends_on = [
    module.domain_profiles
  ]
  source = "../terraform-intersight-policies"
  # source  = "terraform-cisco-modules/policies/intersight"
  # version = ">= 1.0.1"
  model = local.model
  domains = module.domain_profiles.domains
  pools = module.pools
}

# module "profiles" {
#   depends_on = [
#     module.policies
#   ]
#   source = "../terraform-intersight-profiles"
#   # source  = "terraform-cisco-modules/profiles/intersight"
#   # version = ">= 1.0.1"
#   model = local.model
#   pools = module.pools
#   policies = module.policies
# }
