import csv
import json
import os

def format_fighter_data(input_csv, output_json):
    """Convert fighter data CSV to vector-ready JSON"""
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
                # "id": f"fighter_{idx}",
                "text": "\n".join(text_chunks),
                "metadata": row.copy()
            }
            output.append(json_obj)
    
    with open(output_json, mode="w", encoding="utf-8") as fout:
        json.dump(output, fout, ensure_ascii=False, indent=2)
    return len(output)

def format_event_data(input_csv, output_json):
    """Convert event/fight data CSV to vector-ready JSON with optimized structure"""
    with open(input_csv, 'r', encoding='utf-8') as fin:
        reader = csv.DictReader(fin)
        output = []
        
        for idx, row in enumerate(reader):
            fight_description = []
            
            # Add event details first
            if 'Event Name' in row:
                fight_description.append(f"Event: {row['Event Name']}")
            if 'Event Date' in row:
                fight_description.append(f"Date: {row['Event Date']}")
            if 'Event Location' in row:
                fight_description.append(f"Location: {row['Event Location']}")
                
            # Add fight-specific details
            if 'Fighter 1' in row and 'Fighter 2' in row:
                fight_description.append(f"Fight: {row['Fighter 1']} vs {row['Fighter 2']}")
            if 'Weight Class' in row:
                fight_description.append(f"Weight Class: {row['Weight Class']}")
            
            # Add result details
            if 'Winning Fighter' in row:
                fight_description.append(f"Winner: {row['Winning Fighter']}")
            if 'Winning Method' in row:
                fight_description.append(f"Method: {row['Winning Method']}")
            if 'Winning Round' in row:
                fight_description.append(f"Round: {row['Winning Round']}")
            if 'Winning Time' in row:
                fight_description.append(f"Time: {row['Winning Time']}")
                
            # Add any remaining fields
            for col in reader.fieldnames:
                if col not in ['Event Name', 'Event Date', 'Event Location', 
                              'Fighter 1', 'Fighter 2', 'Weight Class',
                              'Winning Fighter', 'Winning Method', 'Winning Round', 'Winning Time']:
                    fight_description.append(f"{col}: {row[col]}")
            
            json_obj = {
                "id": f"fight_{idx}",
                "text": "\n".join(fight_description),
                "metadata": row.copy()
            }
            output.append(json_obj)
    
    with open(output_json, 'w', encoding='utf-8') as fout:
        json.dump(output, fout, ensure_ascii=False, indent=2)
    return len(output)

if __name__ == "__main__":
    # Hardcoded file paths
    FIGHTER_CSV = "data/fighter_info.csv"
    FIGHTER_JSON = "data/fighter_vectors.json"
    EVENT_CSV = "data/event_data_sherdog.csv" 
    EVENT_JSON = "data/event_vectors.json"
    
    # Process fighter data
    if os.path.exists(FIGHTER_CSV):
        entries = format_fighter_data(FIGHTER_CSV, FIGHTER_JSON)
        print(f"✓ Created fighter vectors at {FIGHTER_JSON} with {entries} fighters")
    else:
        print(f"✗ Fighter data not found at {FIGHTER_CSV}")
    
    # Process event data
    if os.path.exists(EVENT_CSV):
        entries = format_event_data(EVENT_CSV, EVENT_JSON)
        print(f"✓ Created event vectors at {EVENT_JSON} with {entries} fights")
    else:
        print(f"✗ Event data not found at {EVENT_CSV}")