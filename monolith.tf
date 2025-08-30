# terraform {
#   required_version = ">= 1.0.0"

#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "6.45.0"
#     }
#     null = {
#       source  = "hashicorp/null"
#       version = "~> 3.0"
#     }
#   }
# }

# # Generate shared secrets for VPN tunnels
# resource "null_resource" "generate_shared_secrets" {
#   provisioner "local-exec" {
#     command = <<EOT
#       echo "shared_secret_a=$(openssl rand -base64 32)" > ../../G-secrets/shared_secretsA.txt
#       echo "shared_secret_b=$(openssl rand -base64 32)" > ../../G-secrets/shared_secretsB.txt
#     EOT
#   }
#   # # This triggers the null_resource to run every time you apply the Terraform plan.
#   # # Because the secrets are used by other resources (e.g., VPN config), those resources will also be redeployed.
#   # # triggers = {
#   # #   always_run = timestamp()
#   # # }
# }

# # Read generated secrets after they are created
# data "local_file" "shared_secretsA" {
#   filename   = "../../G-secrets/shared_secretsA.txt"
#   depends_on = [null_resource.generate_shared_secrets]
# }

# data "local_file" "shared_secretsB" {
#   filename   = "../../G-secrets/shared_secretsB.txt"
#   depends_on = [null_resource.generate_shared_secrets]
# }

# locals {
#   shared_secret_a = trim(replace(data.local_file.shared_secretsA.content, "shared_secret_a=", ""), "\n\r ")
#   shared_secret_b = trim(replace(data.local_file.shared_secretsB.content, "shared_secret_b=", ""), "\n\r ")
# }

# ######################################################
# # PROVIDERS
# ######################################################
# provider "google" {
#   alias       = "ncc"
#   project     = "ncc-project-467401"
#   region      = "us-central1"
#   credentials = file("../../G-secrets/ncc-project-467401-210df7f1e23a.json")
# }

# provider "google" {
#   alias       = "spoke_a"
#   project     = "aws-ultramarines-466800"
#   region      = "us-east1"
#   credentials = file("../../G-secrets/aws-ultramarines-466800-7908714403bd.json")
# }

# provider "google" {
#   alias       = "spoke_b"
#   project     = "pelagic-core-467122-q4"
#   region      = "europe-west2"
#   credentials = file("../../G-secrets/pelagic-core-467122-q4-25d0b2aa49f2.json")
# }

# ######################################################
# # NCC Hub 
# ######################################################
# # Hub VPC
# resource "google_compute_network" "ncc_vpc" {
#   provider                = google.ncc
#   name                    = "ncc-hub-vpc"
#   auto_create_subnetworks = false
# }

# # Hub Subnet
# resource "google_compute_subnetwork" "ncc_subnet" {
#   provider      = google.ncc
#   name          = "ncc-subnet"
#   network       = google_compute_network.ncc_vpc.id
#   ip_cidr_range = "10.99.0.0/24"
#   region        = "us-central1"
# }

# # Hub NCC 
# resource "google_network_connectivity_hub" "group_armageddon_hub" {
#   provider    = google.ncc
#   name        = "group-armageddon-hub"
#   description = "Hub connecting Spokes"
# }

# # Hub HA Gateway 
# resource "google_compute_ha_vpn_gateway" "ncc_vpn_gateway" {
#   provider = google.ncc
#   name     = "ncc-vpn-gateway"
#   network  = google_compute_network.ncc_vpc.id
#   region   = "us-central1"
# }

# # Hub Cloud Router 
# resource "google_compute_router" "ncc_cloud_router" {
#   provider = google.ncc
#   name     = "ncc-cloud-router"
#   region   = "us-central1"
#   network  = google_compute_network.ncc_vpc.id
#   bgp {
#     asn = 64512
#   }
# }

# resource "google_project_iam_member" "vpn_gateway_use_for_ncc_to_spoke_a" {
# # Grant the ncc (hub) service account permission to use spoke_a's HA VPN Gateway.
# # This allows the ncc (hub) project to create VPN tunnels connecting to Spoke A.
#   provider = google.spoke_a
#   project  = "aws-ultramarines-466800"
#   role     = "roles/compute.networkUser"
#   member   = "serviceAccount:admin-428@ncc-project-467401.iam.gserviceaccount.com"
# }

