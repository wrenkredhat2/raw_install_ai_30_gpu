#!/bin/bash

# Create Folder Structure
mkdir -p rhoai-gitops/{infrastructure/{nfd,serverless,servicemesh},rhoai-core/{operator,dsc}}

# 1. NFD Subscription (Wave 0)
cat <<EOF > rhoai-gitops/infrastructure/nfd/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-nfd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  channel: stable
  name: nfd
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 2. Service Mesh 3.0 (Wave 0)
cat <<EOF > rhoai-gitops/infrastructure/servicemesh/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ossm-operator
  namespace: openshift-operators
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  channel: stable-3.0
  name: ossm-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 3. Serverless (Wave 0)
cat <<EOF > rhoai-gitops/infrastructure/serverless/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-serverless
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  channel: stable
  name: serverless-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 4. RHOAI 3.0 Operator (Wave 10)
cat <<EOF > rhoai-gitops/rhoai-core/operator/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator
  annotations:
    argocd.argoproj.io/sync-wave: "10"
spec:
  channel: fast-3.x
  name: rhods-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# 5. The DataScienceCluster (Wave 15)
cat <<EOF > rhoai-gitops/rhoai-core/dsc/dsc.yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
  annotations:
    argocd.argoproj.io/sync-wave: "15"
spec:
  components:
    dashboard:
      managementState: Managed
    kserve:
      managementState: Managed
      servingPlatform: singlemodel
    modelmeshserving:
      managementState: Managed
    workbenches:
      managementState: Managed
EOF

# 6. Master Kustomization
cat <<EOF > rhoai-gitops/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - infrastructure/nfd/subscription.yaml
  - infrastructure/servicemesh/subscription.yaml
  - infrastructure/serverless/subscription.yaml
  - rhoai-core/operator/subscription.yaml
  - rhoai-core/dsc/dsc.yaml
EOF

echo "Done! Structure created in ./rhoai-gitops"