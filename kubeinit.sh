# configuration in ~/.config/gcloud

# gcloud init
# echo "set region and zone to eu-west-2/europe-west2-a"
# gcloud config set compute/region eu-west2
# gcloud config set compute/zone europe-west2-a

echo "create network"
gcloud compute networks create kubenet --subnet-mode custom

echo "create subnet"
gcloud compute networks subnets create kubernetes \
  --network kubenet \
  --range 10.240.0.0/24

echo "create fw rules for internal access"
gcloud compute firewall-rules create kubenet-allow-internal \
  --allow tcp,udp,icmp \
  --network kubenet \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

echo "create fw rules for external access"
gcloud compute firewall-rules create kubenet-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubenet \
  --source-ranges 0.0.0.0/0

echo "list fw rules"
gcloud compute firewall-rules list --filter="network:kubenet"

# echo "create public ip"
# gcloud compute addresses create kubenet \
#  --region $(gcloud config get-value compute/region)

# echo "verify public ip"
# gcloud compute addresses list --filter="name=('kubenet')"

echo "create vm instances (controllers)"
#for i in 0 1 2; do
for i in 0; do
    gcloud compute instances create controller-${i} \
      --async \
      --boot-disk-size 200GB \
      --can-ip-forward \
      --image-family ubuntu-1804-lts \
      --image-project ubuntu-os-cloud \
      --machine-type n1-standard-1 \
      --private-network-ip 10.240.0.1${i} \
      --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
      --subnet kubernetes \
      --tags kubenet,controller

    echo "${instance} - internal ip:"
    gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].networkIP)'

    echo "${instance} - external ip:"
    gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].accessConfigs[0].natIP)'
done

echo "create vm instances (workers)"
#for i in 0 1 2; do
for i in 0; do
    gcloud compute instances create worker-${i} \
      --async \
      --boot-disk-size 200GB \
      --can-ip-forward \
      --image-family ubuntu-1804-lts \
      --image-project ubuntu-os-cloud \
      --machine-type n1-standard-1 \
      --metadata pod-cidr=10.200.${i}.0/24 \
      --private-network-ip 10.240.0.2${i} \
      --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
      --subnet kubernetes \
      --tags kubenet,worker

    echo "${instance} - internal ip:"
    gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].networkIP)'

    echo "${instance} - external ip:"
    gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].accessConfigs[0].natIP)'
done

echo "list instances"
gcloud compute instances list

echo "ssh to instance"
echo "for example, gcloud compute ssh controller-0"
