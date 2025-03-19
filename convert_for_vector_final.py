import csv
import json
import sys
import os

def format_csv_to_ndjson(input_csv, output_json):
    with open(input_csv, mode="r", encoding="utf-8") as fin:
        reader = csv.DictReader(fin)
        output = []
        
        for idx, row in enumerate(reader):
            text_chunks = []
            for col in reader.fieldnames:
                value = row[col]
                value_str = str(value) if value is not None else ""
                text_chunks.append(f"{col}: {value_str}")
            
            json_obj = {
                "id": f"row_{idx}",
                "text": "\n".join(text_chunks),
                "metadata": row.copy()
            }
            output.append(json_obj)
    
    with open(output_json, mode="w", encoding="utf-8") as fout:
        json.dump(output, fout, ensure_ascii=False, indent=2)
    return len(output)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_for_vector_new.py <input_csv> <output.json>")
        sys.exit(1)
    
    if not os.path.exists(sys.argv[1]):
        print(f"Error: Missing input file {sys.argv[1]}")
        sys.exit(1)
    
    entries = format_csv_to_ndjson(sys.argv[1], sys.argv[2])
    print(f"Created {sys.argv[2]} with {entries} entries")


