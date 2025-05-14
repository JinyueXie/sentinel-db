# sentinel-db

## 🌐 Project Overview

**sentinel-db** is a cloud-native fraud data infrastructure project designed to simulate a real-world Cloud Database Administrator's responsibilities within a fintech or anti-fraud environment.

This project focuses on:
- Secure provisioning of PostgreSQL databases on **Amazon RDS**
- Fully automated **backup**, **monitoring**, and **alerting** pipelines
- DevOps integration with **GitHub Actions** and optional **Terraform**
- Simulated operational workflows like auto-locking high-risk accounts or expanding storage
- Deep visibility into metrics and logs using AWS-native and local tools

---
## 📊 Dataset: Bank Account Fraud (BAF)

This project uses the **Bank Account Fraud (BAF)** dataset suite — a large-scale, privacy-preserving, and realistic collection of tabular datasets designed for fraud detection in financial services.

---

### 🔍 Source & Citation

- 📥 **Dataset**: [Kaggle – Bank Account Fraud Dataset (BAF)](https://www.kaggle.com/datasets/sgpjesus/bank-account-fraud-dataset-neurips-2022)  
- 📄 **Research Paper**: [Turning the Tables: Biased, Imbalanced, Dynamic Tabular Datasets for ML Evaluation (NeurIPS 2022)](https://arxiv.org/abs/2206.03872)  
- 📑 **Citation**:

```bibtex
@article{jesusTurningTablesBiased2022,
  title={Turning the Tables: Biased, Imbalanced, Dynamic Tabular Datasets for ML Evaluation},
  author={Jesus, Sérgio and Pombal, José and Alves, Duarte and Cruz, André and Saleiro, Pedro and Ribeiro, Rita P. and Gama, João and Bizarro, Pedro},
  journal={Advances in Neural Information Processing Systems (NeurIPS)},
  year={2022}
}

---

## 🏗️ System Architecture

```mermaid
graph TB
    subgraph AWS Cloud
        A[BAF CSV in S3 (optional)] --> B[EC2 Loader (Python)]
        B --> C[(Amazon RDS - PostgreSQL)]
        C --> D[CloudWatch Metrics + Logs]
        D --> E[Lambda Alarm Handler (optional)]
    end
    F[Developer Laptop] -->|Git Push| G[GitHub Actions CI/CD]
    G -->|Terraform Plan| C
    G -->|Run Backup Tests| D
# sentinel-db
Cloud fraud detection system using the BAF dataset and PostgreSQL
