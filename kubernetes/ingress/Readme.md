```

kubectl create namespace ingress-nginx

kubectl apply -f serviceaccount.yaml
kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml
kubectl apply -f deployment.yaml
kubectl apply -f ingressclass-nginx.yaml
kubectl apply -f service.yaml

kubectl apply -f ingress.yaml



```
