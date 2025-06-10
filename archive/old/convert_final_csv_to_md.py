import json
from pathlib import Path
import re
import os

# This script ONLY generates markdown files for vector store optimization
# It does NOT create the actual vector embeddings or vector store
# You will need to manually upload these files to your vector store provider

def create_fighter_markdown(fighter_data):
    """Create markdown content for a fighter optimized for vector store retrieval"""
    # Start with a clear title and summary for better embedding
    md = f"# {fighter_data['name']} - UFC Fighter Profile\n\n"
    
    # Add a summary section that repeats key information for better semantic retrieval
    md += f"{fighter_data['name']} is a UFC fighter with a record of {fighter_data['stats']['record']}. "
    md += f"Fighting in the {fighter_data['weight_class']} division, "
    
    if fighter_data['nickname']:
        md += f"known as \"{fighter_data['nickname']}\", "
    
    md += f"{fighter_data['name']} has {fighter_data['stats']['total_wins']} wins "
    md += f"({fighter_data['stats']['win_methods']['knockout']} by knockout, "
    md += f"{fighter_data['stats']['win_methods']['submission']} by submission, "
    md += f"{fighter_data['stats']['win_methods']['decision']} by decision) "
    md += f"and {fighter_data['stats']['total_losses']} losses "
    md += f"({fighter_data['stats']['loss_methods']['knockout']} by knockout, "
    md += f"{fighter_data['stats']['loss_methods']['submission']} by submission, "
    md += f"{fighter_data['stats']['loss_methods']['decision']} by decision).\n\n"
    
    # Basic info section with clear semantic headers
    md += "## Fighter Information\n\n"
    
    # Create a table for basic info - tables are parsed well by vector stores
    md += "| Attribute | Value |\n"
    md += "| --- | --- |\n"
    md += f"| Name | {fighter_data['name']} |\n"
    if fighter_data['nickname']:
        md += f"| Nickname | {fighter_data['nickname']} |\n"
    md += f"| Weight Class | {fighter_data['weight_class']} |\n"
    if fighter_data['height_display']:
        md += f"| Height | {fighter_data['height_display']} |\n"
    if fighter_data['nationality']:
        md += f"| Nationality | {fighter_data['nationality']} |\n"
    if fighter_data['hometown']:
        md += f"| Hometown | {fighter_data['hometown']} |\n"
    if fighter_data['association']:
        md += f"| Team/Association | {fighter_data['association']} |\n"
    if fighter_data['birth_date']:
        md += f"| Birth Date | {fighter_data['birth_date']} |\n"
    md += "\n"
    
    # Stats section with clear semantic structure
    md += "## Fight Statistics\n\n"
    
    # Create a table for record stats
    md += "### Record Summary\n\n"
    md += "| Category | Value |\n"
    md += "| --- | --- |\n"
    md += f"| Overall Record | {fighter_data['stats']['record']} |\n"
    md += f"| Total Wins | {fighter_data['stats']['total_wins']} |\n"
    md += f"| Total Losses | {fighter_data['stats']['total_losses']} |\n"
    md += f"| Total Draws | {fighter_data['stats']['total_draws']} |\n"
    md += "\n"
    
    # Win methods with explicit labeling
    md += "### Win Methods\n\n"
    win_methods = fighter_data['stats']['win_methods']
    md += "| Method | Count |\n"
    md += "| --- | --- |\n"
    md += f"| Knockout/TKO | {win_methods['knockout']} |\n"
    md += f"| Submission | {win_methods['submission']} |\n"
    md += f"| Decision | {win_methods['decision']} |\n"
    md += "\n"
    
    # Loss methods with explicit labeling
    md += "### Loss Methods\n\n"
    loss_methods = fighter_data['stats']['loss_methods']
    md += "| Method | Count |\n"
    md += "| --- | --- |\n"
    md += f"| Knockout/TKO | {loss_methods['knockout']} |\n"
    md += f"| Submission | {loss_methods['submission']} |\n"
    md += f"| Decision | {loss_methods['decision']} |\n"
    md += "\n"
    
    # Fight history with clear semantic structure
    md += "## Fight History\n\n"
    
    # Add a summary of most recent fights first
    md += "### Most Recent Fights\n\n"
    
    # Create a table of recent fights for better parsing
    md += "| Date | Opponent | Result | Method | Event |\n"
    md += "| --- | --- | --- | --- | --- |\n"
    
    for fight in fighter_data['fights'][:5]:  # Top 5 most recent fights
        result = fight['result'].upper()
        md += f"| {fight['date']} | {fight['opponent']} | {result} | {fight['method']} | {fight['event']} |\n"
    
    md += "\n"
    
    # Detailed fight history
    md += "### Complete Fight History\n\n"
    
    for i, fight in enumerate(fighter_data['fights']):
        result_emoji = "✅" if fight['result'] == 'win' else "❌" if fight['result'] == 'loss' else "🔄"
        md += f"#### Fight vs. {fight['opponent']} ({fight['date']})\n\n"
        
        # Create a table for each fight for better parsing
        md += "| Detail | Information |\n"
        md += "| --- | --- |\n"
        md += f"| Opponent | {fight['opponent']} |\n"
        md += f"| Date | {fight['date']} |\n"
        md += f"| Event | {fight['event']} |\n"
        md += f"| Result | {fight['result'].upper()} |\n"
        md += f"| Method | {fight['method']} |\n"
        if fight['referee']:
            md += f"| Referee | {fight['referee']} |\n"
        md += f"| Round | {fight['round']} |\n"
        md += "\n"
        
        # Add a sentence summary for better semantic understanding
        md += f"{fighter_data['name']} {fight['result']} against {fight['opponent']} on {fight['date']} "
        md += f"at {fight['event']} by {fight['method']} in round {fight['round']}.\n\n"
    
    return md

