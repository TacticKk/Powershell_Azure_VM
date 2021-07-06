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
