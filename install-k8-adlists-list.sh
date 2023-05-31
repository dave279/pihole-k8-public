#!/bin/bash
kubectl create configmap pihole-adlists-list -n pihole --from-file=adlists.list
