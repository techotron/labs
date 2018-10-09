# Command cheatsheet for minikube commands

## Service related Commands
Install minikube, kubectl, docker, virtualbox (MacOS using homebrew)
```buildoutcfg
brew update && brew install kubectl && brew cask install docker minikube virtualbox
```

Open LoadBalancer Service
- Minikube doesn't create an external IP address when you create a load balancer service. The service will always show in a `pending` state. In order to access the service, you can run this command to open a browser to the load balancer service you've created..
```buildoutcfg
minikube service <service-name>
```

## Dashboard
Get the dashboard URL
```buildoutcfg
minikube dashboard
```