# # VPN tunnels for spoke_a (two tunnels for HA VPN)
# resource "google_compute_vpn_tunnel" "tunnel_spoke_a_0" {
#   provider              = google.ncc
#   name                  = "tunnel-spoke-a-0"
#   region                = "us-central1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   vpn_gateway_interface = 0
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
#   shared_secret         = local.shared_secret_a
#   ike_version           = 2
#   router                = google_compute_router.ncc_cloud_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_ncc_to_spoke_a
#   ]
# }

# resource "google_compute_vpn_tunnel" "tunnel_spoke_a_1" {
#   provider              = google.ncc
#   name                  = "tunnel-spoke-a-1"
#   region                = "us-central1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   vpn_gateway_interface = 1
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
#   shared_secret         = local.shared_secret_a
#   ike_version           = 2
#   router                = google_compute_router.ncc_cloud_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_ncc_to_spoke_a
#   ]
# }

# # Cloud Router interface and peer for spoke_a (interface 0)
# resource "google_compute_router_interface" "interface_spoke_a_0" {
#   provider   = google.ncc
#   name       = "interface-spoke-a-0"
#   router     = google_compute_router.ncc_cloud_router.name
#   region     = "us-central1"
#   ip_range   = "169.254.0.1/30"
#   vpn_tunnel = google_compute_vpn_tunnel.tunnel_spoke_a_0.name
#   depends_on = [
#     google_compute_router.ncc_cloud_router,
#     google_compute_vpn_tunnel.tunnel_spoke_a_0
#   ]
# }

# resource "google_compute_router_peer" "peer_spoke_a_0" {
#   provider        = google.ncc
#   name            = "peer-spoke-a-0"
#   router          = google_compute_router.ncc_cloud_router.name
#   region          = "us-central1"
#   peer_ip_address = "169.254.0.2"
#   peer_asn        = 65001
#   interface       = google_compute_router_interface.interface_spoke_a_0.name
#   depends_on      = [google_compute_router_interface.interface_spoke_a_0]
# }

# # Cloud Router interface and peer for spoke_a (interface 1)
# resource "google_compute_router_interface" "interface_spoke_a_1" {
#   provider   = google.ncc
#   name       = "interface-spoke-a-1"
#   router     = google_compute_router.ncc_cloud_router.name
#   region     = "us-central1"
#   ip_range   = "169.254.1.1/30"
#   vpn_tunnel = google_compute_vpn_tunnel.tunnel_spoke_a_1.name
#   depends_on = [
#     google_compute_router.ncc_cloud_router,
#     google_compute_vpn_tunnel.tunnel_spoke_a_1
#   ]
# }

# resource "google_compute_router_peer" "peer_spoke_a_1" {
#   provider        = google.ncc
#   name            = "peer-spoke-a-1"
#   router          = google_compute_router.ncc_cloud_router.name
#   region          = "us-central1"
#   peer_ip_address = "169.254.1.2"
#   peer_asn        = 65001
#   interface       = google_compute_router_interface.interface_spoke_a_1.name
#   depends_on      = [google_compute_router_interface.interface_spoke_a_1]
# }

# # NCC spoke for spoke_a
# resource "google_network_connectivity_spoke" "vpn_spoke_a" {
#   provider = google.ncc
#   name     = "vpn-spoke-a"
#   location = "us-central1"
#   hub      = google_network_connectivity_hub.group_armageddon_hub.id

#   linked_vpn_tunnels {
#     uris = [
#       google_compute_vpn_tunnel.tunnel_spoke_a_0.id,
#       google_compute_vpn_tunnel.tunnel_spoke_a_1.id
#     ]
#     site_to_site_data_transfer = true
#   }

#   depends_on = [
#     google_compute_vpn_tunnel.tunnel_spoke_a_0,
#     google_compute_vpn_tunnel.tunnel_spoke_a_1
#   ]

#   lifecycle {
#     # Ignore changes to 'name' and 'linked_vpn_tunnels[0].uris'.
#     # The 'name' attribute is often updated automatically by GCP, causing unnecessary resource replacements, 
#     # but the actual functionality doesn't change. By ignoring this, we prevent the resource from being 
#     # destroyed and recreated unnecessarily.
#     #
#     # The 'linked_vpn_tunnels[0].uris' can also change in format (e.g., full URL vs. a shortened version), 
#     # but it doesn't impact the actual functionality of the VPN connections. This is why we ignore it too,
#     # to avoid triggering unnecessary changes that don't impact the operation of the infrastructure.
#     ignore_changes = [
#       name,
#       linked_vpn_tunnels[0].uris
#     ]
#   }
# }

