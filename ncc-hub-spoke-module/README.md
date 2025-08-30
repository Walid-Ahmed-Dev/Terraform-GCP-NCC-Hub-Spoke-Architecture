# NCC Hub-and-Spoke Module

This Terraform module sets up a hub-and-spoke network architecture in Google Cloud Platform (GCP) using Network Connectivity Center (NCC). It creates a hub VPC with a subnet, HA VPN gateways, cloud routers, and VPN tunnels to connect two spoke VPCs (Spoke A and Spoke B). Each spoke has its own VPC, subnet, optional test VM, HA VPN gateway, and cloud router. The module also configures firewall rules for VPN, BGP, and spoke-to-spoke communication.

## Features

- Creates a hub-and-spoke topology with NCC hub and two spokes.
- Configures HA VPN tunnels for high availability.
- Generates random shared secrets for VPN tunnels.
- Supports optional test VMs for connectivity testing.
- Includes firewall rules for VPN, BGP, and spoke-to-spoke traffic.
- Parameterized for flexibility across different projects and regions.
- Configures BGP peering for dynamic routing between hub and spokes.

## Requirements

- Terraform >= 1.0.0  
- Google Cloud provider >= 6.0  
- Random provider >= 3.0  
- Null provider >= 3.0  
- Valid GCP credentials for the hub and spoke projects  
- Service accounts with appropriate permissions  

## Usage

Create a Terraform configuration that calls the module:

