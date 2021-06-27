#Ajout d'une règle entrante RDP au NSG afin de pouvoir prendre la main sur la machine

$nsg = (Get-AzNetworkSecurityGroup).SecurityRules
$rules = $nsg.DestinationPortRange

foreach ($rule in $rules){
    
    if ($rules -eq "3389"){
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
