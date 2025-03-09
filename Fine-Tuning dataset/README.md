# Cybersecurity Penetration Testing Dataset

This repository contains a comprehensive dataset for fine-tuning AI models in cybersecurity, with a focus on penetration testing. The primary model used is Deepseek-R1-Distill-Qwen-8B.

## Overview
The dataset is designed to train an AI model to conduct automated penetration testing on Kubernetes target systems using the OWASP SecureCodeBox framework.

## Model Capabilities
The trained model will be able to:

- Identify vulnerabilities and exploit techniques in target applications
- Generate scan CRDs based on YAML templates 
- Retrieve and analyze SecureCodeBox scan results
- Make informed decisions for exploiting target applications based on scan results

## Target Environment
- Kubernetes clusters
- OWASP SecureCodeBox framework integration
- Focus on cloud-native security testing

## Model Information

### Selected Model
- Deepseek-R1-Distill-Qwen-8B
- Chosen to comply with Lightning AI platform limitations while maintaining strong performance
- Fine-tuning will be conducted on Lightning AI cloud infrastructure for optimal training capabilities

## Dataset Components

### 1. ptaas-tool Dataset
**Source:** ptaas-tool/dataset

Contains multiple versions of penetration testing scenarios:
- v0.1 (simple): 500 entries, 9 attacks, 112 vulnerabilities
- v0.2 (complex): 1000 entries, 9 attacks, 112 vulnerabilities
- v0.3 (random): 1000 entries, 9 attacks, 112 vulnerabilities
- v0.4 (normal): 1000 entries, 8 attacks, 112 vulnerabilities

**Usage:** Training AI models for vulnerability identification and attack pattern assessment

### 2. HackMentor Dataset
**Source:** tmylla/HackMentor

Contents:
- IIO (Instruction, Input, Output) data
- Cybersecurity-focused conversations

**Usage:** Improving model understanding of cybersecurity concepts and terminology

### 3. Custom SecureCodeBox (SCB) Dataset
Contents:
- Custom Resource Definitions (CRDs) from Kubernetes environments
- SecureCodeBox scan results and findings
- AI-generated datasets from SCB scans

**Usage:** Real-world vulnerability examples from cloud-native environments

## Data Preparation Guidelines

### Training Data Components
- Vulnerability descriptions and exploit techniques from ptaas-tool dataset
- Security assessment reports and penetration testing methodologies from HackMentor
- SecureCodeBox scan CRD templates and manipulation
- Scan findings retrieval and analysis patterns
- Attack pattern mapping and vulnerability correlation
- Cloud-native security testing scenarios
- Kubernetes resource manipulation examples
- Real-world scan result interpretation

### Data Format Requirements
- JSONL file format
- Includes instructions/prompts
- Expected outputs/completions
- Relevant context

### Quality Control
- Proper labeling
- Duplicate removal
- Technical accuracy validation
- Scenario diversity

## Fine-Tuning Process
1. Data preprocessing
2. Model configuration
3. Training parameters optimization
4. Validation and testing
5. Model evaluation


## Acknowledgments
Thanks to:
- ptaas-tool dataset creators
- HackMentor dataset team
- SecureCodeBox community

