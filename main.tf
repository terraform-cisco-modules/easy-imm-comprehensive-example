#_______________________________________________________________________
#
# Terraform Required Parameters - Intersight Provider
# https://registry.terraform.io/providers/CiscoDevNet/intersight/latest
#_______________________________________________________________________

terraform {
  required_providers {
    intersight = {
      source  = "CiscoDevNet/intersight"
      version = ">=1.0.32"
    }
    utils = {
      source  = "netascode/utils"
      version = ">= 0.1.2"
    }
  }
  required_version = ">=1.3.0"
}

provider "intersight" {
  apikey    = var.apikey
  endpoint  = var.endpoint
  secretkey = var.secretkey
}


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

# module "domain_profiles" {
#   depends_on = [
#     module.pools
#   ]
#   source = "../terraform-intersight-ucs-domain-profiles"
#   # source  = "terraform-cisco-modules/ucs-domain-profiles/intersight"
#   # version = ">= 1.0.1"
#   model = local.model
# }

# module "policies" {
#   depends_on = [
#     module.domain_profiles
#   ]
#   source = "../terraform-intersight-policies"
#   # source  = "terraform-cisco-modules/policies/intersight"
#   # version = ">= 1.0.1"
#   model = local.model
#   pools = module.pools
#   domain_profiles = module.domain_profiles
# }

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