# resource "google_project_iam_member" "vpn_gateway_use_for_ncc_to_spoke_b" {
# # Grant the ncc (hub) service account permission to use spoke_b's HA VPN Gateway.
# # This allows the ncc (hub) project to create VPN tunnels connecting to Spoke B.
#   provider = google.spoke_b
#   project  = "pelagic-core-467122-q4"
#   role     = "roles/compute.networkUser"
#   member   = "serviceAccount:admin-428@ncc-project-467401.iam.gserviceaccount.com"
# }

# # VPN tunnels for spoke_b (two tunnels for HA VPN)
# resource "google_compute_vpn_tunnel" "tunnel_spoke_b_0" {
#   provider              = google.ncc
#   name                  = "tunnel-spoke-b-0"
#   region                = "us-central1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   vpn_gateway_interface = 0
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
#   shared_secret         = local.shared_secret_b
#   ike_version           = 2
#   router                = google_compute_router.ncc_cloud_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_ncc_to_spoke_b
#   ]
# }

# resource "google_compute_vpn_tunnel" "tunnel_spoke_b_1" {
#   provider              = google.ncc
#   name                  = "tunnel-spoke-b-1"
#   region                = "us-central1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   vpn_gateway_interface = 1
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
#   shared_secret         = local.shared_secret_b
#   ike_version           = 2
#   router                = google_compute_router.ncc_cloud_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_ncc_to_spoke_b
#   ]
# }

# # Cloud Router interface and peer for spoke_b (interface 0)
# resource "google_compute_router_interface" "interface_spoke_b_0" {
#   provider   = google.ncc
#   name       = "interface-spoke-b-0"
#   router     = google_compute_router.ncc_cloud_router.name
#   region     = "us-central1"
#   ip_range   = "169.254.2.1/30"
#   vpn_tunnel = google_compute_vpn_tunnel.tunnel_spoke_b_0.name
#   depends_on = [
#     google_compute_router.ncc_cloud_router,
#     google_compute_vpn_tunnel.tunnel_spoke_b_0
#   ]
# }

# resource "google_compute_router_peer" "peer_spoke_b_0" {
#   provider        = google.ncc
#   name            = "peer-spoke-b-0"
#   router          = google_compute_router.ncc_cloud_router.name
#   region          = "us-central1"
#   peer_ip_address = "169.254.2.2"
#   peer_asn        = 65002
#   interface       = google_compute_router_interface.interface_spoke_b_0.name
#   depends_on      = [google_compute_router_interface.interface_spoke_b_0]
# }

# # Cloud Router interface and peer for spoke_b (interface 1)
# resource "google_compute_router_interface" "interface_spoke_b_1" {
#   provider   = google.ncc
#   name       = "interface-spoke-b-1"
#   router     = google_compute_router.ncc_cloud_router.name
#   region     = "us-central1"
#   ip_range   = "169.254.3.1/30"
#   vpn_tunnel = google_compute_vpn_tunnel.tunnel_spoke_b_1.name
#   depends_on = [
#     google_compute_router.ncc_cloud_router,
#     google_compute_vpn_tunnel.tunnel_spoke_b_1
#   ]
# }

# resource "google_compute_router_peer" "peer_spoke_b_1" {
#   provider        = google.ncc
#   name            = "peer-spoke-b-1"
#   router          = google_compute_router.ncc_cloud_router.name
#   region          = "us-central1"
#   peer_ip_address = "169.254.3.2"
#   peer_asn        = 65002
#   interface       = google_compute_router_interface.interface_spoke_b_1.name
#   depends_on      = [google_compute_router_interface.interface_spoke_b_1]
# }

# # NCC spoke for spoke_b
# resource "google_network_connectivity_spoke" "vpn_spoke_b" {
#   provider = google.ncc
#   name     = "vpn-spoke-b"
#   location = "us-central1"
#   hub      = google_network_connectivity_hub.group_armageddon_hub.id

