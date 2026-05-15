# BigData-Kelompok5


## Big Data Environment Tech Stack
- Data Lakehouse: Apache Iceberg
- Layer Storage: MinIO
- Data Orchestration: dbt
- Data Processing: Trino


## Setup

```bash

# 1. Create virtual environment
py -m venv venv

# Linux/Mac
source venv/Scripts/activate  
# Windows
\venv\Scripts\activate


# 2. Install dependencies
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

# 3. Verify dbt
dbt --version

```
Jalankan Docker

```bash

docker compose up -d

```
Endpoint

| MinIO | http://localhost:9001|

Username: admin

Password: admin123

|Trino UI | http://localhost:8080|

Jalankan Trino di CLI

```bash
docker exec -it trino trino
```

Cek catalogs di trino
```bash
SHOW CATALOGS; 

SHOW SCHEMAS FROM iceberg;
```
Pastikan sudah aman. 

## Fetch Data DBGEN

```bash
git clone https://github.com/electrum/tpch-dbgen.git
cd tpch-dbgen
make
```

Kalau misalnya tidak bisa ambil data, coba pakai WSL. Aku pakai Windows gak ke solved :') 

Ambil data raw

```bash
git clone https://github.com/aleaugustoplus/tpch-data.git
```
lalu run `convert_tbl_to_csv.py` untuk convert data .tbl ke .csv dan ganti limiter dari "|" ke ","


## Upload CSV ke Lakehouse MinIO

- Bisa langsung di Console nya di `http://localhost:9001` di Lakehouse lalu Upload Folder. 

- Bisa pakai command. Saat dicoba di aku error. 

## CSV -> Parquet

- Run csv_to_parquet_customer.py untuk file customer. 



