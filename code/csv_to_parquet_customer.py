import io
from minio import Minio
import pandas as pd

MINIO_ENDPOINT = "localhost:9000"
MINIO_ACCESS_KEY = "admin"
MINIO_SECRET_KEY = "admin123"
MINIO_SECURE = False

SOURCE_BUCKET = "lakehouse"
SOURCE_OBJECT = "csv/customer/customer.csv"

TARGET_BUCKET = "iceberg"
TARGET_PREFIX = "tpch/customer"

print("\n" + "="*70)
print("CSV TO PARQUET CONVERTER - CUSTOMER")
print("="*70)

print(f"\nSource: s3://{SOURCE_BUCKET}/{SOURCE_OBJECT}")
print(f"Target: s3://{TARGET_BUCKET}/{TARGET_PREFIX}/")

print("\nConnecting to MinIO...")
client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE,
)

# Ensure target bucket exists
if not client.bucket_exists(TARGET_BUCKET):
    print(f"Creating bucket: {TARGET_BUCKET}")
    client.make_bucket(TARGET_BUCKET)
else:
    print(f"Bucket exists: {TARGET_BUCKET}")

print(f"Reading CSV from MinIO...")
response = client.get_object(SOURCE_BUCKET, SOURCE_OBJECT)
csv_bytes = response.read()
response.close()
response.release_conn()

csv_size = len(csv_bytes) / (1024 * 1024)
print(f"Read {csv_size:.2f} MB")

print("\nParsing CSV data...")
df = pd.read_csv(
    io.BytesIO(csv_bytes),
    sep=",",
    header=None,
    engine="python"
)

print(f"Rows: {len(df)}")
print(f"Columns: {df.shape[1]}")

print("\nApplying schema...")
df.columns = [
    "c_custkey",
    "c_name",
    "c_address",
    "c_nationkey",
    "c_phone",
    "c_acctbal",
    "c_mktsegment",
    "c_comment",
]

df["c_custkey"] = df["c_custkey"].astype("int64")
df["c_nationkey"] = df["c_nationkey"].astype("int64")
df["c_acctbal"] = df["c_acctbal"].astype("float64")

print("Converting to Parquet format...")
parquet_buffer = io.BytesIO()
df.to_parquet(parquet_buffer, index=False, engine="pyarrow")
parquet_buffer.seek(0)

parquet_size = parquet_buffer.getbuffer().nbytes / (1024 * 1024)
print(f"Parquet size: {parquet_size:.2f} MB")

target_object = f"{TARGET_PREFIX}/data-00001.parquet"

print(f"\nUploading to MinIO...")
client.put_object(
    TARGET_BUCKET,
    target_object,
    data=parquet_buffer,
    length=parquet_buffer.getbuffer().nbytes,
    content_type="application/octet-stream",
)

print(f"Uploaded: s3://{TARGET_BUCKET}/{target_object}")
print("\n" + "="*70)
print("Conversion completed successfully")
print("="*70 + "\n")