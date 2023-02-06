#!/bin/bash
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
