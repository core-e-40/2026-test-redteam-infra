terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 2.0"
    }
  }
}

provider "openstack" {
  # Reads from clouds.yaml or OS_* env vars automatically
  # cloud = "mycloud"   # uncomment if using clouds.yaml with named cloud
  auth_url	= "https://openstack.cyberrange.rit.edu:5000/v3"
  application_credential_id	= var.app_cred_id
  application_credential_secret = var.app_cred_secret
}

# ─────────────────────────────────────────────
# NETWORKS
# ─────────────────────────────────────────────

resource "openstack_networking_network_v2" "target_net" {
  name           = "scp-target-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "target_subnet" {
  name            = "scp-target-subnet"
  network_id      = openstack_networking_network_v2.target_net.id
  cidr            = "10.10.10.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]

  allocation_pool {
    start = "10.10.10.10"
    end   = "10.10.10.200"
  }
}

resource "openstack_networking_network_v2" "red_net" {
  name           = "scp-red-net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "red_subnet" {
  name            = "scp-red-subnet"
  network_id      = openstack_networking_network_v2.red_net.id
  cidr            = "10.10.100.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]

  allocation_pool {
    start = "10.10.100.10"
    end   = "10.10.100.200"
  }
}

# ─────────────────────────────────────────────
# ROUTER — connects both subnets + external
# ─────────────────────────────────────────────

resource "openstack_networking_router_v2" "scp_router" {
  name                = "scp-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "target_router_iface" {
  router_id = openstack_networking_router_v2.scp_router.id
  subnet_id = openstack_networking_subnet_v2.target_subnet.id
}

resource "openstack_networking_router_interface_v2" "red_router_iface" {
  router_id = openstack_networking_router_v2.scp_router.id
  subnet_id = openstack_networking_subnet_v2.red_subnet.id
}

data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

# ─────────────────────────────────────────────
# KEYPAIR
# ─────────────────────────────────────────────

resource "openstack_compute_keypair_v2" "scp_key" {
  name       = "scp-lab-key"
  public_key = file(var.ssh_public_key_path)
}

# ─────────────────────────────────────────────
# SECURITY GROUPS
# ─────────────────────────────────────────────

resource "openstack_networking_secgroup_v2" "target_sg" {
  name        = "scp-target-sg"
  description = "Target subnet - open internally, red team access allowed"
}

# Allow all traffic within 10.10.10.0/24
resource "openstack_networking_secgroup_rule_v2" "target_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.10.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.target_sg.id
}

# Allow all traffic from red team subnet
resource "openstack_networking_secgroup_rule_v2" "target_from_red" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.10.100.0/24"
  security_group_id = openstack_networking_secgroup_v2.target_sg.id
}

# Allow egress
resource "openstack_networking_secgroup_rule_v2" "target_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.target_sg.id
}

resource "openstack_networking_secgroup_v2" "red_sg" {
  name        = "scp-red-sg"
  description = "Red team subnet"
}

resource "openstack_networking_secgroup_rule_v2" "red_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.10.100.0/24"
  security_group_id = openstack_networking_secgroup_v2.red_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "red_from_target" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "10.10.10.0/24"
  security_group_id = openstack_networking_secgroup_v2.red_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "red_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.red_sg.id
}

# SSH from anywhere for management (restrict to your IP in prod)
resource "openstack_networking_secgroup_rule_v2" "target_ssh_mgmt" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.target_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "red_ssh_mgmt" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.red_sg.id
}

# WinRM for Ansible on Windows (target subnet)
resource "openstack_networking_secgroup_rule_v2" "target_winrm" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5985
  port_range_max    = 5986
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.target_sg.id
}
