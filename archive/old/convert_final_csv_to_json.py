import json
import pandas as pd
from pathlib import Path
import re

# Load fighter info from CSV
fighter_info = pd.read_csv('data/fighter_info.csv').set_index('Fighter_ID').to_dict('index')
combined_data = []

# Function to parse height string to inches
def height_to_inches(height_str):
    if not isinstance(height_str, str) or not height_str:
        return None
    
    # Parse format like "6'2"
    match = re.match(r"(\d+)'(\d+)", height_str)
    if match:
        feet, inches = int(match.group(1)), int(match.group(2))
        return (feet * 12) + inches
    return None

# Function to convert date format
def format_date(date_str):
    if not isinstance(date_str, str) or not date_str:
        return None
    
    # Convert "Jul 19, 1987" to "1987-07-19"
    try:
        months = {
            "Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04", "May": "05", "Jun": "06", 
            "Jul": "07", "Aug": "08", "Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"
        }
        
        match = re.match(r"(\w+) (\d+), (\d+)", date_str)
        if match:
            month, day, year = match.groups()
            month_num = months.get(month, "01")
            day_padded = day.zfill(2)
            return f"{year}-{month_num}-{day_padded}"
    except:
        pass
    
    return date_str

for json_file in Path('data/fighters').glob('*.json'):
    with open(json_file, 'r') as f:
        fights_data = json.load(f)
    
    # Extract the fighter ID and name
    fighter_key = json_file.stem
    fighter_id = int(fighter_key.split('_')[-1])
    fighter_name = " ".join(fighter_key.split('_')[:-1])
    
    # Get the base info from CSV
    base_info = fighter_info.get(fighter_id, {})
    
    # Extract wins and losses from the base info
    wins = base_info.get('Wins', 0)
    losses = base_info.get('Losses', 0)
    draws = base_info.get('Draws', 0) if 'Draws' in base_info else 0
    
    # Create the structured fighter entry
    fighter_entry = {
        "id": fighter_id,
        "name": fighter_name,
        "nickname": base_info.get('Nickname', ''),
        "birth_date": format_date(base_info.get('Birth Date', '')),
        "nationality": base_info.get('Nationality', ''),
        "hometown": base_info.get('Hometown', ''),
        "association": base_info.get('Association', ''),
        "weight_class": base_info.get('Weight Class', ''),
        "height_display": base_info.get('Height', ''),
        "height_inches": height_to_inches(base_info.get('Height', '')),
        
        "stats": {
            "record": f"{wins}-{losses}-{draws}",
            "total_wins": wins,
            "total_losses": losses,
            "total_draws": draws,
            "win_methods": {
                "decision": base_info.get('Win_Decision', 0),
                "knockout": base_info.get('Win_KO', 0), 
                "submission": base_info.get('Win_Sub', 0)
            },
            "loss_methods": {
                "decision": base_info.get('Loss_Decision', 0),
                "knockout": base_info.get('Loss_KO', 0),
                "submission": base_info.get('Loss_Sub', 0)
            }
        },
        
        "fights": []
    }
    
    # Process each fight with improved structure
    processed_fights = []
    for fight in fights_data:
        # Parse the event date
        event_date = fight.get('Event Date', '')
        formatted_date = event_date
        
        # Try to convert "Nov / 16 / 2024" to "2024-11-16"
        match = re.match(r"(\w+) / (\d+) / (\d+)", event_date)
        if match:
            month, day, year = match.groups()
            months = {
                "Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04", "May": "05", "Jun": "06", 
                "Jul": "07", "Aug": "08", "Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"
            }
            month_num = months.get(month, "01")
            day_padded = day.zfill(2)
            formatted_date = f"{year}-{month_num}-{day_padded}"
        
        # Handle method and referee
        method_ref = fight.get('Method/Referee', '')
        method = method_ref
        referee = ""
        
        # Try to separate method and referee if they're combined
        if method_ref:
            parts = method_ref.split('Referee: ')
            if len(parts) > 1:
                method, referee = parts
            else:
                # Try another pattern where referee name follows directly
                for ref_name in ["Herb Dean", "Marc Goddard", "Dan Miragliotta", "John McCarthy", "Keith Peterson"]:
                    if ref_name in method_ref:
                        method = method_ref.replace(ref_name, '').strip()
                        referee = ref_name
                        break
        
        structured_fight = {
            "result": fight.get('Result', '').lower(),
            "opponent": fight.get('Opponent', ''),
            "date": formatted_date,
            "event": fight.get('Event', ''),
            "method": method,
            "referee": referee,
            "round": int(fight.get('Rounds', 0)) if fight.get('Rounds', '').isdigit() else fight.get('Rounds', '')
        }
        
        processed_fights.append(structured_fight)
    
    # Sort fights by date (newest to oldest)
    sorted_fights = sorted(processed_fights, key=lambda x: x["date"], reverse=True)
    
    # Add sorted fights to fighter entry
    fighter_entry["fights"] = sorted_fights
    
    combined_data.append(fighter_entry)

# Write to improved final.json
with open('data/final.json', 'w') as f:
    json.dump(combined_data, f, indent=2)

print(f"Conversion complete! Created data/final.json with {len(combined_data)} fighter records.")
