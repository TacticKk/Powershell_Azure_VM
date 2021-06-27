# Projet Powershell

Ce projet est constitué de deux scripts :

1/ Déploiements de VMs Azure

2/ Installation d'un AD + DNS et création d'utilisateurs

## 1/ Déploiements de machines virtuelles sur Azure

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

### B - Fonction VM_creation

La créationd de fonction permet de faciliter la création de VM et d'éviter de réécrire de nombreuses choses.
```powershell
function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    $Username = Read "Nom pour les comptes de base des VMs ?"
    $Password = 'Password de base pour les VMs ?' #Trouver le moyen de cacher le texte
    $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $cred = New-Object -TypeName PSCredential -ArgumentList ($Username, $Password)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name ` 
    -VirtualNetworkName $VNet_name -SubnetName $subnet_name -Credential $cred

    #Pas de possibilité de setup le "Standard_B1s" de base, donc on update à la création de la VM
    Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
    $vm = Get-AzVM -ResourceGroupName $RG_name -VMName $vm_name
    $vm.HardwareProfile.VmSize = "Standard_B1s"
    Update-AzVM -VM $vm -ResourceGroupName $RG_name
    Start-AzVM -ResourceGroupName $RG_name  -Name $vm.name

    # Ajout d'une règle entrante RDP au NSG afin de pouvoir prendre la main sur la machine

    $rules = (Get-AzNetworkSecurityGroup).SecurityRules.Name

    foreach ($rule in $rules){
    
    if ($rules -eq "AllowRDPPort"){
        Write-Host "La règle existe déjà"
        break
    }
    else {
        $nsg = Get-AzNetworkSecurityGroup -Name $NSG_name -ResourceGroupName $RG_name
        #Add the inbound security rule.
        $nsg | Add-AzNetworkSecurityRuleConfig -Name "AllowRDPPort" -Description "Allow RDP port" -Access Allow `
        -Protocol * -Direction Inbound -Priority 3901 -SourceAddressPrefix "*" -SourcePortRange * `
        -DestinationAddressPrefix * -DestinationPortRange 3389
        # Update the NSG.
        $nsg | Set-AzNetworkSecurityGroup}
        break

}
```
Dans cette fonction, nous avons mis en paramètres les informations dont nous avons besoin, afin de pouvoir vraiment simplifier la démarche.

De plus, nous ne pouvons (contrairement au CLI Azure) fournir de base la "VM Size" que l'on souhaite. Ainsi, le script va en fournir une par défaut. C'est pourquoi nous faisons une update de la machine afin de passer dans la "VM Size" voulue.

Enfin, nous avons à la fin de la fonction, une boucle foreach qui va vérifier si la règle pour le RDP est déjà existante ou non dans notre NSG et l'ajouter si ce n'est pas le cas.

### C - Menu des fonctions

Nous avons mis en place un menu où l'utilisateur va choisir ce qu'il fait, selon ses besoins.

```powershell
    Write-Host "============= Pick the Server environment=============="
    Write-Host "`ta. [1] pour déployer des VMs en précisant chaque paramètre"
    Write-Host "`tb. [2] pour déployer un nombre précis de VMs avec les mêmes paramètres"
    Write-Host "`tc. [3] pour déployer des VMs depuis un Excel"
    Write-Host "`td. [4] to Quit'"
    Write-Host "========================================================"
    
    $choice = Read-Host "`nEnter Choice"
```

### D - Appel de la fonction

Etant donné que nous avons plusieurs possibilités dans notre script, l'appel va se faire de la même façon en écrivant "VM_Creation" qui est le nom de la fonction. Cependant, les informations données et/ou attendues ne sont pas les mêmes.

NB : Nous avons créé un alias au début du script de "Read-Host" vers "Read" qui nous permet donc faciliter l'écriture et la lecture de ce dernier.

## Principales sources
[Documentation Microsoft : "Azure Windows - Quick create Powershell"](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell) 

[Documentation Microsoft : "Azure Virtual Network - Quick create Powershell"](https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-powershell)

[Documentation Microsoft : "Azure - Network Security Group"](https://docs.microsoft.com/en-us/powershell/module/az.network/new-aznetworksecuritygroup?view=azps-6.1.0)

[Documentation Microsoft : "Azure Virtual Network - B Series"](https://docs.microsoft.com/fr-fr/azure/virtual-machines/sizes-b-series-burstables)

[Documentation UKCloud : "Azure - How to create VM"](https://docs.ukcloud.com/articles/azure/azs-how-create-vm-ps.html?tabs=tabid-1)