def create_fighter_chunk(fighter_data):
    """Create a smaller markdown chunk for a fighter focused on key stats and recent fights"""
    chunk = f"# {fighter_data['name']} - UFC Fighter Stats\n\n"
    
    # Add a summary section with key information
    chunk += f"{fighter_data['name']} is a UFC fighter with a record of {fighter_data['stats']['record']}. "
    chunk += f"Fighting in the {fighter_data['weight_class']} division, "
    
    if fighter_data['nickname']:
        chunk += f"known as \"{fighter_data['nickname']}\", "
    
    chunk += f"{fighter_data['name']} has {fighter_data['stats']['total_wins']} wins and {fighter_data['stats']['total_losses']} losses.\n\n"
    
    # Add record in a clear format
    chunk += f"## {fighter_data['name']}'s Record: {fighter_data['stats']['record']}\n\n"
    
    # Add win methods
    chunk += f"Wins by KO/TKO: {fighter_data['stats']['win_methods']['knockout']}, "
    chunk += f"Submissions: {fighter_data['stats']['win_methods']['submission']}, "
    chunk += f"Decisions: {fighter_data['stats']['win_methods']['decision']}\n\n"
    
    # Add recent fights in a clear format
    chunk += f"## {fighter_data['name']}'s Recent Fights:\n\n"
    
    for i, fight in enumerate(fighter_data['fights'][:5]):
        result = fight['result'].upper()
        chunk += f"- {fighter_data['name']} {result} vs {fight['opponent']} on {fight['date']} by {fight['method']}\n"
    
    return chunk

