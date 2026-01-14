# OCP AI-30 Setup

Complete setup guide for Installing an NVIDIA-GPU enabled

## Overview

This setup deploys a complete GPU-enabled OpenShift environment with:
- **Node Feature Discovery (NFD)** for hardware detection
- **NVIDIA GPU Operator** for automated GPU resource management
- **Custom configurations** for production GPU workloads
- **AI-30-Operator** for production GPU workloads
- **AI-30-Instance** for production GPU workloads

## Clone the Repository

```bash
git clone https://github.com/rh-aiservices-bu/ocp-gpu-setup.git
cd ocp-gpu-setup
```

## Step 1: Install Argo

All subsequent steps are excuted by injecting applications into ARGO-CD.
as for the Applications is skip on missingResources is true, there might be longer Sync-runs due to missing CRDs in combination with thier creation and retries.

```bash
oc create -f ./argo-cd/subscription.yaml
oc create -f ./argo-cd/.yaml

```

**Note:**:
If there is the need of revoing a namespace dur to syncronistaion Problems ther is a small redmae comprisoing the commands of how to get rid of TERMINATING namespaces:
 --> argo-cd/remove-gitops.gist


## Step 2: Deploy Node Feature Discovery (NFD)

NFD detects hardware features on cluster nodes and labels them for workload scheduling.

```bash
oc create -f ./argo-application/nfd-application.yaml
```

**What this deploys:**
- **Namespace**: `openshift-nfd` with cluster monitoring
- **Operator**: Red Hat NFD operator (v4.18.0)
- **Configuration**: Scans nodes every 60 seconds for PCI devices including GPUs
- **NFD-Instance**: the NodefeatureDisconry 

## Step 3: Deploy NVIDIA GPU Operator

The GPU Operator automates the management of NVIDIA GPU software stack.

```bash
Warning: metadata.finalizers: "argoproj.io/resources-finalizer": prefer a domain-qualified finalizer name including a path (/) to avoid accidental conflicts with other finalizer writers
```

**What this deploys:**
- **Namespace**: `nvidia-gpu-operator`
- **Operator**: NVIDIA GPU Operator (v25.3.0) from certified operators
- **Components**: GPU drivers, container runtime, device plugins, monitoring

Wait for both NFD and GPU Operator to be fully installed before proceeding.

## Step 4: Deploy Custom Resources (CRs)

The CRs configure how NFD and the GPU Operator should operate in your cluster.

```bash
oc apply -f ./crs
```

**What this configures:**

### Node Feature Discovery Configuration
- **Hardware Detection**: Identifies NVIDIA GPUs and other PCI devices
- **Node Labeling**: Adds vendor and device information as node labels
- **Scheduling**: Enables GPU-aware pod scheduling

### GPU Cluster Policy
- **Driver Management**: Automatic NVIDIA driver installation and updates
- **Monitoring**: DCGM (Data Center GPU Manager) for GPU metrics
- **Device Plugin**: Exposes GPU resources to Kubernetes scheduler
- **MIG Support**: Multi-Instance GPU configuration capability
- **Validation**: GPU functionality testing and validation

### Driver Configuration
- **Container Image**: Specific NVIDIA driver version with SHA256 verification
- **Registry**: Uses NVIDIA's official container registry
- **Integration**: OpenShift driver toolkit compatibility

## Verification

After deployment, verify your GPU setup:

```bash
# Check GPU nodes
oc get nodes -l nvidia.com/gpu.present=true

# Check GPU operator pods
oc get pods -n nvidia-gpu-operator

# Check NFD labels on GPU nodes
oc describe node <gpu-node-name> | grep nvidia

# Check available GPU resources
oc describe node <gpu-node-name> | grep nvidia.com/gpu
```

## Supported GPU Types

The setup script supports 14 different GPU configurations including:
- Tesla T4, A10G, A100 (various configurations)
- H100 (80GB and 94GB variants)
- L40, L40S (single and multi-GPU)
- V100 and other enterprise GPUs

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   NFD Operator  │    │  GPU Operator    │    │ Custom Resources│
│                 │    │                  │    │                 │
│ • Node scanning │    │ • Driver mgmt    │    │ • NFD config    │
│ • Hardware      │    │ • Device plugin  │    │ • Cluster policy│
│   detection     │    │ • Monitoring     │    │ • Driver spec   │
│ • Node labeling │    │ • Validation     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │   GPU Worker Nodes  │
                    │                     │
                    │ • NVIDIA L40S GPUs  │
                    │ • Specialized taints│
                    │ • GPU-ready runtime │
                    │ • Monitoring agents │
                    └─────────────────────┘
```