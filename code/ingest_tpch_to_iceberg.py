import sys
import subprocess
from pathlib import Path
from typing import Tuple
import time


def run_command(cmd: list, description: str = "") -> Tuple[int, str, str]:
    """Execute shell command and capture output."""
    if description:
        print(f"> {description}")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,  # 5 minute timeout for uploads
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out (5 minutes)"
    except Exception as e:
        return -1, "", str(e)


def check_docker_service(service_name: str) -> bool:
    """Check if Docker service is running."""
    cmd = ["docker", "ps", "--filter", f"name={service_name}", "--format", "{{.Names}}"]
    returncode, stdout, _ = run_command(cmd)
    
    if returncode == 0 and service_name in stdout:
        return True
    return False


def verify_prerequisites() -> bool:
    """Verify all required services and files exist."""
    print("\n")
    print("Verifying Prerequisites")
    
    errors = []
    
    # Check Docker services
    services = ["minio", "hive-metastore", "trino"]
    for service in services:
        if check_docker_service(service):
            print(f"{service:20} running")
        else:
            print(f"{service:20} NOT running")
            errors.append(f"{service} is not running")
    
    # Check CSV files
    csv_dir = Path(__file__).parent.parent / "data" / "csv"
    csv_files = list(csv_dir.glob("*.csv"))
    
    if csv_files:
        print(f"{len(csv_files):20} CSV file(s) found in data/csv/")
    else:
        print(f"No CSV files found in data/csv/")
        errors.append("CSV files not found in data/csv/")
    
    # Check Python script dependencies
    try:
        import minio
        print(f"{'minio':20} module available")
    except ImportError:
        errors.append("minio package not installed")
    
    if errors:
        print(f"\nPrerequisites not met:")
        for err in errors:
            print(f"  - {err}")
        return False
    
    return True


def upload_csv_files() -> bool:
    """Execute CSV upload to MinIO."""
    code_dir = Path(__file__).parent
    upload_script = code_dir / "upload_csv_to_lakehouse.py"
    
    if not upload_script.exists():
        print(f"Upload script not found: {upload_script}")
        return False
    
    returncode, stdout, stderr = run_command(
        ["python", str(upload_script)],
        "> Step 1: Upload CSV files to MinIO"
    )
    
    print(stdout)
    
    if returncode != 0:
        print(f"CSV upload failed:\n{stderr}")
        return False
    
    print("CSV upload completed successfully")
    return True


def execute_iceberg_schema_sql() -> bool:
    """Execute Iceberg schema creation via Trino."""
    code_dir = Path(__file__).parent
    sql_script = code_dir / "tpch_iceberg_schema.sql"
    
    if not sql_script.exists():
        print(f"SQL script not found: {sql_script}")
        return False
    
    print("\n")
    print("> Step 2: Create external schemas and Iceberg tables")
    
    # Read SQL script
    with open(sql_script, 'r') as f:
        sql_content = f.read()
    
    # Execute via Trino
    # Note: We need to split the SQL into meaningful chunks to execute
    try:
        # Import here to avoid import error if dependencies missing
        from trino.dbapi import connect
        
        print("Connecting to Trino at localhost:8080")
        conn = connect(
            host="localhost",
            port=8080,
            user="trino",
            catalog="hive",
            schema="default",
        )
        
        cursor = conn.cursor()
        print("Connected to Trino\n")
        
        # Split SQL by semicolon and execute statements
        statements = [s.strip() for s in sql_content.split(';') if s.strip()]
        
        statement_groups = {
            "Schema Creation": statements[0:1],
            "External Table Creation": statements[1:9],
            "Iceberg Table Creation": statements[9:17],
            "Data Ingestion": statements[17:25],
            "Validation": statements[25:26] if len(statements) > 25 else [],
        }
        
        for group_name, group_statements in statement_groups.items():
            if not group_statements:
                continue
            
            print(f"\n{group_name}:")
            for i, stmt in enumerate(group_statements, 1):
                try:
                    print(f"  [{i}/{len(group_statements)}] {stmt[:60]}...")
                    cursor.execute(stmt)
                    
                    # Fetch and display results if available
                    try:
                        results = cursor.fetchall()
                        if results and group_name == "Validation":
                            for row in results:
                                print(f"       {row[0]:20} {row[1]:>10}")
                    except:
                        pass  # Statement returned no results
                    
                    print(f"Success")
                    
                except Exception as e:
                    # Some statements may fail (IF NOT EXISTS), continue
                    error_msg = str(e)
                    if "already exists" in error_msg.lower() or "if not exists" in error_msg.lower():
                        print(f"Already exists (skipped)")
                    else:
                        print(f"Error: {error_msg[:50]}")
        
        cursor.close()
        conn.close()
        
        print("\nIceberg schema and tables created successfully")
        return True
        
    except ImportError:
        print("trino package not installed")
        print("Install with: pip install trino")
        return False
    except Exception as e:
        print(f"Trino connection failed: {e}")
        return False


def validate_ingestion() -> bool:
    """Validate that data was ingested correctly."""
    print("\n")
    print("> Step 3: Validate data ingestion")
    
    try:
        from trino.dbapi import connect
        
        conn = connect(
            host="localhost",
            port=8080,
            user="trino",
            catalog="iceberg",
            schema="tpch",
        )
        
        cursor = conn.cursor()
        
        # Check if tables exist and have data
        tables = ["customer", "lineitem", "nation", "orders", "part", "partsupp", "region", "supplier"]
        
        print("\nTable row counts:")
        total_rows = 0
        
        for table in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) as count FROM iceberg.tpch.{table}")
                result = cursor.fetchone()
                count = result[0] if result else 0
                total_rows += count
                
                status = "Success" if count > 0 else "Empty"
                print(f"{status} {table:15} {count:>15,} rows")
            except Exception as e:
                print(f"{table:15} Error: {str(e)[:40]}")
        
        cursor.close()
        conn.close()
        
        if total_rows > 0:
            print(f"\nTotal rows ingested: {total_rows:,}")
            return True
        else:
            print(f"\nNo data found in tables")
            return False
            
    except Exception as e:
        print(f"Validation failed: {e}")
        return False


def summary(success: bool) -> None:
    """Print execution summary."""
    print("\n")
    
    if success:
        print("TPC-H Iceberg Ingestion Complete!")
    else:
        print("TPC-H Iceberg Ingestion Failed")


def main():
    """Main orchestration."""
    print("\n")
    print("TPC-H Iceberg Data Ingestion Orchestrator")
    
    # Verify prerequisites
    if not verify_prerequisites():
        print("\nPrerequisites not met.")
        sys.exit(1)
    
    # Step 1: Upload CSV
    if not upload_csv_files():
        summary(False)
        sys.exit(1)
    
    time.sleep(2)  # Brief pause
    
    # Step 2: Create schemas and tables
    if not execute_iceberg_schema_sql():
        summary(False)
        sys.exit(1)
    
    # Step 3: Validate
    if not validate_ingestion():
        print("\nValidation incomplete, but ingestion may have succeeded")
        summary(False)
        sys.exit(1)
    
    # Success
    summary(True)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)
