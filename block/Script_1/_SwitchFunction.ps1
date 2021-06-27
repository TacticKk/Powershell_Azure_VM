switch ($choice) {

    #Déploiement de VMs une par une avec des paramètres différents
    '1'{ 
        $answer = "yes"
        
        while ($answer -eq "yes") {
            VM_creation -vm_name (Read "Nom de la VM  ") -RG_name (Read "Nom du RG  ") -Location_name (Read "Nom de la location  ") -VNet_name (Read "Nom du VNet  ") `
            -subnet_name (Read "Nom du subnet  ") -NSG_name (Read "Nom du NSG  ")
            
            $answer = Read "Do you want to create une VM sur Azure ? "
        }
    }

    #Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '2'{
        $answer = Read "How much VM do want to create sur Azure ? "
        $RG_name = Read "Nom du RG "
        $Location_name = Read "Nom de location "
        $Vnet_name = Read "Nom du VNet "
        $Subnet_name = Read "Nom du Subnet "
        $NSG_name = Read "Nom du NSG "

        $i = 1
        while ($i -le $answer) {
            $vm_name = Read "Nom de la VM $i"
            VM_creation -vm_name $vm_name -RG_name $RG_name -Location_name $Location_name -VNet_name $Vnet_name -subnet_name $Subnet_name -NSG_name $NSG_name 
            $i++
        }
    }

    #Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '3'{
        Write-Host "You have selected a Dev Environment"
    }
    #Ferme le script
    '4'{Return}
}
