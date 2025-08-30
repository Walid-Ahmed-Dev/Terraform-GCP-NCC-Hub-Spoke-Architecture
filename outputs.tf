output "spoke_a_test_vm_ip" {
  description = "Output from child module: Spoke A test VM private IP"
  value       = module.ncc_hub_spoke.spoke_a_test_vm_ip
}

output "spoke_b_test_vm_ip" {
  description = "Output from child module: Spoke B test VM private IP"
  value       = module.ncc_hub_spoke.spoke_b_test_vm_ip
}

output "ncc_vpc_id" {
  description = "ID of the NCC hub VPC"
  value       = module.ncc_hub_spoke.ncc_vpc_id
}

output "spoke_a_vpc_id" {
  description = "ID of the Spoke A VPC"
  value       = module.ncc_hub_spoke.spoke_a_vpc_id
}

output "spoke_b_vpc_id" {
  description = "ID of the Spoke B VPC"
  value       = module.ncc_hub_spoke.spoke_b_vpc_id
}
