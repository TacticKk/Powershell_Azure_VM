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
        $nsg | Set-AzNetworkSecurityGroup
        break
        }
    }
}
