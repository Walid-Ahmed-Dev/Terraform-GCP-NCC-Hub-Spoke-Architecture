# Defining Terraform provider requirements and version constraints
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

# Configuring Google Cloud providers for NCC hub and spokes
provider "google" {
  alias       = "ncc"
  project     = var.ncc_project_id
  region      = var.ncc_region
  credentials = var.ncc_credentials_path
}

provider "google" {
  alias       = "spoke_a"
  project     = var.spoke_a_project_id
  region      = var.spoke_a_region
  credentials = var.spoke_a_credentials_path
}

provider "google" {
  alias       = "spoke_b"
  project     = var.spoke_b_project_id
  region      = var.spoke_b_region
  credentials = var.spoke_b_credentials_path
}

# Generating shared secrets for VPN tunnels using random provider
resource "random_id" "shared_secret_a" {
  byte_length = 32
}

resource "random_id" "shared_secret_b" {
  byte_length = 32
}

locals {
  shared_secret_a = base64encode(random_id.shared_secret_a.b64_std)
  shared_secret_b = base64encode(random_id.shared_secret_b.b64_std)
}

# NCC Hub VPC and Subnet
resource "google_compute_network" "ncc_vpc" {
  provider                = google.ncc
  name                    = "${var.prefix}-ncc-hub-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ncc_subnet" {
  provider      = google.ncc
  name          = "${var.prefix}-ncc-subnet"
  network       = google_compute_network.ncc_vpc.id
  ip_cidr_range = var.ncc_subnet_cidr
  region        = var.ncc_region
}

# NCC Hub
resource "google_network_connectivity_hub" "ncc_hub" {
  provider    = google.ncc
  name        = "${var.prefix}-ncc-hub"
  description = "Hub connecting Spoke A and Spoke B"
}

# NCC HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "ncc_vpn_gateway" {
  provider = google.ncc
  name     = "${var.prefix}-ncc-vpn-gateway"
  network  = google_compute_network.ncc_vpc.id
  region   = var.ncc_region
}

# NCC Cloud Router
resource "google_compute_router" "ncc_cloud_router" {
  provider = google.ncc
  name     = "${var.prefix}-ncc-cloud-router"
  region   = var.ncc_region
  network  = google_compute_network.ncc_vpc.id
  bgp {
    asn = var.ncc_asn
  }
}

# IAM permissions for VPN connectivity
resource "google_project_iam_member" "ncc_to_spoke_a" {
  # Allows the hub project (via its service account) to attach VPN tunnels to spoke_a's VPC.
  # Required for NCC to establish connectivity via spoke_a's HA VPN Gateway.
  provider = google.spoke_a
  project  = var.spoke_a_project_id
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:${var.ncc_service_account}"
}

resource "google_project_iam_member" "ncc_to_spoke_b" {
  # Allows the hub project (via its service account) to attach VPN tunnels to spoke_b's VPC.
  # Required for NCC to establish connectivity via spoke_b's HA VPN Gateway.
  provider = google.spoke_b
  project  = var.spoke_b_project_id
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:${var.ncc_service_account}"
}

resource "google_project_iam_member" "spoke_a_to_ncc" {
  # Allows the spoke_a project (via its service account) to attach VPN tunnels to the hub's VPC.
  # Required for spoke_a to establish connectivity via the hub's HA VPN Gateway.
  provider = google.ncc
  project  = var.ncc_project_id
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:${var.spoke_a_service_account}"
}

resource "google_project_iam_member" "spoke_b_to_ncc" {
  # Allows the spoke_b project (via its service account) to attach VPN tunnels to the hub's VPC.
  # Required for spoke_b to establish connectivity via the hub's HA VPN Gateway.
  provider = google.ncc
  project  = var.ncc_project_id
  role     = "roles/compute.networkUser"
  member   = "serviceAccount:${var.spoke_b_service_account}"
}

# VPN Tunnels for Spoke A
resource "google_compute_vpn_tunnel" "ncc_to_spoke_a_0" {
  provider              = google.ncc
  name                  = "${var.prefix}-ncc-to-spoke-a-0"
  region                = var.ncc_region
  vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
  shared_secret         = local.shared_secret_a
  ike_version           = 2
  router                = google_compute_router.ncc_cloud_router.id
  depends_on            = [google_project_iam_member.ncc_to_spoke_a]
}

