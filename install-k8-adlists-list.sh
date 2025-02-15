#!/bin/bash
microk8s kubectl create configmap pihole-adlists-list -n pihole --from-file=adlists.list
