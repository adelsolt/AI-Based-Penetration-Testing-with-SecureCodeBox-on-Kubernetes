# README: Deploying a Multi-Agent Architecture for Kubernetes Penetration Testing

This guide explains how to deploy a **multi-agent Letta-based penetration testing solution** in Kubernetes, using the **Deepseek R1-Distill-Qwen-8B** model as the foundation for each agent’s capabilities. The architecture comprises the following agents:

1. **Orchestrator Agent**  
2. **Kubernetes Infrastructure Agent**  
3. **Vulnerability Scanning Agent**  
4. **Analysis & Exploitation Agent**

Additionally, you will provision **MinIO** (or an equivalent S3-compatible service) to store artifacts, logs, and scan results. The instructions below outline recommended pod structures, resources, and setup steps.

---

## 1. Overview

Each agent runs as a separate container, typically in its own **Kubernetes Deployment**. The Orchestrator serves as the entry point and coordinator of tasks among the other agents. The Kubernetes Infrastructure Agent has the necessary privileges to interact with cluster resources, while the Vulnerability Scanning Agent handles all scanning activities. Finally, the Analysis & Exploitation Agent processes scan results and executes exploits.

Here’s a quick summary of how many pods you might start with for each component:

1. **Orchestrator Deployment**: 1 pod (scale if needed)  
2. **Kubernetes Infrastructure Agent Deployment**: 1–2 pods  
3. **Vulnerability Scanning Agent Deployment**: 1 pod (scale for intensive scans)  
4. **Analysis & Exploitation Agent Deployment**: 1 pod (scale if many concurrent analyses)  
5. **MinIO Deployment**: 1 pod (or more for redundancy, e.g., StatefulSet)

---

## 2. Architecture Diagram

### Mermaid Diagram

```mermaid
flowchart TD
    A[User Request]
    B[Orchestrator Agent]
    C[K8s Infrastructure Agent]
    D[Vulnerability Scanning Agent]
    E[Analysis & Exploitation Agent]
    F[MinIO (Artifact Storage)]

    A --> B
    B --> C
    B --> D
    D --> E
    E --> B
    D --> F
    E --> F
    B --> A