resource "google_compute_vpn_tunnel" "ncc_to_spoke_a_1" {
  provider              = google.ncc
  name                  = "${var.prefix}-ncc-to-spoke-a-1"
  region                = var.ncc_region
  vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
  shared_secret         = local.shared_secret_a
  ike_version           = 2
  router                = google_compute_router.ncc_cloud_router.id
  depends_on            = [google_project_iam_member.ncc_to_spoke_a]
}

# NCC Cloud Router Interfaces and Peers for Spoke A
resource "google_compute_router_interface" "ncc_to_spoke_a_0" {
  provider   = google.ncc
  name       = "${var.prefix}-ncc-to-spoke-a-0"
  router     = google_compute_router.ncc_cloud_router.name
  region     = var.ncc_region
  ip_range   = var.ncc_to_spoke_a_ip_range_0
  vpn_tunnel = google_compute_vpn_tunnel.ncc_to_spoke_a_0.name
  depends_on = [google_compute_vpn_tunnel.ncc_to_spoke_a_0]
}

resource "google_compute_router_peer" "ncc_to_spoke_a_0" {
  provider        = google.ncc
  name            = "${var.prefix}-ncc-to-spoke-a-0"
  router          = google_compute_router.ncc_cloud_router.name
  region          = var.ncc_region
  peer_ip_address = var.spoke_a_to_ncc_peer_ip_0
  peer_asn        = var.spoke_a_asn
  interface       = google_compute_router_interface.ncc_to_spoke_a_0.name
  depends_on      = [google_compute_router_interface.ncc_to_spoke_a_0]
}

resource "google_compute_router_interface" "ncc_to_spoke_a_1" {
  provider   = google.ncc
  name       = "${var.prefix}-ncc-to-spoke-a-1"
  router     = google_compute_router.ncc_cloud_router.name
  region     = var.ncc_region
  ip_range   = var.ncc_to_spoke_a_ip_range_1
  vpn_tunnel = google_compute_vpn_tunnel.ncc_to_spoke_a_1.name
  depends_on = [google_compute_vpn_tunnel.ncc_to_spoke_a_1]
}

resource "google_compute_router_peer" "ncc_to_spoke_a_1" {
  provider        = google.ncc
  name            = "${var.prefix}-ncc-to-spoke-a-1"
  router          = google_compute_router.ncc_cloud_router.name
  region          = var.ncc_region
  peer_ip_address = var.spoke_a_to_ncc_peer_ip_1
  peer_asn        = var.spoke_a_asn
  interface       = google_compute_router_interface.ncc_to_spoke_a_1.name
  depends_on      = [google_compute_router_interface.ncc_to_spoke_a_1]
}

# NCC Spoke for Spoke A
resource "google_network_connectivity_spoke" "vpn_spoke_a" {
  provider = google.ncc
  name     = "${var.prefix}-vpn-spoke-a"
  location = var.ncc_region
  hub      = google_network_connectivity_hub.ncc_hub.id
  linked_vpn_tunnels {
    uris = [
      google_compute_vpn_tunnel.ncc_to_spoke_a_0.id,
      google_compute_vpn_tunnel.ncc_to_spoke_a_1.id
    ]
    site_to_site_data_transfer = true
  }
  depends_on = [
    google_compute_vpn_tunnel.ncc_to_spoke_a_0,
    google_compute_vpn_tunnel.ncc_to_spoke_a_1
  ]
  lifecycle {
    ignore_changes = [name, linked_vpn_tunnels[0].uris]
  }
}

# VPN Tunnels for Spoke B
resource "google_compute_vpn_tunnel" "ncc_to_spoke_b_0" {
  provider              = google.ncc
  name                  = "${var.prefix}-ncc-to-spoke-b-0"
  region                = var.ncc_region
  vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
  shared_secret         = local.shared_secret_b
  ike_version           = 2
  router                = google_compute_router.ncc_cloud_router.id
  depends_on            = [google_project_iam_member.ncc_to_spoke_b]
}