```hcl
module "ncc_hub_spoke" {
  source                   = "./ncc-hub-spoke"
  prefix                   = "my-ncc"
  ncc_project_id           = "ncc-project-467401"
  ncc_region               = "us-central1"
  ncc_subnet_cidr          = "10.190.0.0/24"
  ncc_asn                  = 64512
  ncc_credentials_path     = "../../G-secrets/ncc-project-467401-210df7f1e23a.json"
  ncc_service_account      = "admin-428@ncc-project-467401.iam.gserviceaccount.com"
  spoke_a_project_id       = "aws-ultramarines-466800"
  spoke_a_region           = "us-east1"
  spoke_a_subnet_cidr      = "10.10.1.0/24"
  spoke_a_asn              = 65001
  spoke_a_credentials_path = "../../G-secrets/aws-ultramarines-466800-7908714403bd.json"
  spoke_a_service_account  = "admin-34@aws-ultramarines-466800.iam.gserviceaccount.com"
  spoke_b_project_id       = "pelagic-core-467122-q4"
  spoke_b_region           = "europe-west2"
  spoke_b_subnet_cidr      = "10.10.2.0/24"
  spoke_b_asn              = 65002
  spoke_b_credentials_path = "../../G-secrets/pelagic-core-467122-q4-25d0b2aa49f2.json"
  spoke_b_service_account  = "admin-532@pelagic-core-467122-q4.iam.gserviceaccount.com"
  deploy_test_vms          = true
  test_vm_machine_type     = "e2-micro"
  test_vm_image            = "debian-cloud/debian-11"

  ncc_to_spoke_a_ip_range_0  = "169.254.0.1/30"
  spoke_a_to_ncc_ip_range_0  = "169.254.0.2/30"
  spoke_a_to_ncc_peer_ip_0   = "169.254.0.2"
  ncc_to_spoke_a_peer_ip_0   = "169.254.0.1"
  ncc_to_spoke_a_ip_range_1  = "169.254.1.1/30"
  spoke_a_to_ncc_ip_range_1  = "169.254.1.2/30"
  spoke_a_to_ncc_peer_ip_1   = "169.254.1.2"
  ncc_to_spoke_a_peer_ip_1   = "169.254.1.1"

  ncc_to_spoke_b_ip_range_0  = "169.254.2.1/30"
  spoke_b_to_ncc_ip_range_0  = "169.254.2.2/30"
  spoke_b_to_ncc_peer_ip_0   = "169.254.2.2"
  ncc_to_spoke_b_peer_ip_0   = "169.254.2.1"
  ncc_to_spoke_b_ip_range_1  = "169.254.3.1/30"
  spoke_b_to_ncc_ip_range_1  = "169.254.3.2/30"
  spoke_b_to_ncc_peer_ip_1   = "169.254.3.2"
  ncc_to_spoke_b_peer_ip_1   = "169.254.3.1"
}
````

## Inputs

| Name                            | Description                          | Type     | Default                    | Required |
| ------------------------------- | ------------------------------------ | -------- | -------------------------- | :------: |
| prefix                          | Prefix for resource names            | `string` | `"ncc"`                    |    No    |
| ncc\_project\_id                | GCP project ID for the NCC hub       | `string` |                            |    Yes   |
| ncc\_region                     | GCP region for the NCC hub           | `string` | `"us-central1"`            |    No    |
| ncc\_subnet\_cidr               | CIDR range for the NCC hub subnet    | `string` | `"10.190.0.0/24"`          |    No    |
| ncc\_asn                        | BGP ASN for the NCC hub              | `number` | `64512`                    |    No    |
| ncc\_credentials\_path          | Path to NCC hub credentials JSON     | `string` |                            |    Yes   |
| ncc\_service\_account           | Service account email for NCC hub    | `string` |                            |    Yes   |
| spoke\_a\_project\_id           | GCP project ID for Spoke A           | `string` |                            |    Yes   |
| spoke\_a\_region                | GCP region for Spoke A               | `string` | `"us-east1"`               |    No    |
| spoke\_a\_subnet\_cidr          | CIDR range for Spoke A subnet        | `string` | `"10.10.1.0/24"`           |    No    |
| spoke\_a\_asn                   | BGP ASN for Spoke A                  | `number` | `65001`                    |    No    |
| spoke\_a\_credentials\_path     | Path to Spoke A credentials JSON     | `string` |                            |    Yes   |
| spoke\_a\_service\_account      | Service account email for Spoke A    | `string` |                            |    Yes   |
| spoke\_b\_project\_id           | GCP project ID for Spoke B           | `string` |                            |    Yes   |
| spoke\_b\_region                | GCP region for Spoke B               | `string` | `"europe-west2"`           |    No    |
| spoke\_b\_subnet\_cidr          | CIDR range for Spoke B subnet        | `string` | `"10.10.2.0/24"`           |    No    |
| spoke\_b\_asn                   | BGP ASN for Spoke B                  | `number` | `65002`                    |    No    |
| spoke\_b\_credentials\_path     | Path to Spoke B credentials JSON     | `string` |                            |    Yes   |
| spoke\_b\_service\_account      | Service account email for Spoke B    | `string` |                            |    Yes   |
| ncc\_to\_spoke\_a\_ip\_range\_0 | IP range for NCC to Spoke A tunnel 0 | `string` | `"169.254.0.1/30"`         |    No    |
| spoke\_a\_to\_ncc\_ip\_range\_0 | IP range for Spoke A to NCC tunnel 0 | `string` | `"169.254.0.2/30"`         |    No    |
| spoke\_a\_to\_ncc\_peer\_ip\_0  | Peer IP for Spoke A to NCC tunnel 0  | `string` | `"169.254.0.2"`            |    No    |
| ncc\_to\_spoke\_a\_peer\_ip\_0  | Peer IP for NCC to Spoke A tunnel 0  | `string` | `"169.254.0.1"`            |    No    |
| ncc\_to\_spoke\_a\_ip\_range\_1 | IP range for NCC to Spoke A tunnel 1 | `string` | `"169.254.1.1/30"`         |    No    |
| spoke\_a\_to\_ncc\_ip\_range\_1 | IP range for Spoke A to NCC tunnel 1 | `string` | `"169.254.1.2/30"`         |    No    |
| spoke\_a\_to\_ncc\_peer\_ip\_1  | Peer IP for Spoke A to NCC tunnel 1  | `string` | `"169.254.1.2"`            |    No    |
| ncc\_to\_spoke\_a\_peer\_ip\_1  | Peer IP for NCC to Spoke A tunnel 1  | `string` | `"169.254.1.1"`            |    No    |
| ncc\_to\_spoke\_b\_ip\_range\_0 | IP range for NCC to Spoke B tunnel 0 | `string` | `"169.254.2.1/30"`         |    No    |
| spoke\_b\_to\_ncc\_ip\_range\_0 | IP range for Spoke B to NCC tunnel 0 | `string` | `"169.254.2.2/30"`         |    No    |
| spoke\_b\_to\_ncc\_peer\_ip\_0  | Peer IP for Spoke B to NCC tunnel 0  | `string` | `"169.254.2.2"`            |    No    |
| ncc\_to\_spoke\_b\_peer\_ip\_0  | Peer IP for NCC to Spoke B tunnel 0  | `string` | `"169.254.2.1"`            |    No    |
| ncc\_to\_spoke\_b\_ip\_range\_1 | IP range for NCC to Spoke B tunnel 1 | `string` | `"169.254.3.1/30"`         |    No    |
| spoke\_b\_to\_ncc\_ip\_range\_1 | IP range for Spoke B to NCC tunnel 1 | `string` | `"169.254.3.2/30"`         |    No    |
| spoke\_b\_to\_ncc\_peer\_ip\_1  | Peer IP for Spoke B to NCC tunnel 1  | `string` | `"169.254.3.2"`            |    No    |
| ncc\_to\_spoke\_b\_peer\_ip\_1  | Peer IP for NCC to Spoke B tunnel 1  | `string` | `"169.254.3.1"`            |    No    |
| deploy\_test\_vms               | Deploy test VMs in spokes            | `bool`   | `true`                     |    No    |
| test\_vm\_machine\_type         | Machine type for test VMs            | `string` | `"e2-micro"`               |    No    |
| test\_vm\_image                 | Disk image for test VMs              | `string` | `"debian-cloud/debian-11"` |    No    |

## Outputs

| Name                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| shared\_secret\_a      | Shared secret for NCC to Spoke A VPN tunnels |
| shared\_secret\_b      | Shared secret for NCC to Spoke B VPN tunnels |
| spoke\_a\_test\_vm\_ip | Private IP of Spoke A test VM                |
| spoke\_b\_test\_vm\_ip | Private IP of Spoke B test VM                |
| ncc\_vpc\_id           | ID of the NCC hub VPC                        |
| spoke\_a\_vpc\_id      | ID of the Spoke A VPC                        |
| spoke\_b\_vpc\_id      | ID of the Spoke B VPC                        |

---

## VPN & BGP Interface Mapping (NCC ↔ Spoke A & B)

This table shows the dependency-ordered infrastructure components and IP interface mapping between the NCC Hub and each Spoke (A & B). Use this to understand which resource owns which BGP interface IP, and how the peer relationships work.

---

### NCC ↔ Spoke A

| Step | Type             | Description                        | Interface Owner | IP Address    | CIDR  | Used As BGP Peer By | Terraform Resource Block                        |
| ---- | ---------------- | ---------------------------------- | --------------- | ------------- | ----- | ------------------- | ----------------------------------------------- |
| 1    | VPN Tunnel       | VPN tunnel from Spoke A to NCC (0) | N/A             | N/A           | N/A   | N/A                 | `google_compute_vpn_tunnel.spoke_a_to_ncc_0`    |
| 2    | VPN Tunnel       | VPN tunnel from Spoke A to NCC (1) | N/A             | N/A           | N/A   | N/A                 | `google_compute_vpn_tunnel.spoke_a_to_ncc_1`    |
| 3    | Router Interface | NCC interface for tunnel 0         | NCC             | `169.254.0.1` | `/30` | Spoke A             | `google_compute_router_interface.ncc_spoke_a_0` |
| 4    | Router Interface | Spoke A interface for tunnel 0     | Spoke A         | `169.254.0.2` | `/30` | NCC                 | `google_compute_router_interface.spoke_a_ncc_0` |
| 5    | Router Interface | NCC interface for tunnel 1         | NCC             | `169.254.1.1` | `/30` | Spoke A             | `google_compute_router_interface.ncc_spoke_a_1` |
| 6    | Router Interface | Spoke A interface for tunnel 1     | Spoke A         | `169.254.1.2` | `/30` | NCC                 | `google_compute_router_interface.spoke_a_ncc_1` |
| 7    | BGP Peer         | Spoke A peering to NCC (tunnel 0)  | Spoke A         | peer = `.1`   | N/A   | Spoke A             | `google_compute_router_peer.spoke_a_ncc_0`      |
| 8    | BGP Peer         | Spoke A peering to NCC (tunnel 1)  | Spoke A         | peer = `.1`   | N/A   | Spoke A             | `google_compute_router_peer.spoke_a_ncc_1`      |
| 9    | BGP Peer         | NCC peering to Spoke A (tunnel 0)  | NCC             | peer = `.2`   | N/A   | NCC                 | `google_compute_router_peer.ncc_spoke_a_0`      |
| 10   | BGP Peer         | NCC peering to Spoke A (tunnel 1)  | NCC             | peer = `.2`   | N/A   | NCC                 | `google_compute_router_peer.ncc_spoke_a_1`      |

### NCC ↔ Spoke B

| Step | Type             | Description                        | Interface Owner | IP Address    | CIDR  | Used As BGP Peer By | Terraform Resource Block                        |
| ---- | ---------------- | ---------------------------------- | --------------- | ------------- | ----- | ------------------- | ----------------------------------------------- |
| 1    | VPN Tunnel       | VPN tunnel from Spoke B to NCC (0) | N/A             | N/A           | N/A   | N/A                 | `google_compute_vpn_tunnel.spoke_b_to_ncc_0`    |
| 2    | VPN Tunnel       | VPN tunnel from Spoke B to NCC (1) | N/A             | N/A           | N/A   | N/A                 | `google_compute_vpn_tunnel.spoke_b_to_ncc_1`    |
| 3    | Router Interface | NCC interface for tunnel 0         | NCC             | `169.254.2.1` | `/30` | Spoke B             | `google_compute_router_interface.ncc_spoke_b_0` |
| 4    | Router Interface | Spoke B interface for tunnel 0     | Spoke B         | `169.254.2.2` | `/30` | NCC                 | `google_compute_router_interface.spoke_b_ncc_0` |
| 5    | Router Interface | NCC interface for tunnel 1         | NCC             | `169.254.3.1` | `/30` | Spoke B             | `google_compute_router_interface.ncc_spoke_b_1` |
| 6    | Router Interface | Spoke B interface for tunnel 1     | Spoke B         | `169.254.3.2` | `/30` | NCC                 | `google_compute_router_interface.spoke_b_ncc_1` |
| 7    | BGP Peer         | Spoke B peering to NCC (tunnel 0)  | Spoke B         | peer = `.1`   | N/A   | Spoke B             | `google_compute_router_peer.spoke_b_ncc_0`      |
| 8    | BGP Peer         | Spoke B peering to NCC (tunnel 1)  | Spoke B         | peer = `.1`   | N/A   | Spoke B             | `google_compute_router_peer.spoke_b_ncc_1`      |
| 9    | BGP Peer         | NCC peering to Spoke B (tunnel 0)  | NCC             | peer = `.2`   | N/A   | NCC                 | `google_compute_router_peer.ncc_spoke_b_0`      |
| 10   | BGP Peer         | NCC peering to Spoke B (tunnel 1)  | NCC             | peer = `.2`   | N/A   | NCC                 | `google_compute_router_peer.ncc_spoke_b_1`      |

### IP Address Convention

For each `/30` subnet used for BGP over VPN:

* **`.1` IP** is **always the NCC (hub) interface**
* **`.2` IP** is **always the Spoke (A or B) interface**
* Each side uses the **other’s IP as the BGP peer IP** in configuration
---

## Notes

* Ensure that the service accounts have the necessary permissions (`roles/compute.networkUser`) in their respective projects.
* Shared secrets are generated randomly and marked as sensitive.
* Test VMs are optional and controlled by the `deploy_test_vms` variable.
* CIDR ranges and ASNs must be unique and non-overlapping.
* Firewall rules are configured with a priority of `1000` for consistency.
* The module includes validation for project IDs, CIDR ranges, ASNs, and service account emails to ensure proper configuration.
* Use the provided IP ranges and peer IPs for VPN tunnels to avoid connectivity issues.
