function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name -VirtualNetworkName $VNet_name -SubnetName $subnet_name `
    -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest" 

    #Pour WS2016 : ImageName = MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest
    #Pour WS2019 : ImageName = MicrosoftWindowsServer:WindowsServer:2019-Datacenter-Core:latest

}