resource "google_compute_vpn_tunnel" "ncc_to_spoke_b_1" {
  provider              = google.ncc
  name                  = "${var.prefix}-ncc-to-spoke-b-1"
  region                = var.ncc_region
  vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
  shared_secret         = local.shared_secret_b
  ike_version           = 2
  router                = google_compute_router.ncc_cloud_router.id
  depends_on            = [google_project_iam_member.ncc_to_spoke_b]
}

# NCC Cloud Router Interfaces and Peers for Spoke B
resource "google_compute_router_interface" "ncc_to_spoke_b_0" {
  provider   = google.ncc
  name       = "${var.prefix}-ncc-to-spoke-b-0"
  router     = google_compute_router.ncc_cloud_router.name
  region     = var.ncc_region
  ip_range   = var.ncc_to_spoke_b_ip_range_0
  vpn_tunnel = google_compute_vpn_tunnel.ncc_to_spoke_b_0.name
  depends_on = [google_compute_vpn_tunnel.ncc_to_spoke_b_0]
}

resource "google_compute_router_peer" "ncc_to_spoke_b_0" {
  provider        = google.ncc
  name            = "${var.prefix}-ncc-to-spoke-b-0"
  router          = google_compute_router.ncc_cloud_router.name
  region          = var.ncc_region
  peer_ip_address = var.spoke_b_to_ncc_peer_ip_0
  peer_asn        = var.spoke_b_asn
  interface       = google_compute_router_interface.ncc_to_spoke_b_0.name
  depends_on      = [google_compute_router_interface.ncc_to_spoke_b_0]
}

resource "google_compute_router_interface" "ncc_to_spoke_b_1" {
  provider   = google.ncc
  name       = "${var.prefix}-ncc-to-spoke-b-1"
  router     = google_compute_router.ncc_cloud_router.name
  region     = var.ncc_region
  ip_range   = var.ncc_to_spoke_b_ip_range_1
  vpn_tunnel = google_compute_vpn_tunnel.ncc_to_spoke_b_1.name
  depends_on = [google_compute_vpn_tunnel.ncc_to_spoke_b_1]
}

resource "google_compute_router_peer" "ncc_to_spoke_b_1" {
  provider        = google.ncc
  name            = "${var.prefix}-ncc-to-spoke-b-1"
  router          = google_compute_router.ncc_cloud_router.name
  region          = var.ncc_region
  peer_ip_address = var.spoke_b_to_ncc_peer_ip_1
  peer_asn        = var.spoke_b_asn
  interface       = google_compute_router_interface.ncc_to_spoke_b_1.name
  depends_on      = [google_compute_router_interface.ncc_to_spoke_b_1]
}

# NCC Spoke for Spoke B
resource "google_network_connectivity_spoke" "vpn_spoke_b" {
  provider = google.ncc
  name     = "${var.prefix}-vpn-spoke-b"
  location = var.ncc_region
  hub      = google_network_connectivity_hub.ncc_hub.id
  linked_vpn_tunnels {
    uris = [
      google_compute_vpn_tunnel.ncc_to_spoke_b_0.id,
      google_compute_vpn_tunnel.ncc_to_spoke_b_1.id
    ]
    site_to_site_data_transfer = true
  }
  depends_on = [
    google_compute_vpn_tunnel.ncc_to_spoke_b_0,
    google_compute_vpn_tunnel.ncc_to_spoke_b_1
  ]
  lifecycle {
    ignore_changes = [name, linked_vpn_tunnels[0].uris]
  }
}

# NCC Firewall Rules
resource "google_compute_firewall" "ncc_allow_vpn_bgp" {
  provider = google.ncc
  name     = "${var.prefix}-ncc-allow-vpn-bgp"
  network  = google_compute_network.ncc_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["179"]
  }
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  allow {
    protocol = "esp"
  }
  source_ranges = [var.spoke_a_subnet_cidr, var.spoke_b_subnet_cidr]
  priority      = 1000
}

