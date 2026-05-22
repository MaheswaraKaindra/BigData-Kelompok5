BigData-Kelompok5

Ringkasan singkat
- TPC-H → Iceberg:
	1) Convert `.tbl` → CSV
	2) Upload CSV ke MinIO (bucket `lakehouse`)
	3) Buat external tables + Iceberg tables via Trino/Hive
	4) Ingest & verifikasi

Prerequisite
- Docker Desktop / Docker Engine `docker compose`
- Python 3.9+, `pip`
- Build tools: `make`, `gcc` (untuk compile dbgen)
- Port yang dipakai (localhost): MinIO 9000/9001, Trino 8080, Hive Metastore 9083

Dataset Generation (TPC-H 1GB)

Jika belum ada file `.tbl` di folder `tpch-data/`, generate terlebih dahulu:

```bash
# Build dan jalankan dbgen (menghasilkan 1GB data)
./scripts/gendb.sh
```

Script akan:
- Build `dbgen` (kompile dari source di `tpch-dbgen/`)
- Generate file `.tbl` dengan scale factor 1 (1GB)
- Output ke folder `tpch-data/`

Jika ingin custom size, edit `scripts/gendb.sh` dan ubah parameter `-s 1` menjadi scale factor yang diinginkan (contoh: `-s 10` untuk 10GB).

Langkah-langkah (jalankan dari root project)
1) Instal dependensi Python (virtualenv)

```bash
python3 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt
```

2) Jalankan Docker (MinIO, Hive metastore, Trino)

```bash
docker compose up -d
```

3) Pastikan MinIO & Trino jalan (tunggu beberapa detik saat pertama kali)

```bash
docker compose ps
curl -fsS http://localhost:9000/minio/health/live && echo 'MinIO OK'
curl -fsS http://localhost:8080/v1/info && echo 'Trino OK'
```

4) Konversi file TPC-H `.tbl` → CSV

- Script: [code/convert_tbl_to_csv.py](code/convert_tbl_to_csv.py)
- Input: folder `tpch-data/` (file `*.tbl`) — script akan mencari `tpch-data/*.tbl`
- Output: `data/csv/*.csv`

```bash
python code/convert_tbl_to_csv.py
# Periksa hasil:
ls -lh data/csv
```

Note: script juga akan mengekstrak file `*.gz` di `tpch-data/` jika ada.

5) Upload CSV ke MinIO (lakehouse)

- Script: [code/upload_csv_to_lakehouse.py](code/upload_csv_to_lakehouse.py)
- Default MinIO credentials: `admin` / `admin123`
- MinIO Console: http://localhost:9001 (login: admin / admin123)

```bash
python code/upload_csv_to_lakehouse.py
# Verifikasi bucket dan file di MinIO web console
```

6) (Opsional) Jalankan seluruh pipeline otomatis: buat schema + ingest + verifikasi

- Script orchestrator Data Generation & Ingestion: [code/ingest_tpch_to_iceberg.py](code/ingest_tpch_to_iceberg.py)

```bash
python code/ingest_tpch_to_iceberg.py
```

Script ini otomatis menjalankan:
- Upload CSV (memanggil `upload_csv_to_lakehouse.py`)
- Koneksi ke Trino dan mengeksekusi SQL di [code/tpch_iceberg_schema.sql](code/tpch_iceberg_schema.sql)
- Validasi row counts pada Iceberg tables

7) Verifikasi hasil dan contoh query (via Trino)

```bash
# Masuk ke CLI Trino dalam container
docker exec -it trino trino

# Contoh SQL
SHOW TABLES FROM iceberg.tpch;
SELECT COUNT(*) FROM iceberg.tpch.customer;
SELECT * FROM iceberg.tpch.customer LIMIT 10;
```

8) Utility tambahan
- `code/csv_to_parquet_customer.py` dapat membaca `s3://lakehouse/csv/customer.csv` dari MinIO
	dan upload Parquet ke bucket `iceberg` (sebagai contoh konversi ke Parquet), tapi di sini nggak dimasukkan ke pipeline.


Perintah penting (Rangkuman)

```bash
# Start services
docker compose up -d

# Convert .tbl -> .csv
python code/convert_tbl_to_csv.py

# Upload CSV -> MinIO
python code/upload_csv_to_lakehouse.py

# Full ingestion (upload + create schemas + ingest + validate)
python code/ingest_tpch_to_iceberg.py

# Trino CLI
docker exec -it trino trino
```

File utama & peran singkat
- [code/convert_tbl_to_csv.py](code/convert_tbl_to_csv.py) — konversi `.tbl` → `data/csv/`
- [code/upload_csv_to_lakehouse.py](code/upload_csv_to_lakehouse.py) — unggah CSV ke MinIO `lakehouse`
- [code/ingest_tpch_to_iceberg.py](code/ingest_tpch_to_iceberg.py) — orkestrator end-to-end
- [code/tpch_iceberg_schema.sql](code/tpch_iceberg_schema.sql) — SQL untuk membuat external + iceberg tables
- [code/csv_to_parquet_customer.py](code/csv_to_parquet_customer.py) — contoh konversi CSV → Parquet dan upload

Cleanup & Reset

Untuk menghapus semua generated data dan reset project:

```bash
./cleanup.sh
```

Script akan:
- Stop dan remove Docker containers
- Hapus `data/csv/*` (generated CSV files)
- Hapus `tpch-data/*.tbl` (extracted TPC-H files)
- Hapus Python cache

**Catatan:** File `.tbl.gz` (compressed source) akan dipertahankan.

Setelah cleanup, Anda bisa:
- Generate ulang data: `./scripts/gendb.sh`
- Atau extract dari `.tbl.gz` yang ada jika file sudah diekstrak sebelumnya

