# sentinel-db: Fraud Data Infrastructure Simulation (Local Focus with Cloud Foundation)

## 🌐 Project Overview

`sentinel-db` is a project designed to simulate key responsibilities of a Database Administrator or Cloud Engineer in a fintech or anti-fraud environment. It demonstrates the setup, management, and monitoring of a PostgreSQL database handling financial data, primarily in a local environment, with foundational steps taken towards cloud deployment.

**This project has successfully implemented:**
* Local provisioning and setup of a PostgreSQL database (`sentineldb`).
* A Python script to load the Bank Account Fraud (BAF) dataset from Kaggle into the local PostgreSQL database.
* A shell script for creating timestamped backups of the local PostgreSQL database.
* A Python script for monitoring the status (UP/DOWN) of the local PostgreSQL database, with logging.
* A GitHub Actions CI/CD pipeline (`ci.yml`) for automatically testing the database monitoring script against a temporary PostgreSQL service container.
* Initial Infrastructure as Code (IaC) using Terraform (`terraform/aws/`) to define basic AWS cloud infrastructure (VPC, RDS, S3). This has been tested locally with `terraform plan`, `apply`, and `destroy` cycles.

**Future goals and next phases for this project include:**
* Fully automating the deployment and management of the PostgreSQL database to Amazon RDS using Terraform through a dedicated CI/CD pipeline.
* Automating backup of the RDS database to Amazon S3 via scripting and potentially AWS Backup services.
* Implementing enhanced monitoring and alerting for the cloud database using AWS CloudWatch and AWS Lambda.

## 📊 Dataset: Bank Account Fraud (BAF)

