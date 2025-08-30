variable "prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
}

variable "ncc_project_id" {
  description = "GCP project ID for the NCC hub"
  type        = string
}

variable "ncc_region" {
  description = "GCP region for the NCC hub"
  type        = string
}

variable "ncc_subnet_cidr" {
  description = "CIDR range for the NCC hub subnet"
  type        = string
}

variable "ncc_asn" {
  description = "BGP ASN for the NCC hub"
  type        = number
}

variable "ncc_credentials_path" {
  description = "Path to the NCC hub GCP credentials JSON file"
  type        = string
}

variable "ncc_service_account" {
  description = "Service account email for the NCC hub"
  type        = string
}

variable "spoke_a_project_id" {
  description = "GCP project ID for Spoke A"
  type        = string
}

variable "spoke_a_region" {
  description = "GCP region for Spoke A"
  type        = string
}

variable "spoke_a_subnet_cidr" {
  description = "CIDR range for Spoke A subnet"
  type        = string
}

variable "spoke_a_asn" {
  description = "BGP ASN for Spoke A"
  type        = number
}

variable "spoke_a_credentials_path" {
  description = "Path to the Spoke A GCP credentials JSON file"
  type        = string
}

variable "spoke_a_service_account" {
  description = "Service account email for Spoke A"
  type        = string
}

variable "ncc_to_spoke_a_ip_range_0" {
  description = "IP range for NCC to Spoke A tunnel 0"
  type        = string
}

variable "spoke_a_to_ncc_ip_range_0" {
  description = "IP range for Spoke A to NCC tunnel 0"
  type        = string
}

variable "spoke_a_to_ncc_peer_ip_0" {
  description = "Peer IP for Spoke A to NCC tunnel 0"
  type        = string
}

variable "ncc_to_spoke_a_peer_ip_0" {
  description = "Peer IP for NCC to Spoke A tunnel 0"
  type        = string
}

variable "ncc_to_spoke_a_ip_range_1" {
  description = "IP range for NCC to Spoke A tunnel 1"
  type        = string
}

variable "spoke_a_to_ncc_ip_range_1" {
  description = "IP range for Spoke A to NCC tunnel 1"
  type        = string
}

variable "spoke_a_to_ncc_peer_ip_1" {
  description = "Peer IP for Spoke A to NCC tunnel 1"
  type        = string
}

variable "ncc_to_spoke_a_peer_ip_1" {
  description = "Peer IP for NCC to Spoke A tunnel 1"
  type        = string
}

variable "spoke_b_project_id" {
  description = "GCP project ID for Spoke B"
  type        = string
}

variable "spoke_b_region" {
  description = "GCP region for Spoke B"
  type        = string
}

variable "spoke_b_subnet_cidr" {
  description = "CIDR range for Spoke B subnet"
  type        = string
}

variable "spoke_b_asn" {
  description = "BGP ASN for Spoke B"
  type        = number
}

variable "spoke_b_credentials_path" {
  description = "Path to the Spoke B GCP credentials JSON file"
  type        = string
}

variable "spoke_b_service_account" {
  description = "Service account email for Spoke B"
  type        = string
}

variable "ncc_to_spoke_b_ip_range_0" {
  description = "IP range for NCC to Spoke B tunnel 0"
  type        = string
}

variable "spoke_b_to_ncc_ip_range_0" {
  description = "IP range for Spoke B to NCC tunnel 0"
  type        = string
}

variable "spoke_b_to_ncc_peer_ip_0" {
  description = "Peer IP for Spoke B to NCC tunnel 0"
  type        = string
}

variable "ncc_to_spoke_b_peer_ip_0" {
  description = "Peer IP for NCC to Spoke B tunnel 0"
  type        = string
}

variable "ncc_to_spoke_b_ip_range_1" {
  description = "IP range for NCC to Spoke B tunnel 1"
  type        = string
}

variable "spoke_b_to_ncc_ip_range_1" {
  description = "IP range for Spoke B to NCC tunnel 1"
  type        = string
}

variable "spoke_b_to_ncc_peer_ip_1" {
  description = "Peer IP for Spoke B to NCC tunnel 1"
  type        = string
}

variable "ncc_to_spoke_b_peer_ip_1" {
  description = "Peer IP for NCC to Spoke B tunnel 1"
  type        = string
}

variable "deploy_test_vms" {
  description = "Whether to deploy test VMs in Spoke A and Spoke B"
  type        = bool
}

variable "test_vm_machine_type" {
  description = "Machine type for test VMs"
  type        = string
}

variable "test_vm_image" {
  description = "Disk image for test VMs"
  type        = string
}
