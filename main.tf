module "networking" {
    source  = "./modules/networking"
    namespace = var.namespace
}

resource "aws_key_pair" "dc_key" {
    key_name    = "${var.namespace}_key"
    public_key  = file(var.public_key_path)

    tags = {
        Name = var.namespace
    }
}

resource "aws_instance" "dc" {
    ami             = "ami-0a46adf18f8875ad6"
    instance_type   = "t3.medium"
    key_name        = aws_key_pair.dc_key.key_name
    associate_public_ip_address = true
    get_password_data           = true
    user_data                   = <<EOF
<powershell>
Start-Transcript
# install role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# set NLA
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

# set NTP
w32tm /config /manualpeerlist:169.254.169.123 /syncfromflags:manual /update

$params = @{
    domainName                          = "contoso.local"
    domainNetBIOSName                   = "CONTOSO"
    safeModeAdministratorPassword       = "${var.dsrm_password}"
    domainMode                          = "Win2012R2"
    forestMode                          = "Win2012R2"
    installDns                          = $true
    createDNSDelegation                 = $false
    databasePath                        = "C:\Windows\NTDS"
    logPath                             = "C:\Windows\NTDS"
    sysvolPath                          = "C:\Windows\SYSVOL"
}
Install-ADDSForest @params

Stop-Transcript
</powershell>
EOF
    
    network_interface {
        network_interface_id    = module.networking.dc_nic
        device_index            = 0
    }

    tags = {
        Name = var.namespace
    }
}