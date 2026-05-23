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
- dbt Core + dbt Trino (diinstall lewat `requirements.txt`)
- Port yang dipakai (localhost): MinIO 9005/9001, Trino 8080, Hive Metastore 9083

Dataset Generation (TPC-H 1GB)

BigData-Kelompok5 — Panduan Langkah-demi-Langkah

Ringkasan singkat
- Tujuan: Ambil data TPC-H (dari `tpch-dbgen`), konversi ke CSV, unggah ke MinIO,
  buat tabel Iceberg via Trino, lalu jalankan transformasi/validasi dengan `dbt`.

Prasyarat (sebelum mulai)
- macOS / Linux / Windows WSL dengan Docker dan build tools
- Python 3.11 atau 3.12 (direkomendasikan)
- `make`, `gcc` (untuk meng-compile `dbgen`)
- Docker Desktop / Docker Engine (mendukung `docker compose`)
- Port yang dipakai pada localhost: MinIO 9005/9001, Trino 8080, Hive Metastore 9083

Dependensi Python
- Semua dependency Python termasuk `dbt-core` dan `dbt-trino` tercantum di
  `requirements.txt` pada root project. Kami merekomendasikan membuat virtualenv
  per-project.

Langkah Terurut (ikuti persis)

1) Siapkan virtualenv dan instal dependency

	Dari root project:

	```bash
	python3.12 -m venv .venv    # ganti python3.12 jika perlu
	source .venv/bin/activate
	python -m pip install --upgrade pip
	pip install -r requirements.txt
	```

	Validasi interpreter aktif (harus menunjuk ke `.venv`):

	```bash
	which python
	python -m pip -V
	```

	Jika masih mengarah ke Anaconda (`/opt/anaconda3/...`), jalankan `conda deactivate`
	sampai prompt `(base)` hilang, atau gunakan interpreter venv secara eksplisit
	(`./.venv/bin/python`).

	Cek `dbt` tersedia:

	```bash
	dbt --version
	# atau jika belum aktif: ./.venv/bin/dbt --version
	```

	Catatan: jika terminal Anda menggunakan Anaconda base, lebih aman gunakan
	`python3.12 -m venv .venv` seperti di atas agar package versi proyek tidak
	bercampur dengan base env.

2) Build dan generate data TPC-H (`dbgen`)

	Jika belum pernah build `dbgen`, jalankan:

	```bash
	./scripts/gendb.sh
	# skrip ini memanggil make di tpch-dbgen, lalu menjalankan dbgen -s 1 -f
	```

	Alternatif (manual):

	```bash
	cd tpch-dbgen/tpch-dbgen-master
	make
	DSS_PATH=../../data ./dbgen -s 1 -f
	```

	Hasil: file `.tbl` akan tertulis ke folder `tpch-data/`.

3) Konversi `.tbl` → CSV

	Dari root project jalankan:

	```bash
	python code/convert_tbl_to_csv.py
	ls -lh data/csv
	```

	Script akan membaca `tpch-data/*.tbl` dan menulis CSV ke `data/csv/`.

4) Jalankan layanan Docker (MinIO, Hive metastore, Trino)

	```bash
	docker compose up -d
	docker compose ps
	```

	Verifikasi cepat:

	```bash
	curl -fsS http://localhost:9005/minio/health/live && echo 'MinIO OK'
	curl -fsS http://localhost:8080/v1/info && echo 'Trino OK'
	```

5) Unggah CSV ke MinIO (bucket `lakehouse`)

	```bash
	python code/upload_csv_to_lakehouse.py
	# fallback jika python masih bukan milik .venv:
	./.venv/bin/python code/upload_csv_to_lakehouse.py
	```

	Default credential web console: `admin` / `admin123` (http://localhost:9001)

6) Buat schema / external table + Iceberg (via Trino)

	Opsi A (otomatis): jalankan orkestrator

	```bash
	python code/ingest_tpch_to_iceberg.py
	# fallback jika python masih bukan milik .venv:
	./.venv/bin/python code/ingest_tpch_to_iceberg.py
	```

	Opsi B (manual): masuk ke Trino dan eksekusi SQL

	```bash
	# masuk ke CLI Trino dalam container
	docker exec -it trino trino

	# lalu di CLI Trino
	SOURCE /path/to/code/tpch_iceberg_schema.sql;  # atau copy-paste SQL
	```

7) Siapkan dan jalankan `dbt` (transformasi & validasi)

	`tpch-dbt/` berisi `dbt_project.yml` dan `profiles.yml`. Jalankan dari folder
	tersebut agar `--profiles-dir .` menunjuk ke `profiles.yml` yang benar.

	```bash
	cd tpch-dbt
	dbt debug --profiles-dir .
	dbt run --profiles-dir .
	```

	Jika menjalankan dari root project, gunakan:

	```bash
	dbt run --project-dir tpch-dbt --profiles-dir tpch-dbt
	```

	Troubleshoot singkat:
- Jika `dbt` tidak ditemukan, aktifkan virtualenv: `source .venv/bin/activate` atau
  jalankan langsung `./.venv/bin/dbt`.
- Jika `dbt debug` gagal koneksi, periksa `tpch-dbt/profiles.yml` (host/port/user).

8) Verifikasi hasil

	Contoh query di Trino untuk verifikasi:

	```sql
	SHOW TABLES FROM iceberg.tpch;
	SELECT COUNT(*) FROM iceberg.tpch.customer;
	SELECT * FROM iceberg.tpch.customer LIMIT 10;
	```

9) Cleanup / Reset

	Untuk menghentikan layanan dan menghapus data yang di-generate:

	```bash
	./cleanup.sh
	```

	Perintah ini akan menghentikan container, menghapus `data/csv/*`, `tpch-data/*.tbl`
	dan cache Python.

Ringkasan (Quick Commands)

```bash
# 1) Setup environment
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2) Build & generate data
./scripts/gendb.sh

# 3) Convert & upload
python code/convert_tbl_to_csv.py
python code/upload_csv_to_lakehouse.py

# 4) Start services
docker compose up -d

# 5) Ingest (schema + data)
python code/ingest_tpch_to_iceberg.py

# 6) Run dbt
cd tpch-dbt && dbt run --profiles-dir .
```

Jika kamu mau, saya bisa: (a) menjalankan langkah verifikasi `dbt debug` sekarang di mesin kamu, atau (b) menambahkan contoh konfigurasi `profiles.yml` yang lebih lengkap untuk Trino. Pilih salah satu.

