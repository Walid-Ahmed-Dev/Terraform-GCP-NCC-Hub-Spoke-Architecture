# Terraform provider requirements
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Call the ncc-hub-spoke module
module "ncc_hub_spoke" {
  source                    = "./ncc-hub-spoke-module"
  prefix                    = var.prefix
  ncc_project_id            = var.ncc_project_id
  ncc_region                = var.ncc_region
  ncc_subnet_cidr           = var.ncc_subnet_cidr
  ncc_asn                   = var.ncc_asn
  ncc_credentials_path      = var.ncc_credentials_path
  ncc_service_account       = var.ncc_service_account

  spoke_a_project_id        = var.spoke_a_project_id
  spoke_a_region            = var.spoke_a_region
  spoke_a_subnet_cidr       = var.spoke_a_subnet_cidr
  spoke_a_asn               = var.spoke_a_asn
  spoke_a_credentials_path  = var.spoke_a_credentials_path
  spoke_a_service_account   = var.spoke_a_service_account
  
  ncc_to_spoke_a_ip_range_0 = var.ncc_to_spoke_a_ip_range_0 # on google.ncc

  spoke_a_to_ncc_ip_range_0 = var.spoke_a_to_ncc_ip_range_0 # on google.spoke

  spoke_a_to_ncc_peer_ip_0  = var.spoke_a_to_ncc_peer_ip_0 # on google.ncc
  
  ncc_to_spoke_a_peer_ip_0  = var.ncc_to_spoke_a_peer_ip_0 # on google.spoke

  ncc_to_spoke_a_ip_range_1 = var.ncc_to_spoke_a_ip_range_1 # on google.ncc
  
  spoke_a_to_ncc_ip_range_1 = var.spoke_a_to_ncc_ip_range_1 # on google.spoke

  spoke_a_to_ncc_peer_ip_1  = var.spoke_a_to_ncc_peer_ip_1 # on google.ncc

  ncc_to_spoke_a_peer_ip_1  = var.ncc_to_spoke_a_peer_ip_1 # on google.spoke

  spoke_b_project_id        = var.spoke_b_project_id
  spoke_b_region            = var.spoke_b_region
  spoke_b_subnet_cidr       = var.spoke_b_subnet_cidr
  spoke_b_asn               = var.spoke_b_asn
  spoke_b_credentials_path  = var.spoke_b_credentials_path
  spoke_b_service_account   = var.spoke_b_service_account
  ncc_to_spoke_b_ip_range_0 = var.ncc_to_spoke_b_ip_range_0
  spoke_b_to_ncc_ip_range_0 = var.spoke_b_to_ncc_ip_range_0
  spoke_b_to_ncc_peer_ip_0  = var.spoke_b_to_ncc_peer_ip_0
  ncc_to_spoke_b_peer_ip_0  = var.ncc_to_spoke_b_peer_ip_0
  ncc_to_spoke_b_ip_range_1 = var.ncc_to_spoke_b_ip_range_1
  spoke_b_to_ncc_ip_range_1 = var.spoke_b_to_ncc_ip_range_1
  spoke_b_to_ncc_peer_ip_1  = var.spoke_b_to_ncc_peer_ip_1
  ncc_to_spoke_b_peer_ip_1  = var.ncc_to_spoke_b_peer_ip_1
  
  deploy_test_vms           = var.deploy_test_vms # on both
  test_vm_machine_type      = var.test_vm_machine_type # on both
  test_vm_image             = var.test_vm_image # on both
}

