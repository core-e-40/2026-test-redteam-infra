output "target_windows_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.target_windows :
    k => v.network[0].fixed_ip_v4
  }
}

output "target_linux_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.target_linux :
    k => v.network[0].fixed_ip_v4
  }
}

output "blueteam_windows_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.bt_windows :
    k => v.network[0].fixed_ip_v4
  }
}

output "blueteam_linux_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.bt_linux :
    k => v.network[0].fixed_ip_v4
  }
}

output "red_team_ips" {
  value = {
    for k, v in openstack_compute_instance_v2.red_machines :
    k => v.network[0].fixed_ip_v4
  }
}

output "ansible_inventory_hint" {
  value = "Run: cd ../ansible && ./gen_inventory.sh to build inventory from this state"
}
