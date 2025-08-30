# Terraform GCP NCC Hub and Spoke Configuration

This repository contains two Terraform configurations for deploying a Google Cloud Platform (GCP) Network Connectivity Center (NCC) hub and spoke architecture: a **monolith configuration** and a **modular configuration**.

Both configurations create an NCC hub in one GCP project (`ncc-project-467401`) and connect two spokes (`aws-ultramarines-466800` in `us-east1` and `pelagic-core-467122-q4` in `europe-west2`) using HA VPN tunnels.

The configurations have been tested and successfully deploy a functional NCC hub and spoke setup with:

* VPCs
* Subnets
* Cloud Routers
* BGP peering
* Firewall rules
* Optional test VMs

---

##  VPN & BGP Interface Mapping (NCC ↔ Spoke A & B)

This table shows the dependency-ordered infrastructure components and IP interface mapping between the NCC Hub and each Spoke (A & B). Use this to understand which resource owns which BGP interface IP, and how the peer relationships work.


###  NCC ↔ Spoke A

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

###  NCC ↔ Spoke B

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

### 🧠 IP Address Convention

For each `/30` subnet used for BGP over VPN:

* **`.1` IP** is **always the NCC (hub) interface**
* **`.2` IP** is **always the Spoke (A or B) interface**
* Each side uses the **other’s IP as the BGP peer IP** in configuration

---

## Monolith Configuration

### Structure

**Files:**

* `main.tf`: Contains all resource definitions for the NCC hub, spokes, VPN tunnels, Cloud Routers, firewall rules, IAM permissions, and test VMs.
* No separate `variables.tf` or `outputs.tf` files; variables and outputs are defined inline.

**Resources:**

* NCC hub (`group_armageddon_hub`) with a VPC (`ncc-hub-vpc`) and subnet (`10.99.0.0/24`)
* Two spokes, each with:

  * VPC
  * Subnet (`10.10.1.0/24` for Spoke A, `10.10.2.0/24` for Spoke B)
  * HA VPN gateway
  * Cloud Router
  * Test VM
* HA VPN tunnels (two per spoke) with BGP peering for connectivity
* Firewall rules for:

  * VPN/BGP traffic
  * Spoke-to-spoke communication
  * IAP SSH access
* Shared secrets for VPN tunnels generated via a `null_resource` and stored in local files

**Outputs:**

* Shared secrets and test VM private IPs, defined inline with minimal documentation

---

### Pros

* **Simplicity**: All resources in a single file make it easy to understand and deploy for small, one-off setups or prototyping
* **Quick Deployment**: No need to manage multiple files or module dependencies; a single `terraform apply` deploys everything
* **Minimal Overhead**: No module structure reduces initial setup time

---

### Cons

* **Poor Maintainability**: The large `main.tf` (over 400 lines) is hard to navigate
* **No Reusability**: Difficult to reuse components without copying and editing the entire file
* **Non-Compliant with Conventions**:

  * Inline variables and outputs
  * Inconsistent naming (e.g., `group_armageddon_hub` vs. `ncc_vpn_gateway`)
  * Hardcoded values (e.g., project IDs, CIDRs)
  * Lack of validation/descriptions
* **Scalability Issues**: Adding spokes requires duplicating large blocks of code
* **Collaboration Challenges**: Single file increases merge conflicts
* **Fragile Secret Management**: Uses `null_resource` with `local-exec` to store secrets in local files (insecure and non-reproducible)

---

## Modular Configuration

### Structure

**Directory Layout:**

```
.
├── main.tf
├── terraform.tfvars
├── ncc-hub-spoke-module/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
```

**Root Module:**

* `main.tf`: Calls the `ncc-hub-spoke-module` with variable inputs
* `terraform.tfvars`: Provides specific values for the module

**Child Module (`ncc-hub-spoke-module`):**

* `main.tf`: Defines all resources
* `variables.tf`: Variable definitions with descriptions, defaults, validations
* `outputs.tf`: Outputs for shared secrets, test VM IPs, and VPC IDs

**Resources:** (Same as monolith but parameterized)

* NCC hub with VPC `${var.prefix}-ncc-hub-vpc` and subnet `10.190.0.0/24`
* Spokes with:

  * VPCs
  * Subnets (`10.190.1.0/24` for Spoke A, `10.190.2.0/24` for Spoke B)
  * HA VPN gateways, Cloud Routers
  * Optional test VMs
* HA VPN tunnels, BGP peering, parameterized IP ranges and ASNs
* Firewall rules for VPN/BGP, IAP SSH (conditional for test VMs)
* Shared secrets using the `random_id` provider

---

### Conventions