resource "google_compute_firewall" "ncc_allow_spoke_to_spoke" {
  provider = google.ncc
  name     = "${var.prefix}-ncc-allow-spoke-to-spoke"
  network  = google_compute_network.ncc_vpc.id
  allow {
    protocol = "all"
  }
  source_ranges      = [var.spoke_a_subnet_cidr, var.spoke_b_subnet_cidr]
  destination_ranges = [var.spoke_a_subnet_cidr, var.spoke_b_subnet_cidr]
  priority           = 1000
}

# Spoke A VPC and Subnet
resource "google_compute_network" "spoke_a_vpc" {
  provider                = google.spoke_a
  name                    = "${var.prefix}-spoke-a-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "spoke_a_subnet" {
  provider      = google.spoke_a
  name          = "${var.prefix}-spoke-a-subnet"
  network       = google_compute_network.spoke_a_vpc.id
  ip_cidr_range = var.spoke_a_subnet_cidr
  region        = var.spoke_a_region
}

# Spoke A Test VM (optional)
resource "google_compute_instance" "spoke_a_test_vm" {
  provider     = google.spoke_a
  name         = "${var.prefix}-spoke-a-test-vm"
  machine_type = var.test_vm_machine_type
  zone         = "${var.spoke_a_region}-b"
  tags         = ["${var.prefix}-spoke-a-vm"]

  boot_disk {
    initialize_params {
      image = var.test_vm_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spoke_a_subnet.self_link
  }

  depends_on = [google_compute_subnetwork.spoke_a_subnet]
}



# Spoke A HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "spoke_a_vpn_gateway" {
  provider = google.spoke_a
  name     = "${var.prefix}-spoke-a-vpn-gateway"
  network  = google_compute_network.spoke_a_vpc.id
  region   = var.spoke_a_region
}

# Spoke A Cloud Router
resource "google_compute_router" "spoke_a_router" {
  provider = google.spoke_a
  name     = "${var.prefix}-spoke-a-router"
  region   = var.spoke_a_region
  network  = google_compute_network.spoke_a_vpc.id
  bgp {
    asn = var.spoke_a_asn
  }
}

# Spoke A VPN Tunnels
resource "google_compute_vpn_tunnel" "spoke_a_to_ncc_0" {
  provider              = google.spoke_a
  name                  = "${var.prefix}-spoke-a-to-ncc-0"
  region                = var.spoke_a_region
  vpn_gateway           = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  shared_secret         = local.shared_secret_a
  ike_version           = 2
  router                = google_compute_router.spoke_a_router.id
  depends_on            = [google_project_iam_member.spoke_a_to_ncc]
}

resource "google_compute_vpn_tunnel" "spoke_a_to_ncc_1" {
  provider              = google.spoke_a
  name                  = "${var.prefix}-spoke-a-to-ncc-1"
  region                = var.spoke_a_region
  vpn_gateway           = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  shared_secret         = local.shared_secret_a
  ike_version           = 2
  router                = google_compute_router.spoke_a_router.id
  depends_on            = [google_project_iam_member.spoke_a_to_ncc]
}

# Spoke A Cloud Router Interfaces and Peers
resource "google_compute_router_interface" "spoke_a_to_ncc_0" {
  provider   = google.spoke_a
  name       = "${var.prefix}-spoke-a-to-ncc-0"
  router     = google_compute_router.spoke_a_router.name
  region     = var.spoke_a_region
  ip_range   = var.spoke_a_to_ncc_ip_range_0
  vpn_tunnel = google_compute_vpn_tunnel.spoke_a_to_ncc_0.name
  depends_on = [google_compute_vpn_tunnel.spoke_a_to_ncc_0]
}

resource "google_compute_router_peer" "spoke_a_to_ncc_0" {
  provider        = google.spoke_a
  name            = "${var.prefix}-spoke-a-to-ncc-0"
  router          = google_compute_router.spoke_a_router.name
  region          = var.spoke_a_region
  peer_ip_address = var.ncc_to_spoke_a_peer_ip_0
  peer_asn        = var.ncc_asn
  interface       = google_compute_router_interface.spoke_a_to_ncc_0.name
  depends_on      = [google_compute_router_interface.spoke_a_to_ncc_0]
}

