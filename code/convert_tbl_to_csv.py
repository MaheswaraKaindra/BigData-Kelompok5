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
        print('No .gz files found. Skipping gunzip step.')
        return

    for gz_path in gz_files:
        output_path = gz_path.with_suffix('')
        print(f'Extracting GZ: {gz_path} -> {output_path}')
        with gzip.open(gz_path, 'rb') as src, output_path.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        print(f'Extracted GZ to: {output_path}')


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
    if not INPUT_DIR.exists():
        raise FileNotFoundError(f'Input directory not found: {INPUT_DIR}')

    ungzip_archives(INPUT_DIR)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    tbl_files = sorted(INPUT_DIR.rglob('*.tbl'))
    if not tbl_files:
        raise FileNotFoundError(f'No .tbl files found in: {INPUT_DIR}')

    print(f'Found {len(tbl_files)} .tbl file(s) in {INPUT_DIR}')

    for tbl_file in tbl_files:
        csv_file = OUTPUT_DIR / f'{tbl_file.stem}.csv'
        convert_tbl_to_csv(tbl_file, csv_file)
        print(f'Converted: {tbl_file} -> {csv_file}')

    print(f'All files converted successfully to: {OUTPUT_DIR}')


if __name__ == '__main__':
    main()