#   linked_vpn_tunnels {
#     uris = [
#       google_compute_vpn_tunnel.tunnel_spoke_b_0.id,
#       google_compute_vpn_tunnel.tunnel_spoke_b_1.id
#     ]
#     site_to_site_data_transfer = true
#   }

#   depends_on = [
#     google_compute_vpn_tunnel.tunnel_spoke_b_0,
#     google_compute_vpn_tunnel.tunnel_spoke_b_1
#   ]

#   lifecycle {
#     # Ignore changes to 'name' and 'linked_vpn_tunnels[0].uris'.
#     # The 'name' attribute is often updated automatically by GCP, causing unnecessary resource replacements, 
#     # but the actual functionality doesn't change. By ignoring this, we prevent the resource from being 
#     # destroyed and recreated unnecessarily.
#     #
#     # The 'linked_vpn_tunnels[0].uris' can also change in format (e.g., full URL vs. a shortened version), 
#     # but it doesn't impact the actual functionality of the VPN connections. This is why we ignore it too,
#     # to avoid triggering unnecessary changes that don't impact the operation of the infrastructure.
#     ignore_changes = [
#       name,
#       linked_vpn_tunnels[0].uris
#     ]
#   }
# }

# # Firewall rule to allow VPN and BGP traffic
# resource "google_compute_firewall" "allow_vpn_bgp" {
#   provider = google.ncc
#   name     = "allow-vpn-bgp"
#   network  = google_compute_network.ncc_vpc.id
#   allow {
#     protocol = "tcp"
#     ports    = ["179"]
#   }
#   allow {
#     protocol = "udp"
#     ports    = ["500", "4500"]
#   }
#   allow {
#     protocol = "esp"
#   }
#   source_ranges = [
#     "10.10.1.0/24", # Spoke A subnet
#     "10.10.2.0/24"  # Spoke B subnet
#   ]
# }

# # Firewall rule to allow spoke-to-spoke traffic
# resource "google_compute_firewall" "allow_spoke_to_spoke" {
#   provider = google.ncc
#   name     = "allow-spoke-to-spoke"
#   network  = google_compute_network.ncc_vpc.id
#   allow {
#     protocol = "all"
#   }
#   source_ranges      = ["10.10.1.0/24", "10.10.2.0/24"]
#   destination_ranges = ["10.10.1.0/24", "10.10.2.0/24"]
# }

# ######################################################
# # Spoke A (aws-ultramarines-466800) 
# ######################################################
# # Spoke A VPC
# resource "google_compute_network" "spoke_a_vpc" {
#   provider                = google.spoke_a
#   name                    = "spoke-a-vpc"
#   auto_create_subnetworks = false
# }

# # Spoke A Subnet
# resource "google_compute_subnetwork" "spoke_a_subnet" {
#   provider      = google.spoke_a
#   name          = "spoke-a-subnet"
#   network       = google_compute_network.spoke_a_vpc.id
#   ip_cidr_range = "10.10.1.0/24"
#   region        = "us-east1"
# }

# # Compute Instance for Spoke A
# resource "google_compute_instance" "spoke_a_test_vm" {
#   provider     = google.spoke_a
#   name         = "spoke-a-test-vm"
#   machine_type = "e2-micro"
#   zone         = "us-east1-b"
#   tags         = ["spoke-a-vm"]

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.spoke_a_subnet.self_link
#     # No external IP assigned to keep it private
#   }

#   depends_on = [google_compute_subnetwork.spoke_a_subnet]
# }

# # Spoke A HA Gateway
# resource "google_compute_ha_vpn_gateway" "spoke_a_vpn_gateway" {
#   provider = google.spoke_a
#   name     = "spoke-a-vpn-gateway"
#   network  = google_compute_network.spoke_a_vpc.id
#   region   = "us-east1"
# }

# # Cloud Router for spoke_a
# resource "google_compute_router" "spoke_a_router" {
#   provider = google.spoke_a
#   name     = "spoke-a-router"
#   region   = "us-east1"
#   network  = google_compute_network.spoke_a_vpc.id
#   bgp {
#     asn = 65001
#   }
# }

