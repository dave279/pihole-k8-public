# Pihole K8 Public

Pihole is awesome.  It will greatly reduce the amount of "ad spam" and tracking while 
using the Internet.  But all those DNS requests are not private and can be intercepted.

This project will setup pihole to use DNS over HTTPS (DoH) along with a default 
ad blocking list (~800K domains blocked).  This will keep your DNS requests private
from your ISP and prevent them from doing "ISP Shenanigans" such as tracking what you 
do and selling that info to other companies, injecting ads, etc.

## Getting Started
### Prerequisites

- [MicroK8s](https://microk8s.io/) for our kubernetes cluster

For microk8s, make sure the following add-ons are enabled:
- dns
- ingress
- metallb

MetalLb is a load balancer that allows us to assign a fixed ip address 
"in front of" our k8 pods.  K8 will handle the mapping to the proper 
node (for clusters) and pod.  We just use the assigned load balancer ip.

Follow the tutorial and make note of whatever ip address pool you assign to 
metallb.  It should be an unused range on your network (i.e. outside of any
DHCP scope or other statically assigned addresses.)

#### Microk8s - Single Host or Cluster?
You can install microk8s on a single computer ("host.")  You will get all the
k8 benefits such as pod lifecycle management, host resource management, etc.

The various setup files will still work, you'll just lose out on any "high availability" (HA)
benefits, such as if the single host barfs, pihole will stop working.  In a k8 cluster/HA 
scenario, the pihole workload would get moved to another host in the cluster.

https://microk8s.io/docs/addon-metallb

### Installing

Best practice is to use K8 namespaces to segment up your cluster resources. Our 
first step is to create our pihole namespace

    kubectl apply -f pihole-namespace.yml

When the pod hosting our pihole container is running it will need disk storage. 
My k8 is setup to use a NFS server for storage.  If you are using host-path or 
just want ephemeral storage, edit the file and replace nfs-csi with "" (a quoted empty string)

    kubectl apply -f pihole-pvc-pihole.yml
    kubectl apply -f pihole-pvc-dnsmasq.yml

Pihole uses two files:
1. adlists.list is used during the very first bootstrapping to populate the gravity database
with the domains to blacklist.
2. custom.list is used for local dns entries.  For instance, if you get tired of 
remembering various ip addresses on your network, you can make an entry in this file
to map the ip address to a fully-qualified-domain-name.

We are going to use a k8 feature called a ConfigMap.  Later, we will "volumeMount" these
configMaps into the pod's filesystem.  Run the helper scripts.  If you get an error 
about not finding the kubectl command, just copy the command from the script file and
run in your terminal window.

    install-k8-adlists-list.sh
    install-k8-custom-list.sh

This step creates a "deployment."  We're gonna spin up two containers in the pod:
1. Cloudflared - this creates our HTTPs tunnel to the CloudFlare 1.1.1.1 DNS servers
2. Pihole - this will become our network DNS server

Because both of these containers live in a pod, we can share address space.  
The pihole environment variable DNS points to 127.0.0.1#5053 which is the 
port we've setup Cloudflared to use. 

    kubectl apply -f pihole-deployment.yaml

If your deployment step was successful, pihole should be running 

    kubectl get pod -n pihole

The last step is to create a service to allow the outside world to 
interact/connect to our pihole pod.  Pihole will be used as the DNS
server for your network, so it's important to use a static/fixed ip 
address.  Select an available ip address in your metallb load balancer
address space.  Then edit this file and replace the xxx.xxx.xxx.xxx with
the correct ip address.

    kubectl apply -f pihole-service.yml

If the service installed successfully, you should be able to login to 
your pihole instance using the loadbalancer ip address you selected in the
previous step.  The default password is 'nojunk' (set in the pihole-deployment.yml file)
http://xxx.xxx.xxx.xxx/admin

## Built With

  - [MicroK8s](https://microk8s.io/) - Used as the kubernetes cluster software
  - [Raspberry Pi](https://www.raspberrypi.com/) - Use as the compute host infrastructure
  - [Pi-hole](https://pi-hole.net/) - Network wide ad blocking
