import sys
from pathlib import Path
from minio import Minio
from minio.error import S3Error


def get_minio_client():
    """Create and return MinIO client."""
    return Minio(
        endpoint="localhost:9005",
        access_key="admin",
        secret_key="admin123",
        secure=False,
    )


def ensure_bucket_exists(client: Minio, bucket_name: str) -> None:
    """Ensure MinIO bucket exists, create if not."""
    try:
        if not client.bucket_exists(bucket_name):
            client.make_bucket(bucket_name)
            print(f"  Created bucket: {bucket_name}")
        else:
            print(f"  Bucket exists: {bucket_name}")
    except S3Error as e:
        print(f"Error: Could not access bucket {bucket_name}: {e}")
        raise


def upload_csv_files(csv_dir: Path, client: Minio, bucket_name: str, prefix: str = "csv") -> None:
    """Upload all CSV files from directory to MinIO."""
    if not csv_dir.exists():
        print(f"Error: CSV directory not found: {csv_dir}")
        sys.exit(1)

    csv_files = sorted(csv_dir.glob("*.csv"))
    
    if not csv_files:
        print(f"Error: No CSV files found in: {csv_dir}")
        sys.exit(1)

    print(f"\nFound {len(csv_files)} CSV file(s)")
    print(f"Uploading to s3://{bucket_name}/{prefix}/")
    print()

    # Clean up old files before uploading new ones
    print(f"Cleaning up old files in s3://{bucket_name}/{prefix}/...")
    try:
        old_objects = client.list_objects(bucket_name, prefix=prefix, recursive=True)
        cleanup_count = 0
        for obj in old_objects:
            try:
                client.remove_object(bucket_name, obj.object_name)
                cleanup_count += 1
            except S3Error as e:
                print(f"  Warning: Could not remove {obj.object_name}: {str(e)[:40]}")
        if cleanup_count > 0:
            print(f"Removed {cleanup_count} old object(s).")
        else:
            print(f"No old objects found.")
    except S3Error as e:
        print(f"  Warning: Cleanup failed: {str(e)[:60]}")
    
    print()

    failed_files = []
    
    for csv_file in csv_files:
        try:
            table_name = csv_file.stem
            object_name = f"{prefix}/{table_name}/{csv_file.name}"
            file_size = csv_file.stat().st_size
            
            client.fput_object(
                bucket_name,
                object_name,
                str(csv_file),
                content_type="text/csv",
            )
            
            formatted_size = format_file_size(file_size)
            print(f"  Uploaded {csv_file.name:20} ({formatted_size:>10}) → {object_name}")   
        except S3Error as e:
            print(f"  Error {csv_file.name:20} {str(e)[:40]}")
            failed_files.append(csv_file.name)

    print(f"\n{'-'*70}")
    print(f"Upload Summary")
    print(f"  Total files:    {len(csv_files)}")
    print(f"  Successful:     {len(csv_files) - len(failed_files)}")
    print(f"  Failed:         {len(failed_files)}")
    
    if failed_files:
        print(f"\nFailed files:")
        for f in failed_files:
            print(f"  - {f}")
        sys.exit(1)
    else:
        print(f"\nAll CSV files uploaded successfully")


def verify_uploads(client: Minio, bucket_name: str, prefix: str = "csv") -> None:
    """Verify that files were uploaded correctly."""
    print(f"\nVerifying uploads in s3://{bucket_name}/{prefix}/")
    print()
    
    try:
        objects = client.list_objects(bucket_name, prefix=prefix, recursive=True)
        count = 0
        
        for obj in objects:
            if obj.object_name.endswith(".csv"):
                # size_mb = obj.size / (1024 * 1024)
                formatted_size = format_file_size(obj.size)
                print(f"  {obj.object_name:40} ({formatted_size})")
                count += 1
        
        if count == 0:
            print(f"  No CSV files found in {bucket_name}/{prefix}")
            return False
        
        print(f"\nVerified: {count} CSV file(s) in MinIO")
        return True
        
    except S3Error as e:
        print(f"Error: Verification failed: {e}")
        return False


def main():
    
    # Resolve paths
    code_dir = Path(__file__).resolve().parent
    project_dir = code_dir.parent
    csv_dir = project_dir / "data" / "csv"
    
    print(f"Project directory: {project_dir}")
    print(f"CSV directory:     {csv_dir}")
    
    # MinIO config
    bucket_name = "lakehouse"
    csv_prefix = "csv"
    
    try:
        # Connect to MinIO
        print(f"\nConnecting to MinIO localhost:9005...")
        client = get_minio_client()
        client.bucket_exists("lakehouse")
        print("Connected")
        
        # Ensure bucket exists
        ensure_bucket_exists(client, bucket_name)
        
        # Upload CSV files
        upload_csv_files(csv_dir, client, bucket_name, csv_prefix)
        
        # Verify uploads
        verify_uploads(client, bucket_name, csv_prefix)
        
        print("Complete")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


def format_file_size(size_in_bytes: float) -> str:
    """Mengubah ukuran bytes menjadi KB, MB, atau GB secara dinamis."""
    kb = 1024
    mb = kb * 1024
    gb = mb * 1024

    if size_in_bytes < mb:
        return f"{size_in_bytes / kb:6.2f} KB"
    elif size_in_bytes >= gb:
        return f"{size_in_bytes / gb:6.2f} GB"
    else:
        return f"{size_in_bytes / mb:6.2f} MB"
    
if __name__ == "__main__":
    main()