# resource "google_project_iam_member" "vpn_gateway_use_for_spoke_a_to_ncc" {
# # Grant the spoke_a service account permission to use ncc (hub) HA VPN Gateway.
# # This allows the spoke_a project to create VPN tunnels connecting to ncc (hub).
#   provider = google.ncc
#   project  = "ncc-project-467401"
#   role     = "roles/compute.networkUser"
#   member   = "serviceAccount:admin-34@aws-ultramarines-466800.iam.gserviceaccount.com"
# }

# # VPN tunnels to NCC hub (two tunnels for HA VPN)
# resource "google_compute_vpn_tunnel" "spoke_a_to_hub_0" {
#   provider              = google.spoke_a
#   name                  = "spoke-a-to-hub-0"
#   region                = "us-east1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
#   vpn_gateway_interface = 0
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   shared_secret         = local.shared_secret_a
#   ike_version           = 2
#   router                = google_compute_router.spoke_a_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_spoke_a_to_ncc
#   ]
# }

# resource "google_compute_vpn_tunnel" "spoke_a_to_hub_1" {
#   provider              = google.spoke_a
#   name                  = "spoke-a-to-hub-1"
#   region                = "us-east1"
#   vpn_gateway           = google_compute_ha_vpn_gateway.spoke_a_vpn_gateway.id
#   vpn_gateway_interface = 1
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   shared_secret         = local.shared_secret_a
#   ike_version           = 2
#   router                = google_compute_router.spoke_a_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_spoke_a_to_ncc
#   ]
# }

# # Cloud Router interface and peer for hub (interface 0)
# resource "google_compute_router_interface" "spoke_a_to_hub_0" {
#   provider   = google.spoke_a
#   name       = "spoke-a-to-hub-0"
#   router     = google_compute_router.spoke_a_router.name
#   region     = "us-east1"
#   ip_range   = "169.254.0.2/30"
#   vpn_tunnel = google_compute_vpn_tunnel.spoke_a_to_hub_0.name
#   depends_on = [
#     google_compute_router.spoke_a_router,
#     google_compute_vpn_tunnel.spoke_a_to_hub_0
#   ]
# }

# resource "google_compute_router_peer" "spoke_a_to_hub_0" {
#   provider        = google.spoke_a
#   name            = "spoke-a-to-hub-0"
#   router          = google_compute_router.spoke_a_router.name
#   region          = "us-east1"
#   peer_ip_address = "169.254.0.1"
#   peer_asn        = 64512
#   interface       = google_compute_router_interface.spoke_a_to_hub_0.name
#   depends_on      = [google_compute_router_interface.spoke_a_to_hub_0]
# }

# # Cloud Router interface and peer for hub (interface 1)
# resource "google_compute_router_interface" "spoke_a_to_hub_1" {
#   provider   = google.spoke_a
#   name       = "spoke-a-to-hub-1"
#   router     = google_compute_router.spoke_a_router.name
#   region     = "us-east1"
#   ip_range   = "169.254.1.2/30"
#   vpn_tunnel = google_compute_vpn_tunnel.spoke_a_to_hub_1.name
#   depends_on = [
#     google_compute_router.spoke_a_router,
#     google_compute_vpn_tunnel.spoke_a_to_hub_1
#   ]
# }

# resource "google_compute_router_peer" "spoke_a_to_hub_1" {
#   provider        = google.spoke_a
#   name            = "spoke-a-to-hub-1"
#   router          = google_compute_router.spoke_a_router.name
#   region          = "us-east1"
#   peer_ip_address = "169.254.1.1"
#   peer_asn        = 64512
#   interface       = google_compute_router_interface.spoke_a_to_hub_1.name
#   depends_on      = [google_compute_router_interface.spoke_a_to_hub_1]
# }

# # Firewall rule to allow VPN and BGP traffic
# resource "google_compute_firewall" "spoke_a_allow_vpn_bgp" {
#   provider = google.spoke_a
#   name     = "spoke-a-allow-vpn-bgp"
#   network  = google_compute_network.spoke_a_vpc.id
#   allow {
#     protocol = "tcp"
#     ports    = ["179"]
#   }
#   allow {
#     protocol = "udp"
#     ports    = ["500", "4500"]
#   }
#   allow {
#     protocol = "esp"
#   }
#   source_ranges = [
#     "10.99.0.0/24" # NCC hub subnet
#   ]
# }

