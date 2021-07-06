############################################################ NSG ###########################################################
#Ajout d'une règle entrante RDP au NSG afin de pouvoir prendre la main sur la machine

$get_nsg_rules = (Get-AzNetworkSecurityGroup).SecurityRules
$get_rules_ports = $get_nsg_rules.DestinationPortRange

foreach ($rule in $get_rules_ports){
    
    if ($get_rules_ports -eq "3389"){
        Write-Output " === Règle Firewall === "
        Write-Output "La règle RDP existe déjà."
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
        break
    }
}
