#!/bin/bash

# the custom list has the local dns entries
# this will copy the file into a k8 configmap entry
kubectl create configmap pihole-custom-list -n pihole --from-file=custom.list
