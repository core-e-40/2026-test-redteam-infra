# SCP Foundation Cyber Range — Infrastructure as Code
# Terraform + Ansible | OpenStack | Red/Blue Team Lab

## Architecture Overview

```
10.10.10.0/24 — TARGET + BLUE TEAM SUBNET
┌─────────────────────────────────────────────────────────┐
│  SERVICE MACHINES (targets)                             │
│  10.10.10.21  SCP-DC-01       Windows Server 2022 (AD) │
│  10.10.10.22  SCP-SMB-01      Windows Server 2019      │
│  10.10.10.23  SCP-SMTP-01     Windows Server 2019      │
│  10.10.10.101 SCP-APACHE-01   Debian 13                │
│  10.10.10.102 SCP-DATABASE-01 Debian 13                │
│  10.10.10.103 SCP-OPENSSH-01  Rocky Linux 10           │
│  10.10.10.104 SCP-OPENVPN-01  Rocky Linux 10           │
│                                                         │
│  BLUE TEAM WORKSTATIONS                                 │
│  10.10.10.31  SCP-BT-WIN-01   Windows Server 2019 (AD) │
│  10.10.10.32  SCP-BT-WIN-02   Windows Server 2019 (AD) │
│  10.10.10.41  SCP-BT-LIN-01   Ubuntu (no AD)           │
│  10.10.10.42  SCP-BT-LIN-02   Ubuntu (no AD)           │
└─────────────────────────────────────────────────────────┘

10.10.100.0/24 — RED TEAM SUBNET
┌─────────────────────────────────────────────────────────┐
│  10.10.100.11 SCP-RED-01  Kali Linux                   │
│  10.10.100.12 SCP-RED-02  Kali Linux                   │
│  10.10.100.13 SCP-RED-03  Kali Linux                   │
│  10.10.100.14 SCP-RED-04  Kali Linux                   │
└─────────────────────────────────────────────────────────┘

Both subnets share a router — full bidirectional reachability.
AD domain: scp.local | DC DNS: 10.10.10.21
```

---

## Prerequisites

### On your workstation:
- Terraform >= 1.5
- Ansible >= 2.14
- Python 3.x with `pywinrm` installed: `pip3 install pywinrm`
- OpenStack credentials configured (see Step 1)

### In OpenStack (do these before anything else):
- Upload OS images to Glance (Windows Server 2022/2019, Debian 13, Rocky Linux 10, Kali, Ubuntu)
- Confirm your external network name: `openstack network list --external`
- Confirm available flavors: `openstack flavor list`

---

## Step-by-Step Deployment

### Step 1 — Configure OpenStack credentials

**Option A — clouds.yaml (recommended)**
```bash
mkdir -p ~/.config/openstack
cat > ~/.config/openstack/clouds.yaml << EOF
clouds:
  mycloud:
    auth:
      auth_url: https://YOUR-OPENSTACK-URL:5000/v3
      username: your-username
      password: your-password
      project_name: your-project
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
EOF
```

**Option B — environment variables**
```bash
export OS_AUTH_URL=https://YOUR-OPENSTACK-URL:5000/v3
export OS_USERNAME=your-username
export OS_PASSWORD=your-password
export OS_PROJECT_NAME=your-project
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
```

---

### Step 2 — Generate SSH keypair (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

For the scoring SSH key (grey team key):
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/greyteam_scoring -N ""
# The .pub goes to the OpenSSH server's authorized_keys (handled by Ansible)
# Give the private key to your grey team judge
```

---

### Step 3 — Configure Terraform variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars   # Fill in your image names and flavor names
```

---

### Step 4 — Deploy infrastructure with Terraform

```bash
cd terraform/
terraform init
terraform plan          # Review what will be created
terraform apply         # Type 'yes' to confirm
```

This creates all VMs, networks, router, security groups with the correct IPs.

---

### Step 5 — Generate Ansible inventory

```bash
cd ansible/
chmod +x gen_inventory.sh
./gen_inventory.sh
# Creates inventory/hosts.ini from the fixed IPs
```

---

### Step 6 — Install Ansible Galaxy collections

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
pip3 install pywinrm   # WinRM for Windows hosts
```

---

### Step 7 — Test connectivity

```bash
# Test Linux hosts
ansible all_linux -i inventory/hosts.ini -m ping

# Test Windows hosts (WinRM)
ansible all_windows -i inventory/hosts.ini -m win_ping
```

If Windows WinRM fails, see Troubleshooting section below.

---

### Step 8 — Run the full deployment

```bash
cd ansible/

# Full deployment (all stages in order)
ansible-playbook -i inventory/hosts.ini site.yml

