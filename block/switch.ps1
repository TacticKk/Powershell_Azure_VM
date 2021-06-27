switch ($choice) {

#Déploiement de VMs une par une avec des paramètres différents
    '1'{ 
        $answer = Read "Do you want to create une VM sur Azure ? "
        
        while ($answer -eq "yes") {
            VM_creation -vm_name (Read "Nom de la VM  ") -RG_name (Read "Nom du RG  ") -Location_name (Read "Nom de la location  ") -VNet_name (Read "Nom du VNet  ") `
            -subnet_name (Read "Nom du subnet  ") -NSG_name (Read "Nom du NSG  ") 
            
            $answer = Read "Do you want to create une VM sur Azure ? "
        }
    }

#Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '2'{
        $answer = Read "How much VM do want to create sur Azure ? "
        $i = 1

        while ($i -ne $answer) {
            VM_creation -vm_name (Read "Nom de la VM  ") -RG_name "RG_test" -Location_name "francecentral" -VNet_name "VNet_test" -subnet_name "frontendSubnet" -NSG_name "NSG_test" 
            
            $i++
        }
    }

#Déploiement de VMs par nombre avec des mêmes paramètres (en dur dans le script)
    '3'{
        Write-Host "You have selected a Dev Environment"
    }

    '4'{Return}
}
