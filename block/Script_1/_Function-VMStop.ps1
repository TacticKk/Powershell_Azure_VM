function VM_stop {
    param ([string]$vm_name,[string]$RG_name)

    #Stop les VMs du RG
    $RG_name = Read "Nom du RG "
    $vm_name = (Get-AzVM -ResourceGroupName $RG_name).Name
    Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
}
