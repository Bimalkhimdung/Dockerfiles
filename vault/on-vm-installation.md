# Helm Installation

## Create storage class 

``` kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml ```

## Get storage class 
``` kubectl get storageclass ```

``` helm repo add hashicorp https://helm.releases.hashicorp.com ```

## Create namespace 

``` kubectl create namespace vault ```



## Install Vault on dedicated VM

``` 

# Install yum-utils which contains yum-config-manager
sudo dnf install -y yum-utils

# Then add the HashiCorp repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo


# From your Kubernetes jump host or any node
curl http://<VAULT_VM_IP>:8200/v1/sys/health

# You should get a JSON response

# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'

# Login to Vault
vault login <your-root-token>

# Enable Kubernetes auth method
vault auth enable kubernetes


# Create a service account for Vault
kubectl create serviceaccount vault-auth -n vault

# Create ClusterRoleBinding for token review
kubectl create clusterrolebinding vault-auth-binding \
  --clusterrole=system:auth-delegator \
  --serviceaccount=vault:vault-auth

# Get the service account token (for Kubernetes 1.24+)
kubectl create token vault-auth -n vault --duration=999999h > /tmp/vault-token.txt

# Get Kubernetes CA certificate
kubectl config view --raw --minify --flatten \
  -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > /tmp/k8s-ca.crt

# Get Kubernetes API server address
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'



On your Vault VM:

# Set variables (replace with your actual values)
export K8S_HOST="https://<K8S_API_SERVER_IP>:6443"
export K8S_CA_CERT=$(cat /tmp/k8s-ca.crt)
export SA_TOKEN=$(cat /tmp/vault-token.txt)

# Configure Kubernetes auth in Vault
vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$K8S_CA_CERT"



vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    disable_local_ca_jwt=true


# Create policy
vault policy write myapp-policy - <<EOF
path "secret/data/myapp" {
  capabilities = ["read"]
}
EOF

# Verify policy
vault policy read myapp-policy


# Create role that binds the policy to Kubernetes service account
vault write auth/kubernetes/role/myapp \
    bound_service_account_names=myapp-sa \
    bound_service_account_namespaces=default \
    policies=myapp-policy \
    ttl=24h


  # Store your secrets
vault kv put secret/myapp ABC=1234 XYZ=4343

# Verify
vault kv get secret/myapp


# Create service account in default namespace
kubectl create serviceaccount myapp-sa -n default



# Install the operator
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace \
  --set defaultVaultConnection.enabled=true \
  --set defaultVaultConnection.address=http://<VAULT_VM_IP>:8200


# Configure Vault Connection

cat <<EOF | kubectl apply -f -
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  name: vault-connection
  namespace: default
spec:
  address: http://10.0.67.160:8200
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vault-auth
  namespace: default
spec:
  vaultConnectionRef: vault-connection
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: myapp
    serviceAccount: myapp-sa
EOF

# Create VaultStaticSecret to Sync to K8s Secret

cat <<EOF | kubectl apply -f -
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: db-creds
  namespace: default
spec:
  vaultAuthRef: vault-auth
  mount: secret
  type: kv-v2
  path: myapp
  refreshAfter: 30s
  destination:
    create: true
    name: db-creds
EOF


```

## Install injector on kubernetese 

Only isntall injector as vault will be installed on dedicated VM.


``` helm install vault hashicorp/vault -n vault -f values.yaml ```

## Upgrade vault

``` helm upgrade vault hashicorp/vault -n vault -f values.yaml ```



## First Time init

``` vault operator init ```

## Unseeal vault
``` vault operator unseal ```


