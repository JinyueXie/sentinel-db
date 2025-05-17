import os
import pandas as pd
import zipfile
import io # Required for TextIOWrapper
import kaggle
import psycopg2
from psycopg2.extras import execute_batch
from dotenv import load_dotenv
import shutil # For cleaning up

# Load environment variables
dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
load_dotenv(dotenv_path=dotenv_path)

# --- Ensure tmp_baf directory exists ---
# The Kaggle API might need it, or we'll use it for the zip.
# If shutil.rmtree is used later, we need to ensure it exists before downloading.
tmp_dir = "tmp_baf"
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)

# --- Kaggle dataset details ---
dataset_slug = 'sgpjesus/bank-account-fraud-dataset-neurips-2022'
# The downloaded zip file will likely be named after the dataset slug
zip_file_name = dataset_slug.split('/')[-1] + '.zip' # e.g., 'bank-account-fraud-dataset-neurips-2022.zip'
zip_file_path = os.path.join(tmp_dir, zip_file_name)

print("📦 Authenticating with Kaggle API...")
kaggle.api.authenticate()

print(f"📦 Downloading dataset {dataset_slug} as a ZIP file to {zip_file_path}...")
# Download WITHOUT unzipping to keep Base.csv inside the zip initially
kaggle.api.dataset_download_files(dataset_slug, path=tmp_dir, unzip=False, force=True) # force=True to overwrite if exists

print(f"📖 Reading 'Base.csv' from {zip_file_path} and sampling 1,000 rows...")
df = None
try:
    with zipfile.ZipFile(zip_file_path, 'r') as zf:
        # Open Base.csv from within the zip file as a stream
        with zf.open('Base.csv', 'r') as csv_file_stream:
            # Wrap the binary stream in a TextIOWrapper to make it readable by pandas as text
            text_stream = io.TextIOWrapper(csv_file_stream, encoding='utf-8') # Assuming UTF-8 encoding
            # Read only the first 1000 rows from the stream
            df = pd.read_csv(text_stream, nrows=1000)
    print("✅ Successfully read 1,000 rows from Base.csv in the ZIP.")
except FileNotFoundError:
    print(f"❌ Error: {zip_file_path} not found. Download might have failed or naming is different.")
    # List files in tmp_dir to help debug
    if os.path.exists(tmp_dir):
        print(f"Files in {tmp_dir}: {os.listdir(tmp_dir)}")
    exit()
except KeyError:
    print(f"❌ Error: 'Base.csv' not found within the zip file {zip_file_path}.")
    # You can list files in zip to debug:
    # with zipfile.ZipFile(zip_file_path, 'r') as zf:
    # print(f"Files in zip: {zf.namelist()}")
    exit()
except Exception as e:
    print(f"❌ An error occurred while reading the CSV from ZIP: {e}")
    exit()

if df is None:
    print("❌ DataFrame could not be loaded. Exiting.")
    exit()

# ✅ Step 3: Select useful columns only (remains the same)
selected_cols = [
    'income', 'name_email_similarity', 'prev_address_months_count',
    'current_address_months_count', 'customer_age', 'days_since_request',
    'intended_balcon_amount', 'zip_count_4w', 'velocity_6h',
    'velocity_24h', 'fraud_bool'
]
df = df[selected_cols]

# ✅ Step 4: Connect to PostgreSQL (Corrected)
print("🐘 Connecting to PostgreSQL...")
conn = None # Initialize conn to None for robust finally block
try:
    conn = psycopg2.connect(
        dbname=os.getenv("PG_DBNAME"),
        user=os.getenv("PG_USER"),
        password=os.getenv("PG_PASSWORD"),
        host=os.getenv("PG_HOST"),
        port=int(os.getenv("PG_PORT"))
    )
    cursor = conn.cursor()
    print("✅ Successfully connected to PostgreSQL.")

    # Convert DataFrame rows to list of tuples for execute_batch
    rows = [
        (
            row['income'], row['name_email_similarity'], row['prev_address_months_count'],
            row['current_address_months_count'], row['customer_age'], row['days_since_request'],
            row['intended_balcon_amount'], row['zip_count_4w'], row['velocity_6h'],
            row['velocity_24h'], bool(row['fraud_bool'])
        )
        for _, row in df.iterrows()
    ]

    # ✅ Step 5: Insert into PostgreSQL (remains the same)
    print(f"✒️ Inserting {len(rows)} rows into PostgreSQL table 'baf_fraud'...")
    execute_batch(cursor, """
        INSERT INTO baf_fraud (
            income, name_email_similarity, prev_address_months_count,
            current_address_months_count, customer_age, days_since_request,
            intended_balcon_amount, zip_count_4w, velocity_6h,
            velocity_24h, fraud_bool
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, rows)

    conn.commit()
    cursor.close()
    print(f"✅ {len(rows)} rows from Kaggle Base.csv loaded into PostgreSQL!")

except psycopg2.Error as e:
    print(f"❌ PostgreSQL Error: {e}")
    if conn:
        conn.rollback() # Rollback any partial transaction
except Exception as e:
    print(f"❌ An unexpected error occurred: {e}")
    if conn:
        conn.rollback()
finally:
    if conn:
        conn.close()
        print("ℹ️ PostgreSQL connection closed.")

# ✅ Optional: clean up temp files
try:
    if os.path.exists(tmp_dir):
        print(f"🧹 Cleaning up temporary directory: {tmp_dir}...")
        shutil.rmtree(tmp_dir)
        print("✅ Cleanup complete.")
except Exception as e:
    print(f"⚠️ Error during cleanup: {e}")
