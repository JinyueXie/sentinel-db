# scripts/db_monitor.py
import psycopg2
import datetime
import os
from dotenv import load_dotenv

# --- Configuration ---
# Load environment variables from .env file located in the parent directory
# Assumes .env file is in the root of the project, and this script is in 'scripts/'
try:
    dotenv_path = os.path.join(os.path.dirname(__file__), '../.env')
    load_dotenv(dotenv_path=dotenv_path)
except Exception as e:
    print(f"Warning: Could not load .env file. Will rely on environment variables if set. Error: {e}")

# Database connection parameters (fetched from environment variables)
DB_NAME = os.getenv("PG_DBNAME", "sentineldb") # Default to sentineldb if not set
DB_USER = os.getenv("PG_USER", "postgres")     # Default to postgres if not set
DB_PASSWORD = os.getenv("PG_PASSWORD")         # No default, should be in .env
DB_HOST = os.getenv("PG_HOST", "localhost")    # Default to localhost
DB_PORT = os.getenv("PG_PORT", "5432")         # Default to 5432

LOG_DIR = "logs" # Assumes this script is run from the project root, or logs dir is in project root
LOG_FILE_PATH = os.path.join(LOG_DIR, "db_status.log")

# --- Helper Functions ---
def ensure_log_directory_exists():
    """Ensures the log directory exists. Creates it if it doesn't."""
    if not os.path.exists(LOG_DIR):
        try:
            os.makedirs(LOG_DIR)
            print(f"Log directory '{LOG_DIR}' created.")
        except OSError as e:
            print(f"Error: Could not create log directory '{LOG_DIR}'. {e}")
            # If log dir can't be created, we might not be able to log,
            # but we can still try to print status.
            return False
    return True

def log_status(status_message, is_critical_alert=False):
    """Writes the status message to the log file and prints it."""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted_log_message = f"{timestamp} | {status_message}\n"

    if ensure_log_directory_exists():
        try:
            with open(LOG_FILE_PATH, "a") as log_file: # "a" for append mode
                log_file.write(formatted_log_message)
        except IOError as e:
            print(f"Error: Could not write to log file '{LOG_FILE_PATH}'. {e}")
            # Still print the original status if logging fails
            print(f"Current Status (logging failed): {status_message}")
            return # Exit if logging failed

    print(status_message) # Also print to console

    if is_critical_alert:
        # In a real system, this would trigger an actual alert (email, PagerDuty, Slack, etc.)
        print(f"🚨 CRITICAL ALERT SIMULATED: {status_message} 🚨")
        # Example: send_alert_email("Database Down!", status_message)

# --- Main Monitoring Logic ---
def check_db_status():
    """Checks the PostgreSQL database status and logs it."""
    status = ""
    is_down = False

    # Check if essential environment variables are loaded
    if not DB_PASSWORD: # Password is crucial
        status = "❌ CONFIGURATION ERROR: PG_PASSWORD environment variable not found. Cannot check DB status."
        is_down = True # Treat as down if config is missing
        log_status(status, is_critical_alert=is_down)
        return

    try:
        # Attempt to connect to the database
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            connect_timeout=5 # Add a connection timeout (in seconds)
        )
        # If connection is successful, close it immediately. We just want to check accessibility.
        conn.close()
        status = f"✅ PostgreSQL is UP. Connected to '{DB_NAME}' on '{DB_HOST}:{DB_PORT}' as '{DB_USER}'."
        is_down = False
    except psycopg2.OperationalError as e:
        # This catches common errors like host not found, port not listening, auth failure
        status = f"❌ DB DOWN: OperationalError - {e}"
        is_down = True
    except Exception as e:
        # Catch any other unexpected exceptions during connection attempt
        status = f"❌ DB DOWN: An unexpected error occurred - {e}"
        is_down = True

    log_status(status, is_critical_alert=is_down)

if __name__ == "__main__":
    print(f"Running Database Monitor ({datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')})...")
    check_db_status()
    print("Monitoring check complete.")
