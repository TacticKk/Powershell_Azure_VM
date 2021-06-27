Set-Alias -Name Read -Value Read-Host
function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    $Username = Read "Nom pour les comptes de base des VMs ?"
    $Password = 'Password de base pour les VMs ?' #Trouver le moyen de cacher le texte
    $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $cred = New-Object -TypeName PSCredential -ArgumentList ($Username, $Password)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name -VirtualNetworkName $VNet_name -SubnetName $subnet_name `
    -Credential $cred

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
}

#############################################################

Write-Host "============= Pick the Server environment=============="
Write-Host "`ta. [1] pour déployer des VMs en précisant chaque paramètre"
Write-Host "`tb. [2] pour déployer un nombre précis de VMs avec les mêmes paramètres"
Write-Host "`tc. [3] pour déployer des VMs depuis un Excel"
Write-Host "`td. [4] to Quit'"
Write-Host "========================================================"
$choice = Read-Host "`nEnter Choice"

switch ($choice) {

#Déploiement de VMs une par une avec des paramètres différents
    '1'{ 
        $answer = Read "Do you want to create une VM sur Azure ? "
        
        while ($answer -eq "yes") {
            VM_creation -vm_name (Read "Nom de la VM  ") -RG_name (Read "Nom du RG  ") -Location_name (Read "Nom de la location  ") -VNet_name (Read "Nom du VNet  ") `
            -subnet_name (Read "Nom du subnet  ") -NSG_name (Read "Nom du NSG  ") 
            
            $answer = Read "Do you want to create une VM sur Azure ? "
        }
    }

#Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '2'{
        $answer = Read "How much VM do want to create sur Azure ? "
        $i = 1

        while ($i -ne $answer) {
            VM_creation -vm_name (Read "Nom de la VM  ") -RG_name "RG_test" -Location_name "francecentral" -VNet_name "VNet_test" -subnet_name "frontendSubnet" -NSG_name "NSG_test" 
            
            $i++
        }
    }

#Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '3'{
        Write-Host "You have selected a Dev Environment"
    }

    '4'{Return}
}