resource "google_compute_router_interface" "spoke_a_to_ncc_1" {
  provider   = google.spoke_a
  name       = "${var.prefix}-spoke-a-to-ncc-1"
  router     = google_compute_router.spoke_a_router.name
  region     = var.spoke_a_region
  ip_range   = var.spoke_a_to_ncc_ip_range_1
  vpn_tunnel = google_compute_vpn_tunnel.spoke_a_to_ncc_1.name
  depends_on = [google_compute_vpn_tunnel.spoke_a_to_ncc_1]
}

resource "google_compute_router_peer" "spoke_a_to_ncc_1" {
  provider        = google.spoke_a
  name            = "${var.prefix}-spoke-a-to-ncc-1"
  router          = google_compute_router.spoke_a_router.name
  region          = var.spoke_a_region
  peer_ip_address = var.ncc_to_spoke_a_peer_ip_1
  peer_asn        = var.ncc_asn
  interface       = google_compute_router_interface.spoke_a_to_ncc_1.name
  depends_on      = [google_compute_router_interface.spoke_a_to_ncc_1]
}

# Spoke A Firewall Rules
resource "google_compute_firewall" "spoke_a_allow_vpn_bgp" {
  provider = google.spoke_a
  name     = "${var.prefix}-spoke-a-allow-vpn-bgp"
  network  = google_compute_network.spoke_a_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["179"]
  }
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  allow {
    protocol = "esp"
  }
  source_ranges = [var.ncc_subnet_cidr]
  priority      = 1000
}

resource "google_compute_firewall" "spoke_a_allow_spoke_to_spoke" {
  provider = google.spoke_a
  name     = "${var.prefix}-spoke-a-allow-spoke-to-spoke"
  network  = google_compute_network.spoke_a_vpc.id
  allow {
    protocol = "all"
  }
  source_ranges      = [var.spoke_b_subnet_cidr]
  destination_ranges = [var.spoke_a_subnet_cidr]
  priority           = 1000
}

resource "google_compute_firewall" "spoke_a_allow_iap_ssh" {
  count    = var.deploy_test_vms ? 1 : 0
  provider = google.spoke_a
  name     = "${var.prefix}-spoke-a-allow-iap-ssh"
  network  = google_compute_network.spoke_a_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.prefix}-spoke-a-vm"]
  priority      = 1000
}

# Spoke B VPC and Subnet
resource "google_compute_network" "spoke_b_vpc" {
  provider                = google.spoke_b
  name                    = "${var.prefix}-spoke-b-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "spoke_b_subnet" {
  provider      = google.spoke_b
  name          = "${var.prefix}-spoke-b-subnet"
  network       = google_compute_network.spoke_b_vpc.id
  ip_cidr_range = var.spoke_b_subnet_cidr
  region        = var.spoke_b_region
}

# Spoke B Test VM (optional)
resource "google_compute_instance" "spoke_b_test_vm" {
  provider     = google.spoke_b
  name         = "${var.prefix}-spoke-b-test-vm"
  machine_type = var.test_vm_machine_type
  zone         = "${var.spoke_b_region}-a"
  tags         = ["${var.prefix}-spoke-b-vm"]

  boot_disk {
    initialize_params {
      image = var.test_vm_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spoke_b_subnet.self_link
  }

  depends_on = [google_compute_subnetwork.spoke_b_subnet]
}

# Spoke B HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "spoke_b_vpn_gateway" {
  provider = google.spoke_b
  name     = "${var.prefix}-spoke-b-vpn-gateway"
  network  = google_compute_network.spoke_b_vpc.id
  region   = var.spoke_b_region
}

# Spoke B Cloud Router
resource "google_compute_router" "spoke_b_router" {
  provider = google.spoke_b
  name     = "${var.prefix}-spoke-b-router"
  region   = var.spoke_b_region
  network  = google_compute_network.spoke_b_vpc.id
  bgp {
    asn = var.spoke_b_asn
  }
}

# Spoke B VPN Tunnels
resource "google_compute_vpn_tunnel" "spoke_b_to_ncc_0" {
  provider              = google.spoke_b
  name                  = "${var.prefix}-spoke-b-to-ncc-0"
  region                = var.spoke_b_region
  vpn_gateway           = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
  vpn_gateway_interface = 0
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  shared_secret         = local.shared_secret_b
  ike_version           = 2
  router                = google_compute_router.spoke_b_router.id
  depends_on            = [google_project_iam_member.spoke_b_to_ncc]
}

