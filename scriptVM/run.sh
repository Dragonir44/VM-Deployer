#!/bin/bash
select state in créer supprimer
do
    if [ $state == créer ]
    then
        echo "Combien de VMs voulez-vous déployer ?"
        read -p "Votre saisi → " numVm
        echo "Pour quel formation ?"
        read -p "Votre saisi → " formation
        echo "Prénom et nom du propriétaire (demandeur)"
        read -p "Votre saisi → " owner
        echo "Disponible à partir du (yyyy-mm-dd)"
        read -p "Votre saisi → " startDate
        echo "à (hh:mm)"
        read -p "Votre saisi → " startHour
        echo "jusqu'au (yyyy-mm-dd)"
        read -p "Votre saisi → " endDate
        echo "à (hh:mm)"
        read -p "Votre saisi → " endHour

        terraform -chdir=/home/sysadmin/scriptVM/terraform init #Initialise terraform cas de premier déploiement

        today=$(date) #Récupère la date du jour

        firstName=$(echo $owner | cut -d " " -f 1) #Récupère le prénom du demandeur
        lastName=$(echo $owner | cut -d " " -f 2) #Récupère le nom du demandeur
        idFormateur="$(echo ${firstName:0:1}$lastName | tr '[:upper:]' '[:lower:]')" #Formate le nom et le prénom du demandeur en son identifiant

        adminPassBase="$formation-44@" #Pattern du mot de passe de la sesion Administrateur
        passForm1="Next-@44/1-" #Pattern du mot de passe de la session Formation1
        passForm2="Next-@44-2-" #Pattern du mot de passe de la session Formation2

        #Execute terraform avec les variables d'environnement défini plus haut
        terraform -chdir=/home/sysadmin/scriptVM/terraform apply -var="num_vm=$numVm" -var="vm_name=$formation" -var="initial=${firstName:0:1}${lastName:0:1}" -var="adminPass=$adminPassBase" -var="form1Pass=$passForm1" -var="form2Pass=$passForm2" -var="attributes={\"adminLog\":\"Administrateur/\",\"form1Log\":\"Formation1/\",\"form2Log\":\"Formation2/\",\"owner\": \"$owner\", \"createDate\":\"$today\"}" -auto-approve
        #Récupère les IPs des VMs sur l'output de terraform au format json
        VmIp=$(terraform -chdir=/home/sysadmin/scriptVM/terraform output -json ipv4)
        
        echo "Création des connexions et des comptes formation sur Guacamole"
        
        #Boucle de déploiement de compte Guacamole
        for (( i=1; i<=$numVm; i++ ))
        do
            currentIndex=$( expr $i - 1 ) #Définition de l'index pour les array
            noFormatedIp=$(echo $VmIp | jq ".[$currentIndex]") #Récupère l'adresse IP de la VM currentIndex au format "192.168.20.xxx"
            idForm1="${formation}-1-${i}" #Création de l'identifient n°1 lié à la session Formation1
            idForm2="${formation}-2-${i}" #Création de l'identifient n°2 lié à la session Formation2
            passGuaForm1=$($RANDOM | md5sum | head -c 12) #Génération d'un mot de passe aléatoire pour le premier compte de la VM currentIndex
            passGuaForm2=$($RANDOM | md5sum | head -c 12) #Génération d'un mot de passe aléatoire pour le deuxième compte de la VM currentIndex
            thisIp=$(echo "$noFormatedIp" | sed -z 's/\[//g;s/\]//g;s/\"//g') #Formatage de l'ip en format 192.168.20.xxx
            
            #Execution du playbook ansible de création des utilisateurs et des connexions Guacamole
            ansible-playbook -i /home/sysadmin/scriptVM/ansible/inventory.yml --extra-vars "vmAdmin=\"$thisIp - $formation - Admin\" vmName1=\"$thisIp - $formation - $i - 1\" vmName2=\"$thisIp - $formation - $i - 2\" vmIp=\"$thisIp\" passAdmin=\"${adminPassBase}${i}\" vmPass1=\"${passForm1}${i}\" vmPass2=\"${passForm2}${i}\" idFormateur=\"$idFormateur\" guaId1=\"$idForm1\" guaId2=\"$idForm2\" guaPass1=\"$passGuaForm1\" guaPass2=\"$passGuaForm2\" startDate=\"$startDate\" endDate=\"$endDate\" startHour=\"$startHour\" endHour=\"$endHour\"" -u sysadmin /home/sysadmin/scriptVM/ansible/create.yml

            #Création d'une entrée dans un fichier temporaire pour le récapitulatif envoyer par mail au formateur
            echo "Nom VM Admin $i : $thisIp - $formation - Admin<br/>Nom 1er connexion VM $i : $thisIp - $formation - $i - 1<br/>1er identifiant guacamole VM $i : $idForm1<br/>1er mot de passe guacamole VM $i : $passGuaForm1<br/>Nom 2eme connexion VM $i : $thisIp - $formation - $i - 2<br/>2eme identifiant guacamole VM $i : $idForm2<br/>2eme mot de passe guacamole VM $i : $passGuaForm2<br/>Valide du $startDate au $endDate<br/><br/>" >> htmlBuffer.txt
        done
        echo "Configuration des comptes Guacamole terminé"
        echo "Envoi du mail récapitulatif en cours ..."
        VMInfo=$(cat htmlBuffer.txt) #Récupération du contenu du fichier temporaire
        #Exécution du playbook ansible d'envoie de mail
        ansible-playbook --extra-vars "prenom=\"$firstName\" nom=\"$lastName\" info=\"$VMInfo\"" /home/sysadmin/scriptVM/ansible/mail.yml
        echo "Mail envoyé"
        rm /home/sysadmin/scriptVM/htmlBuffer.txt #Suppression du fichier temporaire
    elif [ $state == supprimer ]
    then
        echo "Formation ?"
        read -p "Votre saisi → " formation
        echo "Prénom et nom du propriétaire (demandeur)"
        read -p "Votre saisi → " owner
        echo "Combien de VMs avez-vous déployer ?"
        read -p "Votre saisi → " numVm
        VmIp=$(terraform -chdir=/home/sysadmin/scriptVM/terraform output -json ipv4) #Récupération des IPs précédement déployer au format json
        firstName=$(echo $owner | cut -d " " -f 1) #Récupère le prénom du demandeur
        lastName=$(echo $owner | cut -d " " -f 2) #Récupère le nom du demandeur
        echo "Suppression en cours..."
        #Execution de la destruction des resources déployer par terraform avec le nom de la formation en variable d'environnement
        terraform -chdir=/home/sysadmin/scriptVM/terraform destroy -var="vm_name=$formation" -var="initial=${firstName:0:1}${lastName:0:1}"  -auto-approve
        #Boucle de suppression des comptes Guacamole
        for (( i=1; i<=$numVm; i++ ))
        do
            currentIndex=$( expr $i - 1 ) #Définition de l'index pour les array
            noFormatedIp=$(echo $VmIp | jq ".[$currentIndex]") #Récupère l'adresse IP de la VM currentIndex au format "192.168.20.xxx"
            ip=$(echo "$noFormatedIp" | sed -z 's/\[//g;s/\]//g;s/\"//g') #Formatage de l'ip en format 192.168.20.xxx
            
            #Execution du playbook ansible de suppression des comptes et des connexions
            ansible-playbook -i /home/sysadmin/scriptVM/ansible/inventory.yml --extra-vars "form=\"$formation\" ip=\"$ip\"" -u sysadmin /home/sysadmin/scriptVM/ansible/destroy.yml
        done
        echo "Suppression terminé"
    fi
    break 2
done