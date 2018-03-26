<%
  import os, yaml

  values={}
  if context.get("values", "") != "":
    values=yaml.load(open(context.get("values", "")))

  if context.get("cloud", "") == "":
    raise Exception("missing --var cloud={aws,azure,gcp,openstack,vagrant} flag")

  def value(path, default):
    keys=str.split(path, ".")
    root=values
    for key in keys:
      if isinstance(root, dict):
        if key in root:
          root=root[key]
        else:
          return default
      else:
        return default
    return root

  region=""
  if cloud == "aws":
    region="eu-west-1"
  elif cloud == "azure":
    region="westeurope"
  elif cloud == "gcp":
    region="europe-west1"
  elif cloud == "openstack":
    region="europe-1"
  elif cloud == "vagrant":
    region="local"
%># Seed cluster registration manifest into which the control planes of Shoot clusters will be deployed.
---
apiVersion: garden.sapcloud.io/v1beta1
kind: Seed
metadata:
  name: ${value("metadata.name", cloud)}
spec:
  cloud:
    profile: ${value("spec.cloud.profile", cloud)}
    region: ${value("spec.cloud.region", region)}
  secretRef:
    name: ${value("spec.secretRef.name", "seed-" + cloud)}
    namespace: ${value("spec.secretRef.namespace", "garden")}
  ingressDomain: ${value("spec.ingressDomain", "dev." + cloud + ".seed.example.com") if cloud != "vagrant" else "<minikube-ip>.nip.io"}
  networks: # Seed and Shoot networks must be disjunct
    nodes: ${value("spec.networks.nodes", "10.240.0.0/16") if cloud != "vagrant" else "192.168.99.100/24"}
    pods: ${value("spec.networks.pods", "10.241.128.0/17") if cloud != "vagrant" else "172.17.0.0/16"}
    services: ${value("spec.networks.services", "10.241.0.0/17") if cloud != "vagrant" else "10.96.0.0/13"}
