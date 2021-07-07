### Pre-requis pour execution
#Install-Module Azure -AllowClobber
#Import-Module Azure
#Connect-AzAccount

Set-Alias -Name Read -Value Read-Host

########################################################### FONCTIONS ###########################################################

### Traitement de la VM
function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name -VirtualNetworkName $VNet_name -SubnetName $subnet_name `
    -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest" 

    #Pour WS2016 : ImageName = MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest
    #Pour WS2019 : ImageName = MicrosoftWindowsServer:WindowsServer:2019-Datacenter-Core:latest

}

function VM_update {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    #Update le "Standard_B1s" a la creation de la VM
    Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
    $vm = Get-AzVM -ResourceGroupName $RG_name -VMName $vm_name
    $vm.HardwareProfile.VmSize = "Standard_B1s"
    Update-AzVM -VM $vm -ResourceGroupName $RG_name
    Start-AzVM -ResourceGroupName $RG_name  -Name $vm.name
}

function VM_stop {
    param ([string]$vm_name,[string]$RG_name)

    #Stop les VMs du RG
    $RG_name = Read "Nom du RG "
    #$vm_name = (Get-AzVM -ResourceGroupName $RG_name).Name
    #Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
    Get-AzVM -ResourceGroupName $RG_name | Select-Object Name | ForEach-Object { Stop-AzVM -ResourceGroupName $RG_Name -Name $_.Name -Force} 
}

function VM_remove {
    param ([string]$vm_name,[string]$RG_name)
    
    Get-AzVM -ResourceGroupName $RG_name | Select-Object Name | ForEach-Object { Remove-AzVM -ResourceGroupName $RG_Name -Name $_.Name -Force} 
}

### Traitement du fichier RDP
function VM_GetRDP {
    param ([string]$vm_name,[string]$RG_name)

    ##### fonction qui permet de creer le fichier RDP d'une VM

    ## test si le dossier de stockage "RDP" existe. Si oui, il passe, si non, il le creer.
    $test_path_directory = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP"

    if ($test_path_directory -eq $true){
        Write-Output "Le dossier RDP existe deja"
    }
    else{
        New-Item "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\" -itemtype directory -Name "RDP"
    }

## test si le fichier "$vm_name.rdp" existe. Si oui, il passe, si non, il le creer.
    $test_file_RDP = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"

    if ($test_file_RDP -eq $true){
        Write-Output "Le fichier RDP existe deja"
    }
    else{
        Get-AzRemoteDesktopFile -ResourceGroupName $RG_name -Name $vm_name -LocalPath "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"
        Write-Output "Le fichier RDP a bien ete cree."
    }
}

function VM_RemoveRDP {
    param ([string]$vm_name)

    ##### fonction qui permet de supprimer le fichier RDP d'une VM

    ## test si le fichier "RDP" existe. Si oui, il le supprime, si non, wtf.
    $test_file_RDP = Test-Path -Path "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\RDP\$vm_name.rdp"

    if ($test_file_RDP -eq $true){
        Remove-Item "C:\Users\Antoine\OneDrive - SCIENCES U LYON\ESGI\EII20-21\Powershell\project_powershell\$vm_name.rdp" -itemtype directory -Name "RDP"
    }
    else{
        Write-Output "Le fichier rdp est inexistant."
    }
}

### Traitement du NSG
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
            break
        }
    }
}

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
Write-Output "`tg. [7] To Quit"
Write-Output "========================================================"
Write-Output "`r" #saute une ligne
$menu_choice = Read "Enter Choice"

############################################################# SWITCH ###########################################################
switch ($menu_choice) {

    #Deploiement de VMs une par une avec des parametres differents
    '1'{ 
        $answer = "yes"
        
        while ($answer -eq "yes") {
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
        VM_remove -vm_name ($vm_name = Read "Nom de la VM  ") -RG_name ($RG_name = Read "Nom du RG  ")
        VM_RemoveRDP -vm_name $vm_name
    }

    #DL RDP
    '6'{
        VM_GetRDP -vm_name (Read "Nom de la VM") -RG_name (Read "Nom du RG")
    }

    #Stop le script
    '7'{return}
}
