function VM_GetRDP {
    param ([string]$vm_name,[string]$RG_name)

    ##### fonction qui permet de créer le fichier RDP d'une VM

    ## test si le dossier de stockage "RDP" existe. Si oui, il passe, si non, il le créer.
    $test_path_directory = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP"

    if ($test_path_directory -eq $true){
        Write-Output "Le dossier RDP existe déjà"
    }
    else{
        New-Item "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\" -itemtype directory -Name "RDP"
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
