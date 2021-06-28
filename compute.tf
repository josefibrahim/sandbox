 resource "google_compute_instance" "vm"{
     name                       = "${var.name}-vm"
     machine_type               = "f1-micro"
     metadata_startup_script    = file("startup.sh")
     tags                       = ["lb", "ssh"]
     zone                       = var.zone
     allow_stopping_for_update  = true
     boot_disk {
         initialize_params {
             image = "ubuntu-os-cloud/ubuntu-2004-lts"
         }
     }
     
     network_interface {
         network = google_compute_network.vpc_network.name
     }

     service_account {
     scopes = ["cloud-platform"]
     email  =  "wordpress@coen-josef-ibrahim.iam.gserviceaccount.com"
     }
 }

 
 
