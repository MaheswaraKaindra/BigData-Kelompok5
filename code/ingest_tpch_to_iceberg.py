import sys
import subprocess
from pathlib import Path
from typing import Tuple
import time


MINIO_ENDPOINT = "localhost:9005"


def run_command(cmd: list, description: str = "") -> Tuple[int, str, str]:
    """Execute shell command and capture output."""
    if description:
        print(f"> {description}")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300,
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out (5 minutes)"
    except Exception as e:
        return -1, "", str(e)


def python_cmd() -> str:
    """Return current Python executable to keep subprocess env consistent."""
    return sys.executable or "python"


def check_docker_service(service_name: str) -> bool:
    """Check if Docker service is running."""
    cmd = ["docker", "ps", "--filter", f"name={service_name}", "--format", "{{.Names}}"]
    returncode, stdout, _ = run_command(cmd)
    
    if returncode == 0 and service_name in stdout:
        return True
    return False


def verify_prerequisites() -> bool:
    """Verify all required services and files exist."""
    print("\n" + "="*70)
    print("VERIFYING PREREQUISITES")
    print("="*70)
    
    errors = []
    
    # Check Docker services
    services = ["minio", "hive-metastore", "trino"]
    for service in services:
        if check_docker_service(service):
            print(f"  {service:20} running")
        else:
            print(f"  {service:20} NOT running")
            errors.append(f"{service} is not running")
    
    # Check CSV files
    csv_dir = Path(__file__).parent.parent / "data" / "csv"
    csv_files = list(csv_dir.glob("*.csv"))
    
    if csv_files:
        print(f"  {'CSV files':20} {len(csv_files)} file(s) found")
    else:
        print(f"  {'CSV files':20} NOT found")
        errors.append("CSV files not found in data/csv/")
    
    # Check Python script dependencies
    try:
        import minio
        print(f"  {'minio':20} module available")
    except ImportError:
        errors.append("minio package not installed")
    
    if errors:
        print(f"\nErrors:")
        for err in errors:
            print(f"  - {err}")
        return False
    
    print("\nAll prerequisites verified\n")
    return True


def upload_csv_files() -> bool:
    """Execute CSV upload to MinIO."""
    code_dir = Path(__file__).parent
    upload_script = code_dir / "upload_csv_to_lakehouse.py"
    
    if not upload_script.exists():
        print(f"Error: Upload script not found: {upload_script}")
        return False
    
    print("\n" + "="*70)
    print("STEP 1: UPLOAD CSV FILES TO MINIO")
    print("="*70)
    
    returncode, stdout, stderr = run_command([python_cmd(), str(upload_script)])
    
    print(stdout)
    
    if returncode != 0:
        print(f"Error: CSV upload failed")
        print(f"Details: {stderr}")
        return False
    
    print("CSV upload completed successfully\n")
    return True


def cleanup_iceberg_locations() -> bool:
    """Remove existing Iceberg table data so fixed locations can be reused safely."""
    try:
        from minio import Minio
    except ImportError:
        print("Error: minio package not installed")
        return False

    print("\n" + "="*70)
    print("STEP 1B: CLEANUP PREVIOUS ICEBERG TABLE LOCATIONS")
    print("="*70)

    client = Minio(
        endpoint=MINIO_ENDPOINT,
        access_key="admin",
        secret_key="admin123",
        secure=False,
    )

    bucket_name = "iceberg"
    table_prefixes = [
        "tpch/customer/",
        "tpch/lineitem/",
        "tpch/nation/",
        "tpch/orders/",
        "tpch/part/",
        "tpch/partsupp/",
        "tpch/region/",
        "tpch/supplier/",
    ]

    try:
        if not client.bucket_exists(bucket_name):
            print(f"Bucket '{bucket_name}' not found (skipping cleanup)")
            return True

        removed_objects = 0
        for prefix in table_prefixes:
            try:
                # List all objects with this prefix
                object_names = []
                for obj in client.list_objects(bucket_name, prefix=prefix, recursive=True):
                    object_names.append(obj.object_name)
                
                if not object_names:
                    continue

                # Remove objects (skip error handling to avoid toxml issue)
                try:
                    client.remove_objects(bucket_name, object_names)
                    removed_objects += len(object_names)
                    print(f"  Removed {len(object_names)} object(s) from {prefix}")
                except Exception as remove_error:
                    print(f"  Warning: Error removing objects from {prefix}: {remove_error}")
                    
            except Exception as prefix_error:
                print(f"  Warning: Could not clean prefix {prefix}: {prefix_error}")
                continue

        if removed_objects == 0:
            print("  No existing Iceberg objects found")
        else:
            print(f"  Total cleaned: {removed_objects} object(s)")

        print("Iceberg cleanup completed\n")
        return True
    except Exception as e:
        print(f"Error: Iceberg cleanup failed: {e}")
        return False