This project uses the [Bank Account Fraud (BAF) dataset suite](https://www.kaggle.com/datasets/sgpjesus/bank-account-fraud-dataset-neurips-2022) — a large-scale, privacy-preserving, and realistic collection of tabular datasets designed for fraud detection in financial services.

### 🔍 Source & Citation
* **Dataset:** [Kaggle – Bank Account Fraud Dataset (BAF)](https://www.kaggle.com/datasets/sgpjesus/bank-account-fraud-dataset-neurips-2022)
* **Research Paper:** [Turning the Tables: Biased, Imbalanced, Dynamic Tabular Datasets for ML Evaluation (NeurIPS 2022)](https://nips.cc/virtual/2022/poster/55988)
* **Citation:**
    ```
    @article{jesusTurningTablesBiased2022,
      title={Turning the Tables: Biased, Imbalanced, Dynamic Tabular Datasets for ML Evaluation},
      author={Jesus, Sérgio and Pombal, José and Alves, Duarte and Cruz, André and Saleiro, Pedro and Ribeiro, Rita P. and Gama, João and Bizarro, Pedro},
      journal={Advances in Neural Information Processing Systems (NeurIPS)},
      year={2022}
    }
    ```

---

## 🛠️ Current Project Capabilities & Setup

### Implemented Features (Local Environment)
* **Data Ingestion:** Python script (`scripts/load_baf_data.py`) downloads the BAF dataset from Kaggle (streaming from ZIP) and loads a sample of 1,000 rows into a local PostgreSQL database.
* **Local Database Backup:** Shell script (`backup_db.sh`) performs a `pg_dump` of the local `sentineldb` database, creating timestamped backup files in a `backups/` directory.
* **Local Database Monitoring:** Python script (`scripts/db_monitor.py`) checks the connectivity of the local PostgreSQL database and logs its status (UP/DOWN) to `logs/db_status.log`, simulating an alert on failure.
* **CI/CD for Script Testing:** A GitHub Actions workflow (`.github/workflows/ci.yml`) automatically:
    * Sets up a Python environment.
    * Installs dependencies.
    * Spins up a PostgreSQL service container.
    * Runs the `db_monitor.py` script against this service container to validate its functionality.
    * Simulates the execution of the backup script.
* **Infrastructure as Code (IaC) - Foundational Work:** Terraform configurations (`terraform/aws/`) have been developed to define AWS resources (VPC, Subnets, RDS for PostgreSQL, S3 bucket, Security Groups). These configurations have been successfully tested for provisioning and de-provisioning these resources from a local development environment using `terraform plan`, `terraform apply`, and `terraform destroy`.
    *(Note: The CI/CD pipeline for automating Terraform deployments to AWS, `terraform-ci-cd.yml`, has been explored but is currently paused for further refinement and cost management.)*

### Database Access and Security (Local Setup)
Currently, the PostgreSQL database (`sentineldb`) for this project is configured to run locally on the developer's machine. All scripts (`load_baf_data.py`, `db_monitor.py`, `backup_db.sh`) are designed to connect to this local instance via `localhost`.

**Key Security Points for Local Setup:**
* **Credentials:** Database credentials (username, password, host, port, dbname) are managed via a `.env` file in the project root. This file is listed in `.gitignore` and should **never** be committed to version control. An `.env.example` file is provided as a template.
* **Remote Access:** Remote network access to this local PostgreSQL instance is **not configured by default.**
* **`.pgpass` (Optional):** For convenience with command-line tools like `psql` and `pg_dump`, users can configure a `~/.pgpass` file.
* **Firewall:** No specific `ufw` rules are applied by this project for the local setup.

For future deployment to a shared or cloud environment (like the planned AWS RDS setup), robust security measures including AWS Security Groups, IAM roles, and secure secret management (e.g., AWS Secrets Manager) will be implemented.
## 🚀 Local Setup and Usage

### Prerequisites
* Python 3.8+
* PostgreSQL server (e.g., version 14 or higher) installed and running locally.
* Git
* Kaggle API token (`kaggle.json` configured in `~/.kaggle/` or via environment variables).
* (For AWS/Terraform part) AWS CLI installed and configured with credentials, Terraform CLI installed.

### Installation & Configuration
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/JinyueXie/sentinel-db.git](https://github.com/JinyueXie/sentinel-db.git) # Replace with your repo URL if different
    cd sentinel-db
    ```
2.  **Set up a Python virtual environment (recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Configure Local PostgreSQL:**
    * Ensure your local PostgreSQL server is running.
    * Create a database (e.g., `sentineldb`) and a user (e.g., `postgres` or a dedicated user with privileges for `sentineldb`).
    * Ensure the user can connect to `sentineldb` via `localhost`.
5.  **Set up environment variables for local scripts:**
    * Copy `.env.example` to `.env`: `cp .env.example .env`
    * Edit `.env` and fill in your actual local database credentials.

### Running Local Scripts
* **Load Data into Local PostgreSQL:**
    ```bash
    python3 scripts/load_baf_data.py
    ```
* **Backup Local Database:**
    ```bash
    chmod +x backup_db.sh
    ./backup_db.sh
    ```
* **Monitor Local Database Status:**
    ```bash
    python3 scripts/db_monitor.py
    ```

### Working with Terraform for AWS (Local Manual Execution)
This section describes how to use the existing Terraform code to provision and de-provision AWS resources manually from your local machine. **Automated CI/CD for these Terraform operations is a future goal.**
1.  Navigate to the Terraform directory: `cd terraform/aws`
2.  Create `terraform.tfvars` with your `rds_password` (ensure this file is in `.gitignore`):
    ```
    rds_password = "YourChosenRDSPassword"
    # aws_region = "your-chosen-aws-region" # If different from default in variables.tf
    ```
3.  Initialize Terraform: `terraform init`
4.  Plan changes: `terraform plan` (Review the plan carefully)
5.  Apply changes (to create AWS resources): `terraform apply` (Type `yes` to confirm)
    * This will create resources in your AWS account and may incur costs.
6.  **IMPORTANT:** Destroy AWS resources after testing to avoid costs: `terraform destroy` (Type `yes` to confirm)

---

## ☁️ Future Cloud Architecture & CI/CD Vision (Roadmap)

The long-term vision for this project is to fully deploy and manage the infrastructure in AWS using Terraform, with a robust CI/CD pipeline automating these cloud operations.

*(The Mermaid diagram you had here is good to keep, or you can refine it as your vision evolves. I'm keeping the one from the previous version as it outlines the target state well.)*
```mermaid
graph TB
    subgraph "Local Development & CI (Current)"
        DevLaptop[Developer Laptop] -->|Git Push| GitHubRepo[GitHub Repository]
        GitHubRepo -->|Trigger| GHActionsCI[GitHub Actions CI - Local Python Script Tests]
        GHActionsCI -.-> ServiceDB[(PostgreSQL Service Container for CI)]
        DevLaptop -->|Terraform Plan/Apply/Destroy Locally| AWSResourcesLocalMgmt[AWS Resources (Manual Local Mgmt)]
    end

    subgraph "Future: AWS Cloud & CI/CD Automation"
        AWS[AWS Cloud]
        subgraph AWS
            S3Bucket[BAF CSV & DB Backups in S3 Bucket]
            Loader[EC2/Lambda Loader (Python)] 
            RDS[Amazon RDS for PostgreSQL]
            CW[CloudWatch Metrics & Logs]
            LambdaAlert[Lambda Alert Handler]
        end
        
        GitHubRepo -->|Trigger on main branch/PR| GHActionsTerraform[GitHub Actions CI/CD - Terraform]
        GHActionsTerraform -->|Terraform Plan & Apply/Destroy| RDS
        GHActionsTerraform -->|Terraform Plan & Apply/Destroy| S3Bucket
        GHActionsTerraform -->|Terraform Plan & Apply/Destroy| CW
        GHActionsTerraform -->|Terraform Plan & Apply/Destroy| LambdaAlert
        
        Loader --> RDS
        RDS --> CW
        CW -->|Alarm| LambdaAlert
        
        GHActionsCI -->|Future: Run Scripts Against Deployed| RDS 
    end

Amazon S3: For storing the raw BAF dataset and automated database backups.

EC2/Lambda Loader: Python script (adapted load_baf_data.py) to load data from S3 to RDS.

Amazon RDS for PostgreSQL: Managed PostgreSQL database service.

CloudWatch: For collecting metrics and logs from RDS. CloudWatch Alarms will trigger alerts.

AWS Lambda Alert Handler: Triggered by CloudWatch Alarms to send notifications.

Terraform: Infrastructure as Code (IaC) to define and provision all AWS resources.

GitHub Actions (Enhanced CI/CD for Cloud):

Validate Terraform code.

Automatically terraform plan on Pull Requests to main for infrastructure changes.

Controlled terraform apply (e.g., manual approval step or on merge to main) for deploying/updating cloud environments.

Easily triggerable terraform destroy for temporary/dev environments.

Run application scripts (db_monitor.py, backup_db.sh adapted for AWS) against the deployed AWS resources.

This cloud setup will provide a more scalable, resilient, and production-like environment for the `sentinel-db