* Separate `variables.tf` and `outputs.tf` files
* Consistent naming with prefix variable (e.g., `walid-ncc-hub`)
* Descriptive variable names (e.g., `ncc_project_id`, `spoke_a_subnet_cidr`)
* Comments explaining resource purposes
* Use of `random_id` for secrets
* Conditional test VM deployment via `deploy_test_vms` variable

---

### Pros

* **Maintainability**: Easier to navigate and update
* **Reusability**: Reuse the module across environments with different variables
* **Scalability**: Add spokes by reusing/extending the module
* **Team Collaboration**: Smaller, separate files reduce merge conflicts
* **Best Practices**:

  * Clear variable/output documentation
  * Consistent naming
  * Input validation
* **Improved Secret Management**: Uses in-memory `random_id` instead of local files
* **Flexibility**: Conditional logic allows resource toggling (e.g., test VMs)

---

### Cons

* **Increased Complexity**: Requires understanding of modules
* **Setup Overhead**: More files to manage
* **Learning Curve**: Teams unfamiliar with modules may need time
* **Potential Over-Engineering**: May be too complex for very small projects

---

## Usage

### Prerequisites

* Terraform >= 1.0.0
* Google Cloud SDK configured
* GCP projects with NCC & Compute Engine APIs enabled
* Service account JSON key files for hub and spoke projects
* Directory `../../G-secrets/` containing credentials (as defined in `terraform.tfvars`)

---

### Monolith

Place `main.tf` in a directory alongside:

```
../../G-secrets/
├── ncc-project-467401-210df7f1e23a.json
├── aws-ultramarines-466800-7908714403bd.json
├── pelagic-core-467122-q4-25d0b2aa49f2.json
```

Run:

```bash
terraform init
terraform apply
```

Shared secrets are written to:

* `../../G-secrets/shared_secretsA.txt`
* `../../G-secrets/shared_secretsB.txt`

---

### Modular

Place:

* `main.tf`
* `terraform.tfvars`
* `ncc-hub-spoke-module/` directory
  in the same directory, with credentials in `../../G-secrets/`.

Update `terraform.tfvars` with your project info.

Run:

```bash
terraform init
terraform apply -var-file="terraform.tfvars"
```

Outputs include:

* Shared secrets (sensitive)
* Test VM IPs (if `deploy_test_vms = true`)

---

### Example Variables (Modular)

Key variables in `terraform.tfvars`:

```hcl
prefix = "walid"
ncc_project_id = "ncc-project-467401"
spoke_a_project_id = "aws-ultramarines-466800"
spoke_b_project_id = "pelagic-core-467122-q4"

ncc_subnet_cidr = "10.190.0.0/24"
spoke_a_subnet_cidr = "10.190.1.0/24"
spoke_b_subnet_cidr = "10.190.2.0/24"

ncc_credentials_path = "../../G-secrets/ncc-project-467401-210df7f1e23a.json"
spoke_a_credentials_path = "../../G-secrets/aws-ultramarines-466800-7908714403bd.json"
spoke_b_credentials_path = "../../G-secrets/pelagic-core-467122-q4-25d0b2aa49f2.json"

deploy_test_vms = true
```

---

## Key Differences

| Aspect                  | Monolith                                    | Modular                                                   |
| ----------------------- | ------------------------------------------- | --------------------------------------------------------- |
| **Secret Generation**   | `null_resource` with local-exec to files    | `random_id` for secure in-memory generation               |
| **Variable Management** | Hardcoded project IDs and CIDRs             | Parameterized with validation and defaults                |
| **Naming**              | Inconsistent (e.g., `group_armageddon_hub`) | Consistent with prefix (`walid-ncc-hub`)                  |
| **Structure**           | Single `main.tf` file                       | Separate root/module with `variables.tf` and `outputs.tf` |
| **Flexibility**         | Static, limited                             | Conditional test VMs, easy multi-spoke extension          |

---

## Recommendations

* **Use the Monolith for**:

  * Rapid prototyping
  * Small, temporary deployments
  * When simplicity outweighs long-term maintainability

* **Use the Modular Configuration for**:

  * Production environments
  * Multi-project deployments
  * Team collaboration and scalability

**Migration Path**:
If starting with the monolith, refactor by:

* Extracting resources into a module
* Creating `variables.tf` with validations
* Using `random_id` for secrets
* Using a prefix for consistent naming
* Moving outputs to `outputs.tf` with documentation

---

## Contributing

Contributions are welcome! Please follow these conventions:

* Use lowercase letters, numbers, and hyphens for resource names
* Define variables and outputs in `variables.tf` and `outputs.tf`
* Add descriptive comments and validations
* Test in a non-production environment before submitting

## Changelog

# v1.0.0
- initial release