def execute_iceberg_schema_sql() -> bool:
    """Execute Iceberg schema creation via Trino."""
    code_dir = Path(__file__).parent
    sql_script = code_dir / "tpch_iceberg_schema.sql"
    
    if not sql_script.exists():
        print(f"Error: SQL script not found: {sql_script}")
        return False
    
    print("\n" + "="*70)
    print("STEP 2: CREATE EXTERNAL SCHEMAS AND ICEBERG TABLES")
    print("="*70)
    
    # Read SQL script
    with open(sql_script, 'r') as f:
        sql_content = f.read()
    
    # Execute via Trino
    try:
        from trino.dbapi import connect
        
        print("Connecting to Trino at localhost:8080")
        print("Waiting for Trino to be fully ready...")
        
        # Wait for Trino to be ready with retry logic
        max_retries = 30
        retry_count = 0
        conn = None
        
        while retry_count < max_retries and conn is None:
            try:
                conn = connect(
                    host="localhost",
                    port=8080,
                    user="trino",
                    catalog="hive",
                    schema="default",
                    request_timeout=600,
                )
                
                # Test connection with simple query
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                cursor.close()
                
                print("Connected to Trino")
                break
                
            except Exception as e:
                error_msg = str(e)
                if "SERVER_STARTING_UP" in error_msg or "Connection refused" in error_msg:
                    retry_count += 1
                    if retry_count < max_retries:
                        print(f"  Trino still starting... retry {retry_count}/{max_retries - 1}")
                        time.sleep(2)
                    else:
                        raise Exception(f"Trino failed to start after {max_retries * 2} seconds")
                else:
                    raise
        
        if conn is None:
            raise Exception("Failed to connect to Trino")
        
        cursor = conn.cursor()
        
        statement_groups = {
            "Schema Creation": [],
            "External Table Creation": [],
            "Iceberg Table Creation": [],
            "Data Ingestion": [],
            "Validation": []
        }
        
        raw_statements = sql_content.split(';')
        
        for raw_stmt in raw_statements:
            stmt_stripped = raw_stmt.strip()
            if not stmt_stripped:
                continue
                
            # 1. DROP TABLE
            if "DROP TABLE" in stmt_stripped:
                statement_groups["Iceberg Table Creation"].append(stmt_stripped)
            
            # 2. Schema Creation
            elif "CREATE SCHEMA" in stmt_stripped:
                statement_groups["Schema Creation"].append(stmt_stripped)
            
            # 3. External Table Hive
            elif "hive.tpch_external" in stmt_stripped and "CREATE TABLE" in stmt_stripped:
                statement_groups["External Table Creation"].append(stmt_stripped)
            
            # 4. Create Table Iceberg
            elif "iceberg.tpch" in stmt_stripped and "CREATE TABLE" in stmt_stripped:
                statement_groups["Iceberg Table Creation"].append(stmt_stripped)
            
            # 5. Ingestion
            elif "INSERT INTO" in stmt_stripped:
                statement_groups["Data Ingestion"].append(stmt_stripped)
            
            # 6. Validation
            elif "UNION ALL" in stmt_stripped or "table_name, COUNT(*)" in stmt_stripped:
                statement_groups["Validation"].append(stmt_stripped)
        
        for group_name, group_statements in statement_groups.items():
            if not group_statements:
                continue
            
            print(f"\n{group_name}:")
            success_count = 0
            for i, stmt in enumerate(group_statements, 1):
                max_retries = 3
                retry_count = 0
                success = False
                
                while retry_count < max_retries and not success:
                    try:
                        short_stmt = stmt[:50].replace('\n', ' ')
                        cursor.execute(stmt)
                        
                        try:
                            results = cursor.fetchall()
                            if results and group_name == "Validation":
                                for row in results:
                                    print(f"  {row[0]:20} {row[1]:>15} rows")
                        except:
                            pass
                        
                        success_count += 1
                        success = True
                        
                        # delay after INSERT statements
                        if group_name == "Data Ingestion":
                            time.sleep(2)
                        
                    except Exception as e:
                        error_msg = str(e)
                        if "already exists" in error_msg.lower() or "if not exists" in error_msg.lower():
                            success_count += 1
                            success = True
                        elif "too_many_open" in error_msg.lower() and retry_count < max_retries - 1:
                            print(f"  [{i}] Retry {retry_count + 1}/{max_retries - 1}: {error_msg[:40]}")
                            retry_count += 1
                            time.sleep(5)
                        else:
                            print(f"  [{i}] Error: {error_msg[:60]}")
                            break
            
            print(f"  {success_count}/{len(group_statements)} statements executed")
        
        cursor.close()
        conn.close()
        
        print("\nSchema and tables created successfully\n")
        return True
        
    except ImportError:
        print("Error: trino package not installed")
        print("Install with: pip install trino")
        return False
    except Exception as e:
        print(f"Error: Trino connection failed: {e}")
        return False


