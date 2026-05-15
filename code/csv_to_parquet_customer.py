import io
from minio import Minio
import pandas as pd

MINIO_ENDPOINT = "localhost:9000"
MINIO_ACCESS_KEY = "admin"
MINIO_SECRET_KEY = "admin123"
MINIO_SECURE = False

SOURCE_BUCKET = "lakehouse"
SOURCE_OBJECT = "csv/customer.csv"  # pastikan path ini sama persis dengan di MinIO

TARGET_BUCKET = "iceberg"
TARGET_PREFIX = "tpch/customer"

client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE,
)

if not client.bucket_exists(TARGET_BUCKET):
    client.make_bucket(TARGET_BUCKET)

response = client.get_object(SOURCE_BUCKET, SOURCE_OBJECT)
csv_bytes = response.read()
response.close()
response.release_conn()

# DEBUG (boleh kamu aktifkan sementara)
# print(csv_bytes[:200].decode("utf-8", errors="replace"))

# File masih pakai delimiter | dan trailing |
df = pd.read_csv(
    io.BytesIO(csv_bytes),
    sep="|",
    header=None,
    engine="python"
)



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

parquet_buffer = io.BytesIO()
df.to_parquet(parquet_buffer, index=False, engine="pyarrow")
parquet_buffer.seek(0)

target_object = f"{TARGET_PREFIX}/data-00001.parquet"

client.put_object(
    TARGET_BUCKET,
    target_object,
    data=parquet_buffer,
    length=parquet_buffer.getbuffer().nbytes,
    content_type="application/octet-stream",
)

print(f"Uploaded Parquet to s3://{TARGET_BUCKET}/{target_object}")