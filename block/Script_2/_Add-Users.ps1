============= add user ============

Import-Module ActiveDirectory

$users_csv = Import-Csv "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\MOCK_DATA.csv" -Delimiter ";"
$count = ($users_csv).count

# Fournir l'UPN
$UPN = "Powershell.local"

foreach ($User in $users_csv) {

    $username = $User.username
    $password = $User.password
    $firstname = $User.prenom
    $lastname = $User.nom
    $OU = $User.OU 
    $email = $User.email

    $i = 0

    # Check si l'user existe déjà dans l'AD
    if (Get-ADUser -F { SamAccountName -eq $username }) {

        $i++
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

    $count -= $i
    Write-Output "The number of user qui ont été créé sont de : $i"
}

Read-Host -Prompt "Quiter..."
