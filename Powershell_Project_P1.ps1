### Pré-requis pour exécution
#Install-Module Azure -AllowClobber
#Import-Module Azure
#Connect-AzAccount

Set-Alias -Name Read -Value Read-Host

########################################################### FONCTIONS ###########################################################
function VM_creation {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    New-AzVm -ResourceGroupName $RG_name -Location $Location_name -Name $vm_name -SecurityGroupName $NSG_name -VirtualNetworkName $VNet_name -SubnetName $subnet_name `
    -ImageName "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest" 

    #Pour WS2016 : ImageName = MicrosoftWindowsServer:WindowsServer:2016-Datacenter-Server-Core:latest
    #Pour WS2019 : ImageName = MicrosoftWindowsServer:WindowsServer:2019-Datacenter-Core:latest

}

function VM_update {
    param ([string]$vm_name,[string]$RG_name,[string]$Location_name,[string]$VNet_name,[string]$subnet_name, [string]$NSG_name)

    #Update le "Standard_B1s" à la création de la VM
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
    $vm_name = (Get-AzVM -ResourceGroupName $RG_name).Name
    Stop-AzVM -ResourceGroupName $RG_name -Name $vm_name -Force
}

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

############################################################# MENU #############################################################

Write-Host "============= Choose =============="
Write-Host "`ta. [1] pour déployer des VMs en précisant chaque paramètre"
Write-Host "`tb. [2] pour déployer un nombre précis de VMs avec les mêmes paramètres"
Write-Host "`tc. [3] pour déployer des VMs depuis un CSV"
Write-Host "`tc. [4] pour stopper les VMs d'un RG"
Write-Host "`tc. [5] pour télécharger un fichier RDP d'une VM"
Write-Host "`td. [6] to Quit'"
Write-Host "========================================================"
$menu_choice = Read "Enter Choice"

############################################################# SWITCH ###########################################################
switch ($menu_choice) {

    #Déploiement de VMs une par une avec des paramètres différents
    '1'{ 
        $answer = "yes"
        
        while ($answer -eq "yes") {
            VM_creation -vm_name ($vm_name = Read "Nom de la VM  ") -RG_name ($RG_name = Read "Nom du RG  ") -Location_name ($location_name = Read "Nom de la location  ") `
            -VNet_name ($VNet_name = Read "Nom du VNet  ") -subnet_name ($subnet_name = Read "Nom du subnet  ") -NSG_name ($NSG_name = Read "Nom du NSG  ")

            VM_update -vm_name $vm_name -RG_name $RG_name -Location_name $location_name -VNet_name $VNet_name -subnet_name $subnet_name -NSG_name $NSG_name

            VM_GetRDP -vm_name $vm_name -RG_name $RG_name
            
            $answer = Read "Voulez-vous créer une VM sur Azure ? "
        }
    }

    #Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '2'{
        $answer = Read "Combien de VMs voulez-vous créer sur Azure ? "
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
    }

    #Déploiement de VMs via CSV
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
        
            # Check si la vm existe déjà dans le RG
            $Get_vm = (Get-AzVM -ResourceGroupName "RG_test").Name
        
            if ($Get_vm -eq $VM_name ) {
        
                Write-Warning "Une VM avec le nom $VM_name existe déjà dans le groupe de ressource $RG_name."
            }
            else {
                #Si la VM existe pas, il la créer
                VM_creation -vm_name $vm_name -RG_name $RG_name -Location_name $Location_name -VNet_name $Vnet_name -subnet_name $Subnet_name -NSG_name $NSG_name

                VM_update -vm_name $vm_name -RG_name $RG_name -Location_name $location_name -VNet_name $VNet_name -subnet_name $subnet_name -NSG_name $NSG_name

                VM_GetRDP -vm_name $vm_name -RG_name $RG_name
        
                Write-Host "La VM $VM_name a bien été créée dans le groupe de ressource $RG_name." -ForegroundColor Cyan
            }
        }
    }
    #Stop les VMs
    '4'{VM_stop}

    #DL RDP
    '5'{
        VM_GetRDP -vm_name (Read "Nom de la VM  ") -RG_name (Read "Nom du RG  ")
    }

    #Stop le script
    '6'{return}
}

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
