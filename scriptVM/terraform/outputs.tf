output "ipv4" {
  value = data.vsphere_virtual_machine.result[*].guest_ip_addresses[0] #Retroune l'addresse ip de toutes les VMs
}