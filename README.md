# gcp-project

## project description

![Alt text](./photos/conceptual%20model.jpg?raw=true "Title")

---

![Alt text](./photos/ingress-controller.png?raw=true "Title")

### Infrastructure consists of

- vpc
    - Management subnet has
        - NAT gateway
        - Private VM
    - Restricted subnet has
        - Private standard GKE cluster (private control plan)

- Infrastructure properties
    1. Restricted subnet does not have access to internet
    2. All images (devops-challenge & redis) deployed on GKE come from GCR
    3. The VM is private
    4. Deployment is exposed to public internet with a public HTTP load balancer as well as using  ingress and it's controller
    5. All infra is created on GCP using terraform
    6. Deployment on GKE done manually by kubectl tool
    7. 2 service accounts are created with least privilege
        - service account: `sa-private-vm`, it's role: `roles/container.admin`
        - service account: `sa-private-gke`, it's role: `roles/storage.objectViewer`
    8. Only the management subnet can connect to the gke cluster

## Deployment

### Terraform scripts are used to deploy all the infrastructure on GCP

- ./terraform/main.tf file content

```bash
    module "iam-section" {
        source = "./iam-and-admin"
        project_name = "ahmed-nasr-iti-demo"
        service_accounts = {
            # service_account_name = required_role
            "sa-private-vm" = "roles/container.admin",
            "sa-private-gke" = "roles/storage.objectViewer"
        }
    }

    module "vpc-network" {
        source = "./vpc-network"
        vpc_name = "vpc-network"
        subnets_data = {
            "management-subnet" = "10.0.0.0/24",
            "restricted-subnet" = "10.0.1.0/24"
        }
        subnets_region = "us-central1"
        is_private_ip_accessible = {
            "management-subnet" = false,
            "restricted-subnet" = true
        }
        nat_router_name = "nat-router"
        nat_gateway_name = "nat-gateway"
        nat_ip_allocation = "AUTO_ONLY"
        nat_subnet_ip_range = "ALL_SUBNETWORKS_ALL_IP_RANGES"
        firewall_rule_name = "allow-incoming-ssh-from-iap"
        firewall_traffic_direction = "INGRESS"
        service_account_email_list = [module.iam-section.private-vm-sa-email]
        firewall_source_ranges_list = ["35.235.240.0/20"]
        firewall_protocol = "tcp"
        firewall_target_port_list = ["22"]
    }

    module "private-vm" {
        source = "./compute-engine"
        name = "my-private-vm"
        vm_type = "f1-micro"
        vm_zone = "us-central1-a"
        vm_image = "ubuntu-os-cloud/ubuntu-2004-lts"
        vm_subnet_self_link = module.vpc-network.management_subnet_self_link
        vm_service_account = module.iam-section.private-vm-sa-email
        vm_scopes = [ 
            "https://www.googleapis.com/auth/cloud-platform"
        ]
    }

    module "gke-cluster" {
        source = "./kubernates-engine"
        name = "private-gke-cluster"
        zone_name = "us-central1-a" 
        network_self_link = module.vpc-network.network_self_link
        subnet_self_link = module.vpc-network.restricted_subnet_self_link
        remove_default_node_pool = true
        authorized_network_cidr_range = "10.0.0.0/24"
        authorized_network_name = "management_subnet"
        enable_private_nodes = true
        enable_private_endpoint = true
        master_cidr_range = "172.16.0.0/28"
        enable_network_policy = true
        node_pool_name = "my-node-pool"
        node_count = 2
        is_preemptible = true
        node_vm_type = "g1-small"
        gke_service_account_email = module.iam-section.gke-sa-email
        oauth_scopes_list = [ 
            "https://www.googleapis.com/auth/cloud-platform"
        ]
    }

```

### Pushing images to gcr.io

- ./configurations/creating-pushing-gcr-image.sh
- devops challenge image created from ./app/Dockerfile

```bash
    docker build -t gcr.io/ahmed-nasr-iti-demo/devops-challenge:v1.0 ../app
    docker push gcr.io/ahmed-nasr-iti-demo/devops-challenge:v1.0

    docker tag redis gcr.io/ahmed-nasr-iti-demo/redis
    docker push gcr.io/ahmed-nasr-iti-demo/redis

```

### ssh to your private vm and run the following commands

- ./configurations/private-vm.sh

```bash
    # installing gcloud
    sudo apt-get install -y apt-transport-https ca-certificates gnupg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install google-cloud-cli
    # installing google-cloud-sdk-gke-gcloud-auth-plugin
    sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
    # installing kubectl
    grep -rhE ^deb /etc/apt/sources.list* | grep "cloud-sdk"
    sudo apt-get install -y kubectl
    # connecting to the private cluster
    gcloud container clusters get-credentials private-gke-cluster --zone us-central1-a --project ahmed-nasr-iti-demo

```

### apply k8s yaml files with the following order

1. ./k8s-yaml-files/env-configmap.yaml
2. ./k8s-yaml-files/deployment-devops-challenge.yaml
3. ./k8s-yaml-files/loadbalancer-service.yaml
4. to use ingress (optional)
    - create ingress controller using instructions in ./k8s-yaml-files/ingress-configurations/ingress-configuration-steps
    - apply ingress yaml file in same directory
    - if you don't have a domain name add ingress load balancer ip and test domain to /etc/hosts file

## Gallery

created service accounts

![Alt text](./photos/created%20service%20accounts.png?raw=true "Title")

---

created vpc details

![Alt text](./photos/created%20vpc%20details.png?raw=true "Title")

---

firewall rule  to allow iap

![Alt text](./photos/firewall%20rule%20%20to%20allow%20iap.png?raw=true "Title")

---

vpc peering for gke

![Alt text](./photos/vpc%20peering%20for%20gke.png?raw=true "Title")

---

images pushed to gcr

![Alt text](./photos/gcr-images.png?raw=true "Title")

---

created VMs from gke and the private one

![Alt text](./photos/created%20vms.png?raw=true "Title")

---

gke cluster

![Alt text](./photos/gke-cluster.png?raw=true "Title")

---

gke cluster details

![Alt text](./photos/gke-cluster-details-1.png?raw=true "Title")

---

![Alt text](./photos/gke-cluster-details-2.png?raw=true "Title")

---

gke cluster data

![Alt text](./photos/gke-cluster-data.png?raw=true "Title")

---

gke cluster load balancer services

![Alt text](./photos/cluster-loadbalancers.png?raw=true "Title")

---

testing network load balancer service respone

![Alt text](./photos/loadbalancer-ip-respone.png?raw=true "Title")

---

ingress and cluster overview

![Alt text](./photos/ingress-controller.png?raw=true "Title")

---

ingress controller installation

![Alt text](./photos/ingress-controller-installation.png?raw=true "Title")

---

created ingress service

![Alt text](./photos/cluster-ingress.png?raw=true "Title")

---

ingress details

![Alt text](./photos/cluster-ingress-details.png?raw=true "Title")

---

adding ingress load balancer ip to hosts file

![Alt text](./photos/adding%20ingress%20load%20balancer%20ip%20to%20hosts%20file.png?raw=true "Title")

---

testing ingress using curl

![Alt text](./photos/testing-ingress-using-curl.png?raw=true "Title")

---

cluster data, ingress data, and testing ingress

![Alt text](./photos/cluster-data-ingress-testing-ingress.png?raw=true "Title")
