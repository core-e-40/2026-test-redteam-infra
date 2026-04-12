<powershell>
# Set hostname
Rename-Computer -NewName "${hostname}" -Force

# Enable WinRM for Ansible
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'

# Open firewall
netsh advfirewall firewall add rule name="WinRM HTTP" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in localport=5986 action=allow

# Set a local admin password for Ansible bootstrap
# CHANGE THIS — it's just for initial Ansible bootstrap, you'll rotate via playbook
$adminPass = ConvertTo-SecureString "BootstrapPass123!" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $adminPass

# Allow Administrator login
Set-LocalUser -Name "Administrator" -PasswordNeverExpires $true
Enable-LocalUser -Name "Administrator"

Write-Output "WinRM bootstrap complete on ${hostname}"
</powershell>
