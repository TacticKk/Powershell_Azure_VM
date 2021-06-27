Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
$vm = Get-AzVM -ResourceGroupName $RG_name -VMName $vm_name
$vm.HardwareProfile.VmSize = "Standard_B1s"
Update-AzVM -VM $vm -ResourceGroupName $RG_name
Start-AzVM -ResourceGroupName $RG_name  -Name $vm.name
