# ─────────────────────────────────────────────
# TARGET SUBNET — SERVICE MACHINES (10.10.10.x)
# ─────────────────────────────────────────────

locals {
  target_windows_instances = {
    "SCP-DC-01" = {
      ip     = "10.10.10.21"
      flavor = var.windows_flavor
      image  = var.windows_2022_image
    }
    "SCP-SMB-01" = {
      ip     = "10.10.10.22"
      flavor = var.windows_flavor
      image  = var.windows_2019_image
    }
    "SCP-SMTP-01" = {
      ip     = "10.10.10.23"
      flavor = var.windows_flavor
      image  = var.windows_2019_image
    }
  }

  target_linux_instances = {
    "SCP-APACHE-01" = {
      ip     = "10.10.10.101"
      flavor = var.linux_flavor
      image  = var.debian13_image
    }
    "SCP-DATABASE-01" = {
      ip     = "10.10.10.102"
      flavor = var.linux_flavor
      image  = var.debian13_image
    }
    "SCP-OPENSSH-01" = {
      ip     = "10.10.10.103"
      flavor = var.linux_flavor
      image  = var.rocky10_image
    }
    "SCP-OPENVPN-01" = {
      ip     = "10.10.10.104"
      flavor = var.linux_flavor
      image  = var.rocky10_image
    }
  }

  # Blue team workstations — 2 Windows, 2 Linux
  blueteam_windows_instances = {
    "SCP-BT-WIN-01" = {
      ip     = "10.10.10.31"
      flavor = var.workstation_flavor
      image  = var.windows_2019_image
    }
    "SCP-BT-WIN-02" = {
      ip     = "10.10.10.32"
      flavor = var.workstation_flavor
      image  = var.windows_2019_image
    }
  }

  blueteam_linux_instances = {
    "SCP-BT-LIN-01" = {
      ip     = "10.10.10.41"
      flavor = var.workstation_flavor
      image  = var.ubuntu_image
    }
    "SCP-BT-LIN-02" = {
      ip     = "10.10.10.42"
      flavor = var.workstation_flavor
      image  = var.ubuntu_image
    }
  }

  # Red team machines on 10.10.100.x
  red_instances = {
    "SCP-RED-01" = {
      ip     = "10.10.100.11"
      flavor = var.red_flavor
      image  = var.kali_image
    }
    "SCP-RED-02" = {
      ip     = "10.10.100.12"
      flavor = var.red_flavor
      image  = var.kali_image
    }
    "SCP-RED-03" = {
      ip     = "10.10.100.13"
      flavor = var.red_flavor
      image  = var.kali_image
    }
    "SCP-RED-04" = {
      ip     = "10.10.100.14"
      flavor = var.red_flavor
      image  = var.kali_image
    }
  }
}

# ── Target Windows
resource "openstack_compute_instance_v2" "target_windows" {
  for_each        = local.target_windows_instances
  name            = each.key
  flavor_name     = each.value.flavor
  image_name      = each.value.image
  key_pair        = "scp-lab-key-new"
  security_groups = [openstack_networking_secgroup_v2.target_sg.name]

  network {
    name        = openstack_networking_network_v2.target_net.name
    fixed_ip_v4 = each.value.ip
  }

  user_data = templatefile("${path.module}/userdata/windows_init.ps1", {
    hostname = each.key
  })

  metadata = {
    role   = "target-windows"
    subnet = "target"
  }
}

# ── Target Linux
resource "openstack_compute_instance_v2" "target_linux" {
  for_each        = local.target_linux_instances
  name            = each.key
  flavor_name     = each.value.flavor
  image_name      = each.value.image
  key_pair        = "scp-lab-key-new"
  security_groups = [openstack_networking_secgroup_v2.target_sg.name]

  network {
    name        = openstack_networking_network_v2.target_net.name
    fixed_ip_v4 = each.value.ip
  }

  metadata = {
    role   = "target-linux"
    subnet = "target"
  }
}

# ── Blue Team Windows Workstations
resource "openstack_compute_instance_v2" "bt_windows" {
  for_each        = local.blueteam_windows_instances
  name            = each.key
  flavor_name     = each.value.flavor
  image_name      = each.value.image
  key_pair        = "scp-lab-key-new"
  security_groups = [openstack_networking_secgroup_v2.target_sg.name]

  network {
    name        = openstack_networking_network_v2.target_net.name
    fixed_ip_v4 = each.value.ip
  }

  user_data = templatefile("${path.module}/userdata/windows_init.ps1", {
    hostname = each.key
  })

  metadata = {
    role   = "blueteam-windows"
    subnet = "target"
  }
}

# ── Blue Team Linux Workstations
resource "openstack_compute_instance_v2" "bt_linux" {
  for_each        = local.blueteam_linux_instances
  name            = each.key
  flavor_name     = each.value.flavor
  image_name      = each.value.image
  key_pair        = "scp-lab-key-new"
  security_groups = [openstack_networking_secgroup_v2.target_sg.name]

  network {
    name        = openstack_networking_network_v2.target_net.name
    fixed_ip_v4 = each.value.ip
  }

  metadata = {
    role   = "blueteam-linux"
    subnet = "target"
  }
}

# ── Red Team Machines
resource "openstack_compute_instance_v2" "red_machines" {
  for_each        = local.red_instances
  name            = each.key
  flavor_name     = each.value.flavor
  image_name      = each.value.image
  key_pair        = "scp-lab-key-new"
  security_groups = [openstack_networking_secgroup_v2.red_sg.name]

  network {
    name        = openstack_networking_network_v2.red_net.name
    fixed_ip_v4 = each.value.ip
  }

  metadata = {
    role   = "redteam"
    subnet = "red"
  }
}
