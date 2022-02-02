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
    subnet_id                   = module.networking.dc_subnet.id
    private_ip                  = "10.250.10.5"
    vpc_security_group_ids      = [module.networking.dc_sg.id]
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

$dsrmPassword = "${var.dsrm_password}" | ConvertTo-SecureString -AsPlainText -Force

$params = @{
    domainName                          = "contoso.local"
    domainNetBIOSName                   = "CONTOSO"
    safeModeAdministratorPassword       = $dsrmPassword
    domainMode                          = "Win2012R2"
    forestMode                          = "Win2012R2"
    installDns                          = $true
    createDNSDelegation                 = $false
    databasePath                        = "C:\Windows\NTDS"
    logPath                             = "C:\Windows\NTDS"
    sysvolPath                          = "C:\Windows\SYSVOL"
}
Install-ADDSForest @params -confirm:$false

Stop-Transcript
</powershell>
EOF

    tags = {
        Name = var.namespace
    }
}