# Install the Active Directory Domain Services role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart

# Wait for the server to restart

# Promote the server as a domain controller
$Password = "Veremes66" | ConvertTo-SecureString -AsPlainText -Force
$SafeModeAdministratorPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

Install-ADDSForest `
  -DomainName "mondomaine.local" `
  -DomainNetBiosName "MONDOMAINE" `
  -ForestMode WinThreshold `
  -DomainMode WinThreshold `
  -InstallDns `
  -NoRebootOnCompletion `
  -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
  -DatabasePath "C:\Windows\NTDS" `
  -LogPath "C:\Windows\NTDS" `
  -SysvolPath "C:\Windows\SYSVOL" `
  -Force

# Configure DNS server settings
$NIC = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$DNSSettings = @{
  InterfaceIndex = $NIC.InterfaceIndex
  ServerAddresses = @("127.0.0.1")
}

Set-DnsClientServerAddress @DNSSettings

# Configure DNS server as the preferred DNS server
Set-DnsClientServerAddress -InterfaceIndex $NIC.InterfaceIndex -ServerAddresses @("127.0.0.1")

Write-Host "Domain Controller installation completed."

# Restart the server
Restart-Computer -Force
