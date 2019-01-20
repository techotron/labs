# Command cheatsheet for helm

# helm

## Install Helm

You can install the latest version using brew
```buildoutcfg
brew install kubernetes-helm
```

You can install a specific version by downloading the tar from https://github.com/helm/helm/tags and running the following commands
```buildoutcfg
tar -zxvf helm-v2.9.1-darwin-amd64.tar.gz
mv ./darwin-amd64/helm /usr/local/bin/helm
```

## Install Traefik

Search for helm chart
```buildoutcfg
helm search traefik
```

Install helm chart
```buildoutcfg
helm install stable/traefik --name traefik --namespace kube-system
```

List Helm deployments
```buildoutcfg
helm list
```

Check status of the service
```buildoutcfg
kubectl get svc traefik --namespace kube-system -w
```

When the `EXTERNAL-IP` is no longer `<pending>`:
```buildoutcfg
kubectl describe service traefik -n kube-system | grep Ingress | awk '{print $3}'
```

Create ingress rule for traefik ui (only an example. The following works with a manually deployed pod - not one deployed using helm):
```buildoutcfg
kubectl apply -f https://raw.githubusercontent.com/techotron/labs/master/HelmCharts/Traefik/traefik-ui.yml
```

Delete a helm deployment(?)
```buildoutcfg
helm del --purge traefik
```