resource "google_compute_vpn_tunnel" "spoke_b_to_ncc_1" {
  provider              = google.spoke_b
  name                  = "${var.prefix}-spoke-b-to-ncc-1"
  region                = var.spoke_b_region
  vpn_gateway           = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
  vpn_gateway_interface = 1
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
  shared_secret         = local.shared_secret_b
  ike_version           = 2
  router                = google_compute_router.spoke_b_router.id
  depends_on            = [google_project_iam_member.spoke_b_to_ncc]
}

# Spoke B Cloud Router Interfaces and Peers
resource "google_compute_router_interface" "spoke_b_to_ncc_0" {
  provider   = google.spoke_b
  name       = "${var.prefix}-spoke-b-to-ncc-0"
  router     = google_compute_router.spoke_b_router.name
  region     = var.spoke_b_region
  ip_range   = var.spoke_b_to_ncc_ip_range_0
  vpn_tunnel = google_compute_vpn_tunnel.spoke_b_to_ncc_0.name
  depends_on = [google_compute_vpn_tunnel.spoke_b_to_ncc_0]
}

resource "google_compute_router_peer" "spoke_b_to_ncc_0" {
  provider        = google.spoke_b
  name            = "${var.prefix}-spoke-b-to-ncc-0"
  router          = google_compute_router.spoke_b_router.name
  region          = var.spoke_b_region
  peer_ip_address = var.ncc_to_spoke_b_peer_ip_0
  peer_asn        = var.ncc_asn
  interface       = google_compute_router_interface.spoke_b_to_ncc_0.name
  depends_on      = [google_compute_router_interface.spoke_b_to_ncc_0]
}

resource "google_compute_router_interface" "spoke_b_to_ncc_1" {
  provider   = google.spoke_b
  name       = "${var.prefix}-spoke-b-to-ncc-1"
  router     = google_compute_router.spoke_b_router.name
  region     = var.spoke_b_region
  ip_range   = var.spoke_b_to_ncc_ip_range_1
  vpn_tunnel = google_compute_vpn_tunnel.spoke_b_to_ncc_1.name
  depends_on = [google_compute_vpn_tunnel.spoke_b_to_ncc_1]
}

resource "google_compute_router_peer" "spoke_b_to_ncc_1" {
  provider        = google.spoke_b
  name            = "${var.prefix}-spoke-b-to-ncc-1"
  router          = google_compute_router.spoke_b_router.name
  region          = var.spoke_b_region
  peer_ip_address = var.ncc_to_spoke_b_peer_ip_1
  peer_asn        = var.ncc_asn
  interface       = google_compute_router_interface.spoke_b_to_ncc_1.name
  depends_on      = [google_compute_router_interface.spoke_b_to_ncc_1]
}

# Spoke B Firewall Rules
resource "google_compute_firewall" "spoke_b_allow_vpn_bgp" {
  provider = google.spoke_b
  name     = "${var.prefix}-spoke-b-allow-vpn-bgp"
  network  = google_compute_network.spoke_b_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["179"]
  }
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  allow {
    protocol = "esp"
  }
  source_ranges = [var.ncc_subnet_cidr]
  priority      = 1000
}

resource "google_compute_firewall" "spoke_b_allow_spoke_to_spoke" {
  provider = google.spoke_b
  name     = "${var.prefix}-spoke-b-allow-spoke-to-spoke"
  network  = google_compute_network.spoke_b_vpc.id
  allow {
    protocol = "all"
  }
  source_ranges      = [var.spoke_a_subnet_cidr]
  destination_ranges = [var.spoke_b_subnet_cidr]
  priority           = 1000
}

resource "google_compute_firewall" "spoke_b_allow_iap_ssh" {
  count    = var.deploy_test_vms ? 1 : 0
  provider = google.spoke_b
  name     = "${var.prefix}-spoke-b-allow-iap-ssh"
  network  = google_compute_network.spoke_b_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.prefix}-spoke-b-vm"]
  priority      = 1000
}