def validate_ingestion() -> bool:
    """Validate that data was ingested correctly."""
    print("\n" + "="*70)
    print("STEP 3: VALIDATE DATA INGESTION")
    print("="*70)
    
    try:
        from trino.dbapi import connect
        
        # Wait for connection with retry
        print("Connecting to Trino for validation...")
        max_retries = 10
        retry_count = 0
        conn = None
        
        while retry_count < max_retries and conn is None:
            try:
                conn = connect(
                    host="localhost",
                    port=8080,
                    user="trino",
                    catalog="iceberg",
                    schema="tpch",
                    request_timeout=600,
                )
                
                # Test connection
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                cursor.close()
                break
                
            except Exception as e:
                error_msg = str(e)
                if "SERVER_STARTING_UP" in error_msg or "Connection refused" in error_msg:
                    retry_count += 1
                    if retry_count < max_retries:
                        time.sleep(2)
                    else:
                        raise
                else:
                    raise
        
        if conn is None:
            raise Exception("Failed to connect to Trino")
        
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
                
                status = "OK" if count > 0 else "EMPTY"
                print(f"  {table:15} {count:>15,} rows  [{status}]")
            except Exception as e:
                print(f"  {table:15} Error: {str(e)[:40]}")
        
        cursor.close()
        conn.close()
        
        print(f"\nTotal rows ingested: {total_rows:,}")
        return True
        
    except Exception as e:
        print(f"Error: Validation failed: {e}")
        return False



def summary(success: bool) -> None:
    """Print execution summary."""
    print("\n" + "="*70)
    
    if success:
        print("STATUS: TPC-H ICEBERG INGESTION COMPLETED SUCCESSFULLY")
    else:
        print("STATUS: TPC-H ICEBERG INGESTION FAILED")
    
    print("="*70 + "\n")


def main():
    """Main orchestration."""
    print("\n" + "="*70)
    print("TPC-H ICEBERG DATA INGESTION ORCHESTRATOR")
    print("="*70)
    
    # Verify prerequisites
    if not verify_prerequisites():
        print("\nError: Prerequisites not met")
        summary(False)
        sys.exit(1)
    
    # Upload CSV
    if not upload_csv_files():
        summary(False)
        sys.exit(1)

    # Clean previous Iceberg locations
    if not cleanup_iceberg_locations():
        summary(False)
        sys.exit(1)
    
    print("\nWaiting for Trino to be fully ready...")
    time.sleep(10)
    
    # Create schemas and tables
    if not execute_iceberg_schema_sql():
        summary(False)
        sys.exit(1)
    
    # Validate
    if not validate_ingestion():
        print("\nWarning: Validation incomplete")
        summary(False)
        sys.exit(1)
    
    summary(True)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