# # Firewall rule to allow spoke-to-spoke traffic
# resource "google_compute_firewall" "spoke_a_allow_spoke_to_spoke" {
#   provider = google.spoke_a
#   name     = "spoke-a-allow-spoke-to-spoke"
#   network  = google_compute_network.spoke_a_vpc.id
#   allow {
#     protocol = "all"
#   }
#   source_ranges      = ["10.10.2.0/24"]
#   destination_ranges = ["10.10.1.0/24"]
# }

# resource "google_compute_firewall" "spoke_a_allow_iap_ssh" {
#   provider = google.spoke_a
#   name     = "spoke-a-allow-iap-ssh"
#   network  = google_compute_network.spoke_a_vpc.id

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = ["35.235.240.0/20"]

#   target_tags = ["spoke-a-vm"]
# }

# ######################################################
# # Spoke B (warm-scout-464100-j3) 
# ######################################################
# # Spoke B VPC
# resource "google_compute_network" "spoke_b_vpc" {
#   provider                = google.spoke_b
#   name                    = "spoke-b-vpc"
#   auto_create_subnetworks = false
# }

# # Spoke B Subnet
# resource "google_compute_subnetwork" "spoke_b_subnet" {
#   provider      = google.spoke_b
#   name          = "spoke-b-subnet"
#   network       = google_compute_network.spoke_b_vpc.id
#   ip_cidr_range = "10.10.2.0/24"
#   region        = "europe-west2"
# }

# # Compute Instance for Spoke B
# resource "google_compute_instance" "spoke_b_test_vm" {
#   provider     = google.spoke_b
#   name         = "spoke-b-test-vm"
#   machine_type = "e2-micro"
#   zone         = "europe-west2-a"
#   tags         = ["spoke-b-vm"]

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.spoke_b_subnet.self_link
#     # No external IP assigned to keep it private
#   }

#   depends_on = [google_compute_subnetwork.spoke_b_subnet]
# }

# # Spoke B HA VPN Gateway 
# resource "google_compute_ha_vpn_gateway" "spoke_b_vpn_gateway" {
#   provider = google.spoke_b
#   name     = "spoke-b-vpn-gateway"
#   network  = google_compute_network.spoke_b_vpc.id
#   region   = "europe-west2"
# }

# # Cloud Router for spoke_b
# resource "google_compute_router" "spoke_b_router" {
#   provider = google.spoke_b
#   name     = "spoke-b-router"
#   region   = "europe-west2"
#   network  = google_compute_network.spoke_b_vpc.id
#   bgp {
#     asn = 65002
#   }
# }

# resource "google_project_iam_member" "vpn_gateway_use_for_spoke_b_to_ncc" {
# # Grant the spoke_b service account permission to use ncc (hub) HA VPN Gateway.
# # This allows the spoke_b project to create VPN tunnels connecting to ncc (hub).
#   provider = google.ncc
#   project  = "ncc-project-467401"
#   role     = "roles/compute.networkUser"
#   member   = "serviceAccount:admin-532@pelagic-core-467122-q4.iam.gserviceaccount.com"
# }

# # VPN tunnels to NCC hub (two tunnels for HA VPN)
# resource "google_compute_vpn_tunnel" "spoke_b_to_hub_0" {
#   provider              = google.spoke_b
#   name                  = "spoke-b-to-hub-0"
#   region                = "europe-west2"
#   vpn_gateway           = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
#   vpn_gateway_interface = 0
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   shared_secret         = local.shared_secret_b
#   ike_version           = 2
#   router                = google_compute_router.spoke_b_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_spoke_b_to_ncc
#   ]
# }

# resource "google_compute_vpn_tunnel" "spoke_b_to_hub_1" {
#   provider              = google.spoke_b
#   name                  = "spoke-b-to-hub-1"
#   region                = "europe-west2"
#   vpn_gateway           = google_compute_ha_vpn_gateway.spoke_b_vpn_gateway.id
#   vpn_gateway_interface = 1
#   peer_gcp_gateway      = google_compute_ha_vpn_gateway.ncc_vpn_gateway.id
#   shared_secret         = local.shared_secret_b
#   ike_version           = 2
#   router                = google_compute_router.spoke_b_router.id

#   depends_on = [
#     null_resource.generate_shared_secrets,
#     google_project_iam_member.vpn_gateway_use_for_spoke_b_to_ncc
#   ]
# }

