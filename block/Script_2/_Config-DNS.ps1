Add-DnsServerPrimaryZone -NetworkID 10.0.1.0/24 -ZoneFile “10.0.1.4.in-addr.arpa.dns” #Mettre l'IP de son serveur

Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru

Test-DnsServer -IPAddress 10.0.1.4 -ZoneName "Powershell.local" #Vérif fonctionnement DNS