def main():
    print("\n" + "="*80)
    print("MARKDOWN FILE GENERATOR FOR VECTOR STORE OPTIMIZATION".center(80))
    print("="*80)
    print("\nIMPORTANT: This script ONLY generates markdown files.")
    print("It does NOT create the actual vector embeddings or vector store.")
    print("You will need to manually upload these files to your vector store provider.\n")
    
    # Create directories if they don't exist
    vector_store_dir = Path('data/vector_store_markdown')
    vector_store_dir.mkdir(exist_ok=True)
    
    chunks_dir = Path('data/vector_store_chunks')
    chunks_dir.mkdir(exist_ok=True)
    
    # Load fighter data from final.json
    try:
        with open('data/final.json', 'r') as f:
            fighters_data = json.load(f)
        print(f"Loaded {len(fighters_data)} fighters from data/final.json")
    except FileNotFoundError:
        print("Error: data/final.json not found. Please run convert_final_csv_to_json.py first.")
        return
    except json.JSONDecodeError:
        print("Error: data/final.json is not valid JSON. Please check the file.")
        return
    
    print("\nGenerating markdown files...")
    
    # Create individual vector-store optimized markdown files
    for fighter in fighters_data:
        # Create full markdown file for this fighter
        markdown_content = create_fighter_markdown(fighter)
        safe_name = fighter['name'].replace(" ", "_").lower()
        with open(vector_store_dir / f"{safe_name}.md", 'w') as md_file:
            md_file.write(markdown_content)
        
        # Create smaller chunk file for this fighter
        chunk_content = create_fighter_chunk(fighter)
        with open(chunks_dir / f"{safe_name}_chunk.md", 'w') as chunk_file:
            chunk_file.write(chunk_content)
    
    # Create a single combined file with all fighter data for vector store ingestion
    with open('data/vector_store_all_fighters.md', 'w') as vs_md:
        vs_md.write("# UFC Fighter Database - Vector Store Optimized\n\n")
        
        for fighter in fighters_data:
            vs_md.write(f"# {fighter['name']} - UFC Fighter Profile\n\n")
            
            # Add a summary section that repeats key information for better semantic retrieval
            vs_md.write(f"{fighter['name']} is a UFC fighter with a record of {fighter['stats']['record']}. ")
            vs_md.write(f"Fighting in the {fighter['weight_class']} division, ")
            
            if fighter['nickname']:
                vs_md.write(f"known as \"{fighter['nickname']}\", ")
            
            vs_md.write(f"{fighter['name']} has {fighter['stats']['total_wins']} wins ")
            vs_md.write(f"({fighter['stats']['win_methods']['knockout']} by knockout, ")
            vs_md.write(f"{fighter['stats']['win_methods']['submission']} by submission, ")
            vs_md.write(f"{fighter['stats']['win_methods']['decision']} by decision) ")
            vs_md.write(f"and {fighter['stats']['total_losses']} losses.\n\n")
            
            # Add record in a clear format
            vs_md.write(f"## {fighter['name']}'s Record: {fighter['stats']['record']}\n\n")
            
            # Add recent fights in a clear format
            vs_md.write(f"## {fighter['name']}'s Recent Fights:\n\n")
            
            for i, fight in enumerate(fighter['fights'][:5]):
                result = fight['result'].upper()
                vs_md.write(f"- {fighter['name']} {result} vs {fight['opponent']} on {fight['date']} by {fight['method']}\n")
            
            vs_md.write("\n---\n\n")
    
    # Create a file with just fighter stats and recent fights (better for chunking)
    with open('data/vector_store_fighter_stats.md', 'w') as stats_md:
        stats_md.write("# UFC Fighter Statistics\n\n")
        
        for fighter in fighters_data:
            stats_md.write(create_fighter_chunk(fighter))
            stats_md.write("\n---\n\n")
    
    print("\n" + "-"*80)
    print("MARKDOWN FILES GENERATED SUCCESSFULLY".center(80))
    print("-"*80)
    print(f"\n✅ Created {len(fighters_data)} vector-store optimized markdown files in data/vector_store_markdown/")
    print(f"✅ Created {len(fighters_data)} smaller chunk files in data/vector_store_chunks/")
    print("✅ Created combined markdown files at:")
    print("  - data/vector_store_all_fighters.md (full details)")
    print("  - data/vector_store_fighter_stats.md (stats and recent fights only)")
    
    print("\n" + "-"*80)
    print("NEXT STEPS (MANUAL)".center(80))
    print("-"*80)
    print("\nTo create the actual vector store:")
    print("1. Go to your vector store provider's website (e.g., OpenAI)")
    print("2. Upload one of the generated markdown files")
    print("3. Follow the provider's instructions to create embeddings")
    print("4. Update your app.py with the new vector store ID")
    print("\nRecommended file to upload: data/vector_store_fighter_stats.md")
    print("(This file contains the most important information in a format that's easy to chunk)")

if __name__ == "__main__":
    main() 