# # Cloud Router interface and peer for hub (interface 0)
# resource "google_compute_router_interface" "spoke_b_to_hub_0" {
#   provider   = google.spoke_b
#   name       = "spoke-b-to-hub-0"
#   router     = google_compute_router.spoke_b_router.name
#   region     = "europe-west2"
#   ip_range   = "169.254.2.2/30"
#   vpn_tunnel = google_compute_vpn_tunnel.spoke_b_to_hub_0.name
#   depends_on = [
#     google_compute_router.spoke_b_router,
#     google_compute_vpn_tunnel.spoke_b_to_hub_0
#   ]
# }

# resource "google_compute_router_peer" "spoke_b_to_hub_0" {
#   provider        = google.spoke_b
#   name            = "spoke-b-to-hub-0"
#   router          = google_compute_router.spoke_b_router.name
#   region          = "europe-west2"
#   peer_ip_address = "169.254.2.1"
#   peer_asn        = 64512
#   interface       = google_compute_router_interface.spoke_b_to_hub_0.name
#   depends_on      = [google_compute_router_interface.spoke_b_to_hub_0]
# }

# # Cloud Router interface and peer for hub (interface 1)
# resource "google_compute_router_interface" "spoke_b_to_hub_1" {
#   provider   = google.spoke_b
#   name       = "spoke-b-to-hub-1"
#   router     = google_compute_router.spoke_b_router.name
#   region     = "europe-west2"
#   ip_range   = "169.254.3.2/30"
#   vpn_tunnel = google_compute_vpn_tunnel.spoke_b_to_hub_1.name
#   depends_on = [
#     google_compute_router.spoke_b_router,
#     google_compute_vpn_tunnel.spoke_b_to_hub_1
#   ]
# }

# resource "google_compute_router_peer" "spoke_b_to_hub_1" {
#   provider        = google.spoke_b
#   name            = "spoke-b-to-hub-1"
#   router          = google_compute_router.spoke_b_router.name
#   region          = "europe-west2"
#   peer_ip_address = "169.254.3.1"
#   peer_asn        = 64512
#   interface       = google_compute_router_interface.spoke_b_to_hub_1.name
#   depends_on      = [google_compute_router_interface.spoke_b_to_hub_1]
# }

# # Firewall rule to allow VPN and BGP traffic
# resource "google_compute_firewall" "spoke_b_allow_vpn_bgp" {
#   provider = google.spoke_b
#   name     = "spoke-b-allow-vpn-bgp"
#   network  = google_compute_network.spoke_b_vpc.id
#   allow {
#     protocol = "tcp"
#     ports    = ["179"]
#   }
#   allow {
#     protocol = "udp"
#     ports    = ["500", "4500"]
#   }
#   allow {
#     protocol = "esp"
#   }
#   source_ranges = [
#     "10.99.0.0/24" # NCC hub subnet
#   ]
# }

# # Firewall rule to allow spoke-to-spoke traffic
# resource "google_compute_firewall" "spoke_b_allow_spoke_to_spoke" {
#   provider = google.spoke_b
#   name     = "spoke-b-allow-spoke-to-spoke"
#   network  = google_compute_network.spoke_b_vpc.id
#   allow {
#     protocol = "all"
#   }
#   source_ranges      = ["10.10.1.0/24"]
#   destination_ranges = ["10.10.2.0/24"]
# }

# resource "google_compute_firewall" "spoke_b_allow_iap_ssh" {
#   provider = google.spoke_b
#   name     = "spoke-b-allow-iap-ssh"
#   network  = google_compute_network.spoke_b_vpc.id

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = ["35.235.240.0/20"]

#   target_tags = ["spoke-b-vm"]
# }

# ######################################################
# # Output shared secrets for verification (sensitive)
# output "shared_secret_a_output" {
#   value     = local.shared_secret_a
#   sensitive = true
# }

# output "shared_secret_b_output" {
#   value     = local.shared_secret_b
#   sensitive = true
# }

# # Output private IPs of test VMs for connectivity testing
# output "spoke_a_test_vm_ip" {
#   value = google_compute_instance.spoke_a_test_vm.network_interface[0].network_ip
# }

# output "spoke_b_test_vm_ip" {
#   value = google_compute_instance.spoke_b_test_vm.network_interface[0].network_ip
# }
