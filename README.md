# Projet Powershell

Ce projet est constitué de deux scripts :

1/ Déploiements de VMs Azure

2/ Installation d'un AD + DNS et création d'utilisateurs

## 1/ Déploiements de machines virtuelles sur Azure

NB : Nous avons créé un alias au début du script de "Read-Host" vers "Read" qui nous permet donc faciliter l'écriture et la lecture de ce dernier.

### A - Pré-requis

Pour pouvoir exécuter le script, il faut installer le module Azure.

```powershell
Install-Module Azure -AllowClobber
Import-Module Azure
```

Ensuite, il faut se connecter à son compte Azure sur lequel nous souhaitons faire nos manipulations.

```powershell
Connect-AzAccount
```

### B - Fonctions

La création de fonctions permet de faciliter la lisibilité du script et de pouvoir appeler ces dernières au besoin sans réécrire tout le contenu. Dans les fonctions, nous avons mis en paramètres les informations dont nous avons besoin, afin de pouvoir vraiment simplifier la démarche.

Voici nos différentes fonctions :

1/ Fonction de création de la VM
```powershell
function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name -VirtualNetworkName `
    $VNet_name -SubnetName $subnet_name -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest" 

    #Pour WS2016 : ImageName = MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest
    #Pour WS2019 : ImageName = MicrosoftWindowsServer:WindowsServer:2019-Datacenter-Core:latest

}
```

2/ Fonction d'update de la VM
```powershell
function VM_update {
    param ([string]$vm_name,[string]$RG_name)

    #Update le "Standard_B1s" a la creation de la VM
    Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
    $vm = Get-AzVM -ResourceGroupName $RG_name -VMName $vm_name
    $vm.HardwareProfile.VmSize = "Standard_B1s"
    Update-AzVM -VM $vm -ResourceGroupName $RG_name
    Start-AzVM -ResourceGroupName $RG_name  -Name $vm.name
}
```

3/ Fonction d'arrêt de la VM
```powershell
function VM_stop {
    param ([string]$RG_name)

    #Stop les VMs du RG
    $RG_name = Read "Nom du RG "
    #$vm_name = (Get-AzVM -ResourceGroupName $RG_name).Name
    #Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
    Get-AzVM -ResourceGroupName $RG_name | Select-Object Name | ForEach-Object { Stop-AzVM -ResourceGroupName $RG_Name `
    -Name $_.Name -Force} 
}
```

4/ Fonction de suppression de la VM
```powershell
function VM_remove {
    param ([string]$RG_name)
    
    Get-AzVM -ResourceGroupName $RG_name | Select-Object Name | ForEach-Object { Remove-AzVM -ResourceGroupName $RG_Name `
    -Name $_.Name -Force} 
}
```

5/ Fonction de création du fichier RDP de la VM
```powershell
function VM_GetRDP {
    param ([string]$vm_name,[string]$RG_name)

    ##### fonction qui permet de créer le fichier RDP d'une VM

    ## test si le dossier de stockage "RDP" existe. Si oui, il passe, si non, il le créer.
    $test_path_directory = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP"

    if ($test_path_directory -eq $true){
        Write-Output "Le dossier RDP existe déjà"
    }
    else{
        New-Item "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\" `
        -itemtype directory -Name "RDP"
    }

## test si le fichier "$vm_name.rdp" existe. Si oui, il passe, si non, il le créer.
    $test_file_RDP = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"

    if ($test_file_RDP -eq $true){
        Write-Output "Le fichier RDP existe déjà"
    }
    else{
        Get-AzRemoteDesktopFile -ResourceGroupName $RG_name -Name $vm_name -LocalPath "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"
        Write-Output "Le fichier RDP a bien été créé."
    }
}
```

6/ Fonction de suppression du fichier RDP de la VM
```powershell
function VM_RemoveRDP {
    param ([string]$vm_name)

    ##### fonction qui permet de supprimer le fichier RDP d'une VM

    ## test si le fichier "RDP" existe. Si oui, il le supprime, si non, wtf.
    $test_file_RDP = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"

    if ($test_file_RDP -eq $true){
        Remove-Item "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\$vm_name.rdp" `
        -itemtype directory -Name "RDP"
    }
    else{
        Write-Output "Le fichier rdp est inexistant."
    }
}
```

7/ Fonction de création de la règle RDP
```powershell
function NSG_rules {
    
    #Ajout d'une regle entrante RDP au NSG afin de pouvoir prendre la main sur la machine

    $get_nsg_rules = (Get-AzNetworkSecurityGroup).SecurityRules
    $get_rules_ports = $get_nsg_rules.DestinationPortRange

    foreach ($rule in $get_rules_ports){
    
        if ($get_rules_ports -eq "3389"){
            Write-Output " === Regle Firewall === "
            Write-Output "La regle RDP existe deja."
            break
        }
        else {
            $get_nsg_rules = Get-AzNetworkSecurityGroup -Name $NSG_name -ResourceGroupName $RG_name
            #Add the inbound security rule.
            $get_nsg_rules | Add-AzNetworkSecurityRuleConfig -Name "AllowRDPPort" -Description "Allow RDP port" -Access Allow `
            -Protocol * -Direction Inbound -Priority 3901 -SourceAddressPrefix "*" -SourcePortRange * `
            -DestinationAddressPrefix * -DestinationPortRange 3389
            # Update the NSG.
            $get_nsg_rules | Set-AzNetworkSecurityGroup
            Write-Output "La regle RDP a ete cree."
            break
        }
    }
}
```

### C - Menu

Nous avons mis en place un menu où l'utilisateur va choisir ce qu'il fait, selon ses besoins.

```powershell
############################################################# MENU #############################################################

Write-Output "============= Choose =============="
Write-Output "`ta. [1] Creer des VMs en precisant chaque parametre"
Write-Output "`tb. [2] Creer un nombre precis de VMs avec les memes parametres"
Write-Output "`tc. [3] Creer des VMs depuis un CSV"
Write-Output "`r" #saute une ligne
Write-Output "`td. [4] Stopper les VMs d'un RG"
Write-Output "`te. [5] Supprimer les VMs d'un RG"
Write-Output "`r" #saute une ligne
Write-Output "`tf. [6] Telecharger un fichier RDP d'une VM"
Write-Output "`r" #saute une ligne
Write-Output "`tg. [7] Quitter"
Write-Output "========================================================"
Write-Output "`r" #saute une ligne
$menu_choice = Read "Entrez votre choix"
```

### D - Switch

Etant donné que nous avons plusieurs possibilités dans notre script, l'appel d'une ou de fontion(s) va se faire en fonction de la réponse de l'utilisateur. Pour cela, nous avons recours à un "switch".

```powershell
############################################################# SWITCH ###########################################################
switch ($menu_choice) {

    #Deploiement de VMs une par une avec des parametres differents
    '1'{ 
        $answer = "oui"
        
        while ($answer -eq "oui") {
            VM_creation -vm_name ($vm_name = Read "Nom de la VM  ") -RG_name ($RG_name = Read "Nom du RG  ") -Location_name ($location_name = Read "Nom de la location  ") `
            -VNet_name ($VNet_name = Read "Nom du VNet  ") -subnet_name ($subnet_name = Read "Nom du subnet  ") -NSG_name ($NSG_name = Read "Nom du NSG  ")

            VM_update -vm_name $vm_name -RG_name $RG_name -Location_name $location_name -VNet_name $VNet_name -subnet_name $subnet_name -NSG_name $NSG_name

            VM_GetRDP -vm_name $vm_name -RG_name $RG_name
            
            $answer = Read "Voulez-vous creer une VM sur Azure ? "
        }

        NSG_rules
    }

    #Deploiement de VMs par nombre avec des memes parametres (en dur dans le script)
    '2'{
        $answer = Read "Combien de VMs voulez-vous creer sur Azure ? "
        $RG_name = Read "Nom du RG "
        $Location_name = Read "Nom de location "
        $Vnet_name = Read "Nom du VNet "
        $Subnet_name = Read "Nom du Subnet "
        $NSG_name = Read "Nom du NSG "

        $i = 1
        while ($i -le $answer) {
            $VM_name = Read "Nom de la VM $i"
            VM_creation -vm_name $VM_name -RG_name $RG_name -Location_name $Location_name -VNet_name $Vnet_name -subnet_name $Subnet_name -NSG_name $NSG_name

            VM_update -vm_name $VM_name -RG_name $RG_name -Location_name $Location_name -VNet_name $Vnet_name -subnet_name $Subnet_name -NSG_name $NSG_name

            VM_GetRDP -vm_name $vm_name -RG_name $RG_name
            $i++
        }

        NSG_rules
    }

    #Deploiement de VMs via CSV
    '3'{
        #$path = Read "Quel est le path du CSV ?"
        $VM_create_csv = Import-Csv "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\MOCK_DATAv2.csv" -Delimiter ","

        foreach ($elements in $VM_create_csv) {

            $VM_name = $elements.Name
            $RG_name = $elements.RG
            $Location_name = $elements.Location
            $Vnet_name = $elements.Vnet
            $Subnet_name = $elements.Subnet
            $NSG_name = $elements.NSG
        
            # Check si la vm existe deja dans le RG
            $Get_vm = (Get-AzVM -ResourceGroupName "RG_test").Name
        
            if ($Get_vm -eq $VM_name ) {
        
                Write-Output "Une VM avec le nom $VM_name existe deja dans le groupe de ressource $RG_name."
            }
            else {
                #Si la VM existe pas, il la creer
                VM_creation -vm_name $vm_name -RG_name $RG_name -Location_name $Location_name -VNet_name $Vnet_name -subnet_name $Subnet_name -NSG_name $NSG_name

                VM_update -vm_name $vm_name -RG_name $RG_name -Location_name $location_name -VNet_name $VNet_name -subnet_name $subnet_name -NSG_name $NSG_name

                VM_GetRDP -vm_name $vm_name -RG_name $RG_name
        
                Write-Output "La VM $VM_name a bien ete creee dans le groupe de ressource $RG_name." -ForegroundColor Cyan
            }
        }

        NSG_rules
    }

    #Stop les VMs
    '4'{
        VM_stop -RG_name (Read "Nom du RG  ")
    }

    #Remove les VMs
    '5'{
        VM_remove -RG_name ($RG_name = Read "Nom du RG  ")
        VM_RemoveRDP -vm_name $vm_name
    }

    #DL RDP
    '6'{
        VM_GetRDP -vm_name (Read "Nom de la VM") -RG_name (Read "Nom du RG")
    }

    #Stop le script
    '7'{return}
}
```

## 2/ Installation d'un Active Directory et DNS + création d'utilisateurs

### A - Pré-requis

Avant toute chose, nous avons fais les manipulations sur une VM Azure sous Windows Server 2019 Datacenter. Pour pouvoir exécuter la première partie du script, il n'y a doncpas besoin de module à installer. En revanche, pour la seconde partie, il faut installer le module suivant :

```powershell
Import-Module ActiveDirectory
```

### B - Installation de l'AD et du DNS (regroupé sous la feature ADDS)

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName "Powershell.local" -DomainNetBiosName "POWER" -InstallDns:$true `
-NoRebootOnCompletion:$true
```
### C - Configuration du DNS

Avec les deux lignes ci-dessous, nous allons faire de notre serveur, le serveur principal (de première zone) de notre domaine et rediriger les requêtes vers l'adresse IP 8.8.8.8 qui correpond aux serveurs DNS de Google.

```powershell
$vm_name = Read-Host "Nom de la VM souhaitée "

$get_VM_ipaddress = (Get-AzNetworkInterface -Name $vm_name -ResourceGroupName "RG_test").IpConfigurations.PrivateIpAddress
$get_VNet_ipaddress = (Get-AzVirtualNetwork).AddressSpace.AddressPrefixes

Add-DnsServerPrimaryZone -NetworkID $get_VNet_ipaddress -ZoneFile “$get_ipaddress.in-addr.arpa.dns”

Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru
```
Nous allons tester que notre serveur fonctionne bien avec la ligne de commande suivant :

```powershell
Test-DnsServer -IPAddress $get_VM_ipaddress -ZoneName "Powershell.local" #Vérif fonctionnement DNS
```
Si le résultat est un "Success" alors le serveur fonctionne.


### D - Création d'utilisateurs au sein de l'AD

Voici ci dessous le script permettant de créer les utilisateurs. Nous partons d'un fichier CSV, qui est importé avec la commande :

```powershell
# Store the data from NewUsersFinal.csv in the $ADUsers variable
$csv = Import-Csv C:\Users\antoine\Desktop\MOCK_DATA.csv -Delimiter ";"
```

Ensuite, nous definissons l'UPN du domaine ainsi que pour chaque élément du fichier CSV, les éléments nécessaire à la création du compte via une boucle foreach :

```powershell
# Define UPN
$UPN = "Powershell.local"

# Loop through each row containing user details in the CSV file
foreach ($User in $csv) {

    $username = $User.username
    $password = $User.password
    $firstname = $User.prenom
    $lastname = $User.nom
    $OU = $User.OU #This field refers to the OU the user account is to be created in
    $email = $User.email
```
Puis le script effectue une suppression des personnes déjà existantes dans l'AD en ayant comme base l'username de la personne, qui doit être unique. Dans le cas où l'username n'existe pas déjà, alors le compte est créé avec toutes les informations contenues dans le CSV.

```powershell
    # Check to see if the user already exists in AD
    if (Get-ADUser -F { SamAccountName -eq $username }) {
        
        # If user does exist, give a warning
        Write-Warning "Un compte avec l'username $username existe déjà dans l'AD."
    }
    else {

        # User does not exist then proceed to create the new user account
        # Account will be created in the OU provided by the $OU variable read from the CSV file
        New-ADUser -SamAccountName $username `
            -UserPrincipalName "$username@$UPN" `
            -Name "$firstname $lastname" `
            -GivenName $firstname `
            -Surname $lastname `
            -Enabled $True `
            -DisplayName "$lastname, $firstname" `
            -Path $OU `
            -EmailAddress $email `
            -AccountPassword (ConvertTo-secureString $password -AsPlainText -Force) `
            -ChangePasswordAtLogon $True

        # If user is created, show message.
        Write-Host "Le compte de l'utilisateur $username a été créé." -ForegroundColor Cyan
    }
}

Read-Host -Prompt "Quiter..."
```

## Principales sources

### Script 1 - Déploiements de machines virtuelles sur Azure
[Documentation Microsoft : "Azure Windows - Quick create Powershell"](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell) 

[Documentation Microsoft : "Azure Virtual Network - Quick create Powershell"](https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-powershell)

[Documentation Microsoft : "Azure - Network Security Group"](https://docs.microsoft.com/en-us/powershell/module/az.network/new-aznetworksecuritygroup?view=azps-6.1.0)

[Documentation Microsoft : "Azure Virtual Network - B Series"](https://docs.microsoft.com/fr-fr/azure/virtual-machines/sizes-b-series-burstables)

[Documentation Microsoft : "Azure Powershell - Get-AzRemoteDesktopFile"](https://docs.microsoft.com/en-us/powershell/module/az.compute/get-azremotedesktopfile?view=azps-6.2.0)

### Script 2 - Installation d'un Active Directory et DNS + création d'utilisateurs
[Documentation RDR-IT : "Powershell - How to create an AD"](https://rdr-it.com/en/create-an-active-directory-environment-in-powershell/)

[Documentation MalwareMily : "Powershell - How to create ADDS & DHCP"](https://malwaremily.medium.com/install-ad-ds-dns-and-dhcp-using-powershell-on-windows-server-2016-ac331e5988a7)

[Documentation Alitajran : "Powershell - How to create users from CSV"](https://www.alitajran.com/create-active-directory-users-from-csv-with-powershell/)

[Documentation TheITBros : "Powershell - How to create OU in AD"](https://theitbros.com/active-directory-organizational-unit-ou/)

[Website Mockaroo : "Tool - Random Data Generator"](https://www.mockaroo.com/)
