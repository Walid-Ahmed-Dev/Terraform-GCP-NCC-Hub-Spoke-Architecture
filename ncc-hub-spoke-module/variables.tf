variable "prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
  default     = "ncc"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.prefix))
    error_message = "Prefix must start with a letter, contain only lowercase letters, numbers, or hyphens, and be 3-32 characters long."
  }
}

variable "ncc_project_id" {
  description = "GCP project ID for the NCC hub"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.ncc_project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "ncc_region" {
  description = "GCP region for the NCC hub"
  type        = string
  default     = "us-central1"
}

variable "ncc_subnet_cidr" {
  description = "CIDR range for the NCC hub subnet"
  type        = string
  default     = "10.190.0.0/24" # AWSUltraMarines CIDR range
  validation {
    condition     = can(cidrhost(var.ncc_subnet_cidr, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "ncc_asn" {
  description = "BGP ASN for the NCC hub"
  type        = number
  default     = 64512
  validation {
    condition     = var.ncc_asn >= 64512 && var.ncc_asn <= 65535
    error_message = "ASN must be in the private range (64512-65535)."
  }
}

variable "ncc_credentials_path" {
  description = "Path to the NCC hub GCP credentials JSON file"
  type        = string
  sensitive   = true
}

variable "ncc_service_account" {
  description = "Service account email for the NCC hub"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-._]+@[a-z0-9-._]+\\.iam\\.gserviceaccount\\.com$", var.ncc_service_account))
    error_message = "Must be a valid GCP service account email."
  }
}

variable "spoke_a_project_id" {
  description = "GCP project ID for Spoke A"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.spoke_a_project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "spoke_a_region" {
  description = "GCP region for Spoke A"
  type        = string
  default     = "us-east1"
}

variable "spoke_a_subnet_cidr" {
  description = "CIDR range for Spoke A subnet"
  type        = string
  default     = "10.10.1.0/24"
  validation {
    condition     = can(cidrhost(var.spoke_a_subnet_cidr, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_a_asn" {
  description = "BGP ASN for Spoke A"
  type        = number
  default     = 65001
  validation {
    condition     = var.spoke_a_asn >= 64512 && var.spoke_a_asn <= 65535
    error_message = "ASN must be in the private range (64512-65535)."
  }
}

variable "spoke_a_credentials_path" {
  description = "Path to the Spoke A GCP credentials JSON file"
  type        = string
  sensitive   = true
}

variable "spoke_a_service_account" {
  description = "Service account email for Spoke A"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-._]+@[a-z0-9-._]+\\.iam\\.gserviceaccount\\.com$", var.spoke_a_service_account))
    error_message = "Must be a valid GCP service account email."
  }
}

variable "ncc_to_spoke_a_ip_range_0" {
  description = "IP range for NCC to Spoke A tunnel 0"
  type        = string
  default     = "169.254.0.1/30"
  validation {
    condition     = can(cidrhost(var.ncc_to_spoke_a_ip_range_0, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_a_to_ncc_ip_range_0" {
  description = "IP range for Spoke A to NCC tunnel 0"
  type        = string
  default     = "169.254.0.2/30"
  validation {
    condition     = can(cidrhost(var.spoke_a_to_ncc_ip_range_0, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_a_to_ncc_peer_ip_0" {
  description = "Peer IP for Spoke A to NCC tunnel 0"
  type        = string
  default     = "169.254.0.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.spoke_a_to_ncc_peer_ip_0))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_a_peer_ip_0" {
  description = "Peer IP for NCC to Spoke A tunnel 0"
  type        = string
  default     = "169.254.0.1"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.ncc_to_spoke_a_peer_ip_0))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_a_ip_range_1" {
  description = "IP range for NCC to Spoke A tunnel 1"
  type        = string
  default     = "169.254.1.1/30"
  validation {
    condition     = can(cidrhost(var.ncc_to_spoke_a_ip_range_1, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_a_to_ncc_ip_range_1" {
  description = "IP range for Spoke A to NCC tunnel 1"
  type        = string
  default     = "169.254.1.2/30"
  validation {
    condition     = can(cidrhost(var.spoke_a_to_ncc_ip_range_1, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_a_to_ncc_peer_ip_1" {
  description = "Peer IP for Spoke A to NCC tunnel 1"
  type        = string
  default     = "169.254.1.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.spoke_a_to_ncc_peer_ip_1))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_a_peer_ip_1" {
  description = "Peer IP for NCC to Spoke A tunnel 1"
  type        = string
  default     = "169.254.1.1"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.ncc_to_spoke_a_peer_ip_1))
    error_message = "Must be a valid IP address."
  }
}

variable "spoke_b_project_id" {
  description = "GCP project ID for Spoke B"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.spoke_b_project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "spoke_b_region" {
  description = "GCP region for Spoke B"
  type        = string
  default     = "europe-west2"
}

variable "spoke_b_subnet_cidr" {
  description = "CIDR range for Spoke B subnet"
  type        = string
  default     = "10.10.2.0/24"
  validation {
    condition     = can(cidrhost(var.spoke_b_subnet_cidr, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_b_asn" {
  description = "BGP ASN for Spoke B"
  type        = number
  default     = 65002
  validation {
    condition     = var.spoke_b_asn >= 64512 && var.spoke_b_asn <= 65535
    error_message = "ASN must be in the private range (64512-65535)."
  }
}

variable "spoke_b_credentials_path" {
  description = "Path to the Spoke B GCP credentials JSON file"
  type        = string
  sensitive   = true
}

variable "spoke_b_service_account" {
  description = "Service account email for Spoke B"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-._]+@[a-z0-9-._]+\\.iam\\.gserviceaccount\\.com$", var.spoke_b_service_account))
    error_message = "Must be a valid GCP service account email."
  }
}

variable "ncc_to_spoke_b_ip_range_0" {
  description = "IP range for NCC to Spoke B tunnel 0"
  type        = string
  default     = "169.254.2.1/30"
  validation {
    condition     = can(cidrhost(var.ncc_to_spoke_b_ip_range_0, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_b_to_ncc_ip_range_0" {
  description = "IP range for Spoke B to NCC tunnel 0"
  type        = string
  default     = "169.254.2.2/30"
  validation {
    condition     = can(cidrhost(var.spoke_b_to_ncc_ip_range_0, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_b_to_ncc_peer_ip_0" {
  description = "Peer IP for Spoke B to NCC tunnel 0"
  type        = string
  default     = "169.254.2.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.spoke_b_to_ncc_peer_ip_0))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_b_peer_ip_0" {
  description = "Peer IP for NCC to Spoke B tunnel 0"
  type        = string
  default     = "169.254.2.1"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.ncc_to_spoke_b_peer_ip_0))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_b_ip_range_1" {
  description = "IP range for NCC to Spoke B tunnel 1"
  type        = string
  default     = "169.254.3.1/30"
  validation {
    condition     = can(cidrhost(var.ncc_to_spoke_b_ip_range_1, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_b_to_ncc_ip_range_1" {
  description = "IP range for Spoke B to NCC tunnel 1"
  type        = string
  default     = "169.254.3.2/30"
  validation {
    condition     = can(cidrhost(var.spoke_b_to_ncc_ip_range_1, 0))
    error_message = "Must be a valid CIDR range."
  }
}

variable "spoke_b_to_ncc_peer_ip_1" {
  description = "Peer IP for Spoke B to NCC tunnel 1"
  type        = string
  default     = "169.254.3.2"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.spoke_b_to_ncc_peer_ip_1))
    error_message = "Must be a valid IP address."
  }
}

variable "ncc_to_spoke_b_peer_ip_1" {
  description = "Peer IP for NCC to Spoke B tunnel 1"
  type        = string
  default     = "169.254.3.1"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.ncc_to_spoke_b_peer_ip_1))
    error_message = "Must be a valid IP address."
  }
}

variable "deploy_test_vms" {
  description = "Whether to deploy test VMs in Spoke A and Spoke B"
  type        = bool
  default     = true
}

variable "test_vm_machine_type" {
  description = "Machine type for test VMs"
  type        = string
  default     = "e2-micro"
}

variable "test_vm_image" {
  description = "Disk image for test VMs"
  type        = string
  default     = "debian-cloud/debian-11"
}