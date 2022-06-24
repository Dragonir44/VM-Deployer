#Initialisation de terraform (source du provider et version de l'api)
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
  required_version = ">= 0.13"
}

#Configuration des éléments de connexion à vsphere
provider "vsphere" {
    user = "terraform@vsphere.local"
    password = "EFT(*)^E8Mk:c>Rg"
    vsphere_server = "192.168.6.70"
    allow_unverified_ssl = true
}

#Définition du nom du datacenter
data "vsphere_datacenter" "dc" {
  name = "Next Decision"
}

#Définition du datastore contenue dans le datastore
data "vsphere_datastore" "datastore" {
  name = "datastore4"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Définition du pool où intégrer la/les VM(s)
data "vsphere_resource_pool" "pool" {
  name          = "Pool-Formation"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Définition du réseau virtuel où se positionne la/les VM(s)
data "vsphere_network" "network" {
  name = "VM Formation"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Définition du template de VM à utiliser
data "vsphere_virtual_machine" "template" {
  name = "Template P05 - WinServ 19 Formation"
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
#Récupération des id des attributs personnalisé
data "vsphere_custom_attribute" "loginAd" {
  name = "NextAdmin"
}

data "vsphere_custom_attribute" "loginForm1" {
  name = "Login / Pass"
}

data "vsphere_custom_attribute" "loginForm2" {
  name = "Note"
}

data "vsphere_custom_attribute" "date" {
  name = "Date"
}

data "vsphere_custom_attribute" "owner" {
  name = "Responsable"
}

#Création de la / des VM(s)
resource "vsphere_virtual_machine" "vm" {
  count = var.num_vm
  name = "${var.vm_name} - ${count.index + 1} (${var.initial})" #Nom que la /les VM(s) prendrons
  resource_pool_id = data.vsphere_resource_pool.pool.id #Envoi dans le pool précédement configurer

  num_cpus = 2 #Nombre de cpu aloué
  memory = 4096 #Quantité de ram aloué (en bits)
  guest_id = data.vsphere_virtual_machine.template.guest_id #Id du template

  scsi_type = data.vsphere_virtual_machine.template.scsi_type #Type de stockage du template

  #Paramètre du réseau d'appartenance
  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  #paramètre du disque
  disk {
    label = "disk0"
    size = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  #Début du clone
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id #récupération de l'id du template
    customize {
      timeout = 0
      windows_options {
        computer_name = "${var.vm_name}${count.index + 1}" #Nom de la machine
        admin_password = "${var.adminPass}${count.index + 1}" #Mot de passe du compte Administrateur
      }
      #Paramètre de la carte réseau (vide si DHCP)
      network_interface {}
    }
  }
  #Ajout des attributs personnalisé sur vsphere
  custom_attributes = "${tomap({(data.vsphere_custom_attribute.loginForm1.id) = format("%s%s%s",var.attributes.form1Log, var.form1Pass,count.index+1), (data.vsphere_custom_attribute.loginForm2.id) = format("%s%s%s",var.attributes.form2Log,var.form2Pass,count.index+1), (data.vsphere_custom_attribute.loginAd.id) = format("%s%s%s",var.attributes.adminLog,var.adminPass,count.index+1), (data.vsphere_custom_attribute.date.id) = var.attributes.createDate, (data.vsphere_custom_attribute.owner.id) = var.attributes.owner})}"
}

#Resource d'attente (optention de l'adresse ip par DHCP)
resource "time_sleep" "wait_10_minutes" {
  depends_on = [vsphere_virtual_machine.vm[0]]

  create_duration = "10m"
}

#Récupération de tout les paramtères de la VM
data "vsphere_virtual_machine" "result" {
  count         = var.num_vm
  name          = "${var.vm_name} - ${count.index + 1} (${var.initial})" #Nom de la VM
  datacenter_id = data.vsphere_datacenter.dc.id
  depends_on    = [time_sleep.wait_10_minutes] #Ne se lance que après celui là
}

#Resource de connection par SSH (OpenSSH serveur est actif sur le template)
resource "null_resource" "runCmd" {
  count = var.num_vm
  connection {
    type = "ssh" #Protocole utilisé
    user = "Administrateur" #Nom d'utilisateur
    password = "${var.adminPass}${count.index+1}" #Mot de passe défini dans les variables
    host = data.vsphere_virtual_machine.result[count.index].guest_ip_addresses[0] #Adresse ip de la machine
    port = 22 #Port d'écoute du protocole (au cas où)

    target_platform = "windows" #Plateforme de connection (windows ou unix)

    #Paramètre pour une connection winrm (si un jour cela fonctionne)
    #https = true
    #insecure = true
    #use_ntlm = true
  }

  #Execution des commande pour le changement des mots de passe utilisateur de formation
  provisioner "remote-exec" {
    inline = [
      "powershell -Command \"&{Get-LocalUser -Name \"Formation1\" | Set-LocalUser -Password ('${var.form1Pass}${count.index + 1}' | ConvertTo-SecureString -AsPlainText -Force)}\"",
      "powershell -Command \"&{Get-LocalUser -Name \"Formation2\" | Set-LocalUser -Password ('${var.form2Pass}${count.index + 1}' | ConvertTo-SecureString -AsPlainText -Force)}\"",
    ]
  }
  depends_on = [data.vsphere_virtual_machine.result]
}