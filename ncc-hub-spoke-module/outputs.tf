output "shared_secret_a" {
  description = "Shared secret for NCC to Spoke A VPN tunnels"
  value       = local.shared_secret_a
  sensitive   = true
}

output "shared_secret_b" {
  description = "Shared secret for NCC to Spoke B VPN tunnels"
  value       = local.shared_secret_b
  sensitive   = true
}

output "spoke_a_test_vm_ip" {
  description = "Private IP of the Spoke A test VM"
  value       = var.deploy_test_vms ? google_compute_instance.spoke_a_test_vm.network_interface[0].network_ip : null
}

output "spoke_b_test_vm_ip" {
  description = "Private IP of the Spoke B test VM"
  value       = var.deploy_test_vms ? google_compute_instance.spoke_b_test_vm.network_interface[0].network_ip : null
}


output "ncc_vpc_id" {
  description = "ID of the NCC hub VPC"
  value       = google_compute_network.ncc_vpc.id
}

output "spoke_a_vpc_id" {
  description = "ID of the Spoke A VPC"
  value       = google_compute_network.spoke_a_vpc.id
}

output "spoke_b_vpc_id" {
  description = "ID of the Spoke B VPC"
  value       = google_compute_network.spoke_b_vpc.id
}