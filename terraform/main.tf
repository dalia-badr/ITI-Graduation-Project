# creating our service account and giving it an admin role

resource "google_service_account" "ahmed-SA" {
  account_id   = "final-service-account-id"
  display_name = "final project service account"
}

resource "google_project_iam_binding" "ahmed-binding" {
  project = "ahmed-emad-project"
  role    = "roles/container.admin"
  depends_on = [
         google_service_account.ahmed-SA
     ]
  members = [
    "serviceAccount:${google_service_account.ahmed-SA.email}"
  ]
}


# VPC network
resource "google_compute_network" "ahmed-vpc-network" {
  name                    = "final-vpc-network"
  auto_create_subnetworks = false

}

# public subnet with cloud router , NAT gateway and private VM 
resource "google_compute_subnetwork" "ahmed-public-subnet" {
  name          = "final-management-subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-west3"
  network       = google_compute_network.ahmed-vpc-network.id

}


# cloud router 
resource "google_compute_router" "ahmed-router" {
  name    = "final-router"
  region  = google_compute_subnetwork.ahmed-public-subnet.region
  network = google_compute_network.ahmed-vpc-network.id

  bgp {
    asn = 64514
  }
}

# NAT gateway
resource "google_compute_router_nat" "ahmed-nat" {
  name                   = "final-router-nat"
  router                 = google_compute_router.ahmed-router.name
  region                 = google_compute_router.ahmed-router.region
  nat_ip_allocate_option = "AUTO_ONLY"
  #source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.ahmed-public-subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]

  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# private VM 
resource "google_compute_instance" "ahmed-private-vm" {
  name         = "final-instance"
  machine_type = "e2-micro"
  zone         = "europe-west3-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  
  network_interface {
    network    = google_compute_network.ahmed-vpc-network.id
    subnetwork = google_compute_subnetwork.ahmed-public-subnet.id
  }

  service_account {
    email  = google_service_account.ahmed-SA.email
    scopes = ["cloud-platform"]
  } 
}

# firewall rule to enforce the VM to be private by allowing access only through  IAP
resource "google_compute_firewall" "ahmed-FW" {
  name    = "firewall-to-allow-iap"
  network = google_compute_network.ahmed-vpc-network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
}

# private subnet for private GKE cluster
resource "google_compute_subnetwork" "ahmed-private-subnet" {
  name          = "final-restricted-subnetwork"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west3"
  network       = google_compute_network.ahmed-vpc-network.id
  # private_ip_google_access = "true"
}



# creating our private cluster
resource "google_container_cluster" "ahmed-private-cluster" {
  name       = "final-gke-cluster"
  location   = "europe-west3"
  network    = google_compute_network.ahmed-vpc-network.id
  subnetwork = google_compute_subnetwork.ahmed-private-subnet.id
 
 # creating the least possible node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  private_cluster_config {
    master_ipv4_cidr_block  = "172.16.0.0/28"
    enable_private_nodes    = true
    enable_private_endpoint = true
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.0.0.0/24"
    }
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.16.0.0/16"
    services_ipv4_cidr_block = "10.12.0.0/16"
  }


}

resource "google_container_node_pool" "ahmed-preemptible-nodes" {
  name       = "final-node-pool"
  location   = "europe-west3"
  cluster    = google_container_cluster.ahmed-private-cluster.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-micro"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.ahmed-SA.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}












