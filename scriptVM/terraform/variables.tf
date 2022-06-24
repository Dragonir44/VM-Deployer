variable "num_vm" {
    default = 1
}

variable "vm_name" {
    default = "" #Début du nom de la VM
}

variable "initial" {
    default = "" #Fin du nom de la VM
}

variable "start_name" {
    default = 0 #Le nom est en incrémentation, cette variablel défini le début de l'incrémentation
}

#Variables de définition du mot de passe Administrateur
variable "adminPass" {
    default = "Next-601@ND"
}

#Mot de passe du compte formation1
variable "form1Pass" {
    default = "NextForm1-@44"
}
#Mot de passe du compte formation2
variable "form2Pass" {
    default = "NextForm2-@44"
}

#Variable des attributs personnalisé
variable "attributes" {
    type = map
    default = {
        adminLog    = "Administrateur/",
        form1Log    = "Formation1/",
        form2Log    = "Formation2/",
        createDate  = "01/01/2023",
        owner       = "Next"
    }   
}