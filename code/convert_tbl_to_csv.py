from pathlib import Path
import gzip
import shutil
import csv

BASE_DIR = Path(__file__).resolve().parent.parent
INPUT_DIR = BASE_DIR / 'tpch-data'
OUTPUT_DIR = BASE_DIR / 'data' / 'csv'


def ungzip_archives(input_dir: Path) -> None:
    gz_files = sorted(input_dir.rglob('*.gz'))
    if not gz_files:
        print('  No GZ files found')
        return

    print(f"Found {len(gz_files)} GZ file(s)")
    for gz_path in gz_files:
        output_path = gz_path.with_suffix('')
        print(f"  Extracting {gz_path.name}...")
        with gzip.open(gz_path, 'rb') as src, output_path.open('wb') as dst:
            shutil.copyfileobj(src, dst)


def convert_tbl_to_csv(input_path: Path, output_path: Path) -> None:
    with input_path.open('r', encoding='utf-8', errors='replace', newline='') as src, \
         output_path.open('w', encoding='utf-8', newline='') as dst:
        reader = csv.reader(src, delimiter='|')
        writer = csv.writer(dst)

        for row in reader:
            if row and row[-1] == '':
                row = row[:-1]
            writer.writerow(row)


def main() -> None:
    print("\n" + "="*70)
    print("TBL TO CSV CONVERTER")
    print("="*70)
    
    if not INPUT_DIR.exists():
        raise FileNotFoundError(f'Input directory not found: {INPUT_DIR}')

    print(f"\nInput directory:  {INPUT_DIR}")
    print(f"Output directory: {OUTPUT_DIR}")
    
    # Extract GZ files if any
    print("\nStep 1: Extract GZ archives")
    ungzip_archives(INPUT_DIR)
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Find and convert TBL files
    tbl_files = sorted(INPUT_DIR.rglob('*.tbl'))
    if not tbl_files:
        raise FileNotFoundError(f'No TBL files found in: {INPUT_DIR}')

    print(f"Step 2: Convert TBL files")
    print(f"Found {len(tbl_files)} file(s)\n")

    for i, tbl_file in enumerate(tbl_files, 1):
        csv_file = OUTPUT_DIR / f'{tbl_file.stem}.csv'
        convert_tbl_to_csv(tbl_file, csv_file)
        file_size = csv_file.stat().st_size / (1024 * 1024)
        print(f"  [{i}] {tbl_file.name:20} → {csv_file.name:20} ({file_size:6.2f} MB)")

    print(f"\n" + "="*70)
    print(f"Conversion completed: {len(tbl_files)} file(s)")
    print(f"Output location: {OUTPUT_DIR}")
    print("="*70 + "\n")


if __name__ == '__main__':
    main()
