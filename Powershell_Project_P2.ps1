=========== ADDS ===============
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName "Powershell.local" -DomainNetBiosName "POWER" -InstallDns:$true -NoRebootOnCompletion:$true

(Restore Mode Password : Pa$$w0rd)

========== DNS =============

Add-DnsServerPrimaryZone -NetworkID 10.0.1.0/24 -ZoneFile “10.0.1.4.in-addr.arpa.dns”

Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru

Test-DnsServer -IPAddress 10.0.1.4 -ZoneName "Powershell.local" #Vérif fonctionnement DNS

============= add user ============

Import-Module ActiveDirectory

$csv = Import-Csv C:\Users\antoine\Desktop\MOCK_DATA.csv -Delimiter ";"

# Fournir l'UPN
$UPN = "Powershell.local"

foreach ($User in $csv) {

    $username = $User.username
    $password = $User.password
    $firstname = $User.prenom
    $lastname = $User.nom
    $OU = $User.OU 
    $email = $User.email

    # Check si l'user existe déjà dans l'AD
    if (Get-ADUser -F { SamAccountName -eq $username }) {

        Write-Warning "Un compte avec l'username $username existe déjà dans l'AD."
    }
    else {
        #Si l'user existe pas, il créer le compte
        New-ADUser -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Enabled $True `
            -DisplayName "$lastname, $firstname" `
            -Path $OU `
            -EmailAddress $email `
            -AccountPassword (ConvertTo-secureString $password -AsPlainText -Force) -ChangePasswordAtLogon $True

        Write-Host "Le compte de l'utilisateur $username a été créé." -ForegroundColor Cyan
    }
}

Read-Host -Prompt "Quiter..."