# Or run stage by stage (recommended first time):
ansible-playbook -i inventory/hosts.ini site.yml --tags stage1   # DC first
ansible-playbook -i inventory/hosts.ini site.yml --tags stage2   # Linux services
ansible-playbook -i inventory/hosts.ini site.yml --tags stage3   # Windows services
ansible-playbook -i inventory/hosts.ini site.yml --tags stage4   # Workstations
ansible-playbook -i inventory/hosts.ini site.yml --tags stage5   # Red team
```

---

### Step 9 — Tear down after competition

```bash
cd terraform/
terraform destroy   # Nukes everything cleanly
```

---

## Credentials Reference

### AD Domain: scp.local

| Username   | Password          | Role                        |
|------------|-------------------|-----------------------------|
| sjohnson   | UwU?OwO!67        | Domain Admin (given to teams)|
| manderson  | Nuhuh!Whoisyou2   | Standard user               |
| ecarter    | bananaMan?#4      | Standard user               |
| dlee       | HushPuppy*3       | Standard user               |

### Linux (all machines)

| Username   | Password          | Role       |
|------------|-------------------|------------|
| cyberrange | Cyberrange123!    | Local admin|

---

## Hidden Accounts — FOR GREY/RED TEAM EYES ONLY

These accounts are planted for your red team to find and harvest.
Share with your team leads for scoring verification.

### Hidden AD Accounts

| Username   | Password          | Type         | Description              |
|------------|-------------------|--------------|--------------------------|
| rsinclair  | F0undation#77     | Standard     | Archivist, Records Div   |
| nvoss      | Cont@inment!9     | Standard     | Field Agent, Site-19     |
| jholloway  | Keter$ecure1      | Standard     | Researcher, Anomalous Mat|
| vcrane     | Eur1s@Admin!      | Domain Admin | O5 Council Clearance 5   |
| pmehta     | 05M3hta@Adm1n    | Domain Admin | O5 Council Clearance 5   |

### Hidden Linux Local Admins (target subnet only)

| Host            | Username       | Password         | Type        |
|-----------------|----------------|------------------|-------------|
| SCP-APACHE-01   | sysadmin       | Ap@che$ite!99    | Local admin |
| SCP-DATABASE-01 | dbroot         | MySQLr00t!DB     | Local admin |
| SCP-BT-LIN-01   | marcus.hollins | BlueTe@m!2024    | Local admin |
| SCP-BT-LIN-02   | rina.okafor    | R1n@0kafor$99    | Local admin |

### Standard Harvest Users (all Linux machines)

| Username          | Password          |
|-------------------|-------------------|
| walter.bishop     | Fr1nge#Science1   |
| olivia.dunham     | Cortex!Agent77    |
| peter.bishop      | Alt3rnat3Univ3rs3 |
| astrid.farnsworth | Lab@ssist@nt2024  |

### Per-Machine Linux Users

| Host            | Username      | Password         |
|-----------------|---------------|------------------|
| SCP-OPENSSH-01  | leon.kennedy  | Raccoon!City97   |
| SCP-OPENSSH-01  | claire.redfield | Ch1rs@RE2!!    |
| SCP-OPENVPN-01  | ada.wong      | Umb3lla!Sp00n   |
| SCP-BT-LIN-01   | jake.torres   | C0mpeti!tion1   |
| SCP-BT-LIN-02   | mia.chen      | N3twork$Blue!   |

---

## Troubleshooting

### WinRM connection refused
Windows images in OpenStack sometimes need a minute for WinRM to come up after boot.
Wait 2-3 minutes then retry. If still failing:
```bash
# Test WinRM manually
curl -v http://10.10.10.21:5985/wsman
```
Check the cloud-init log in the OpenStack console to see if windows_init.ps1 ran.

### Domain join fails (SMB/SMTP/Workstations)
The DC must be fully up and AD DS running before stage3/stage4.
Check from the DC:
```powershell
Get-Service ADWS, DNS, Netlogon | Select Name, Status
```

### Linux SSH connection refused
Check the OpenStack security group allows TCP 22 from your management IP.
Also verify the cloud image uses the `cyberrange` user — some images default to `debian`, `rocky`, or `ubuntu`.
Override per-host in inventory if needed:
```ini
SCP-APACHE-01 ansible_host=10.10.10.101 ansible_user=debian
```

### Image names not found by Terraform
```bash
openstack image list   # Get exact names as they appear in Glance
```
Update `terraform.tfvars` to match exactly.

---

## Project Structure

```
scp-lab/
├── terraform/
│   ├── main.tf               # Networks, router, security groups
│   ├── instances.tf          # All VM definitions
│   ├── variables.tf          # Variable declarations
│   ├── outputs.tf            # IP outputs
│   ├── terraform.tfvars.example
│   └── userdata/
│       └── windows_init.ps1  # WinRM bootstrap for Windows
│
└── ansible/
    ├── site.yml              # Master playbook (run this)
    ├── ansible.cfg
    ├── requirements.yml      # Galaxy collections
    ├── gen_inventory.sh      # Generates hosts.ini
    ├── inventory/
    │   └── hosts.ini         # Generated by gen_inventory.sh
    ├── group_vars/
    │   ├── all_windows.yml   # WinRM + domain vars
    │   └── all_linux.yml     # SSH + sudo vars
    └── roles/
        ├── common/           # Base Linux config + users
        ├── dc/               # AD DS, DNS, all AD users
        ├── smb/              # File server, SMBv1
        ├── smtp/             # hMailServer, email accounts
        ├── apache/           # Apache2, PHP, SQLi login page
        ├── database/         # MySQL, seeded users table
        ├── openssh/          # OpenSSH, SCP073/343 scoring
        ├── openvpn/          # OpenVPN server, PKI
        ├── linux-workstation/# BT Linux workstations
        ├── windows-workstation/ # BT Windows workstations
        └── redteam/          # Kali, tools, hosts file
```
