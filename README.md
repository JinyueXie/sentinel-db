# sentinel-db: Fraud Data Infrastructure Simulation

## 🌐 Project Overview

`sentinel-db` is a project designed to simulate key responsibilities of a Database Administrator or Cloud Engineer in a fintech or anti-fraud environment. It demonstrates the setup, management, and monitoring of a PostgreSQL database handling financial data.

**This project currently focuses on and has implemented:**
* Local provisioning and setup of a PostgreSQL database (`sentineldb`).
* A Python script to load the Bank Account Fraud (BAF) dataset from Kaggle into the local PostgreSQL database.
* A shell script for creating timestamped backups of the local PostgreSQL database.
* A Python script for monitoring the status (UP/DOWN) of the local PostgreSQL database, with logging.
* A GitHub Actions CI/CD pipeline for automatically testing the database monitoring script against a service container.
* Initial setup of Terraform configurations for provisioning basic AWS infrastructure (VPC, RDS, S3) locally (plan stage).

**Future goals include:**
* Full deployment of the PostgreSQL database to Amazon RDS using Terraform.
* Automated backup of the RDS database to Amazon S3.
* Enhanced monitoring and alerting using AWS CloudWatch and AWS Lambda.
* Integration of Terraform `apply` and `destroy` into the CI/CD pipeline for managing AWS resources.

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

### Implemented Features
* **Data Ingestion:** Python script (`scripts/load_baf_data.py`) downloads the BAF dataset from Kaggle (streaming from ZIP) and loads a sample into a local PostgreSQL database.
* **Local Database Backup:** Shell script (`backup_db.sh`) performs a `pg_dump` of the local `sentineldb` database, creating timestamped backup files in a `backups/` directory.
* **Local Database Monitoring:** Python script (`scripts/db_monitor.py`) checks the connectivity of the local PostgreSQL database and logs its status (UP/DOWN) to `logs/db_status.log`, simulating an alert on failure.
* **CI/CD with GitHub Actions:** A workflow (`.github/workflows/ci.yml`) automatically:
    * Sets up a Python environment.
    * Installs dependencies.
    * Spins up a PostgreSQL service container.
    * Runs the `db_monitor.py` script against the service container to test its functionality.
    * Simulates the execution of the backup script.
* **Infrastructure as Code (IaC) - Initial Phase:** Terraform configurations (`terraform/aws/`) have been created to define basic AWS infrastructure (VPC, Subnets, RDS, S3, Security Groups). These have been tested locally using `terraform plan`.

### Database Access and Security (Local Setup)
Currently, the PostgreSQL database (`sentineldb`) for this project is configured to run locally on the developer's machine. All scripts (`load_baf_data.py`, `db_monitor.py`, `backup_db.sh`) are designed to connect to this local instance via `localhost`.

**Key Security Points for Local Setup:**
* **Credentials:** Database credentials (username, password, host, port, dbname) are managed via a `.env` file in the project root. This file should be listed in `.gitignore` and **never** committed to version control. An `.env.example` file should be provided as a template.
* **Remote Access:** Remote network access to this local PostgreSQL instance is **not configured by default** and is generally not recommended for a local development database without proper network security measures (firewalls, VPNs, etc.).
* **`.pgpass` (Optional):** For convenience with command-line tools like `psql` and `pg_dump`, users can configure a `~/.pgpass` file.
* **Firewall:** No specific `ufw` rules are applied by this project for the local setup, as connections are typically via `localhost`.

For any deployment to a shared or cloud environment (like the planned AWS RDS setup), robust security measures including AWS Security Groups, IAM roles, and secure secret management (e.g., AWS Secrets Manager) would be implemented.


## 🚀 Local Setup and Usage

### Prerequisites
* Python 3.8+
* PostgreSQL server (e.g., version 14 or higher) installed and running locally.
* Git
* Kaggle API token (`kaggle.json` configured in `~/.kaggle/` or via environment variables).
* (For AWS/Terraform part) AWS CLI installed and configured, Terraform installed.

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
    * Edit `.env` and fill in your actual local database credentials:
        ```dotenv
        PG_DBNAME=sentineldb
        PG_USER=your_local_db_user
        PG_PASSWORD=your_local_db_password
        PG_HOST=localhost
        PG_PORT=5432
        # KAGGLE_USERNAME=your_kaggle_username (if not using kaggle.json)
        # KAGGLE_KEY=your_kaggle_key (if not using kaggle.json)
        ```

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
    (Backups are stored in the `backups/` directory)
* **Monitor Local Database Status:**
    ```bash
    python3 scripts/db_monitor.py
    ```
    (Status is logged to `logs/db_status.log` and printed to console)

### Working with Terraform for AWS (Local Execution)
1.  Navigate to the Terraform directory: `cd terraform/aws`
2.  Create `terraform.tfvars` with your `rds_password` (ensure this file is in `.gitignore`):
    ```
    rds_password = "YourChosenRDSPassword"
    ```
3.  Initialize Terraform: `terraform init`
4.  Plan changes: `terraform plan`
5.  Apply changes (to create AWS resources): `terraform apply` (Type `yes` to confirm)
6.  **IMPORTANT:** Destroy AWS resources after testing to avoid costs: `terraform destroy` (Type `yes` to confirm)

---
