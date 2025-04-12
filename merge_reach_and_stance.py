import pandas as pd

# File paths
source_path = '/Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv'
target_path = '/Users/td/Code/mma-ai-swift-app/data/fighter_info.csv'

# Load both source and target CSVs
source_df = pd.read_csv(source_path)
target_df = pd.read_csv(target_path)

# Ensure consistent casing and no whitespace in column names
source_df.columns = source_df.columns.str.strip().str.lower()
target_df.columns = target_df.columns.str.strip().str.lower()

# Select only the columns we care about from the source
source_trimmed = source_df[['fighter_id', 'reach', 'stance']].drop_duplicates(subset='fighter_id')

# Merge source data into the target data using fighter_id
merged_df = target_df.merge(
    source_trimmed,
    on='fighter_id',
    how='left',
    suffixes=('', '_from_source')
)

# Fill missing values in target using source values and replace NaN with '-'
merged_df['reach'] = merged_df['reach'].combine_first(merged_df['reach_from_source']).fillna('-')
merged_df['stance'] = merged_df['stance'].combine_first(merged_df['stance_from_source']).fillna('-')

# Drop the temporary source columns
merged_df = merged_df.drop(columns=['reach_from_source', 'stance_from_source'])

# Rename columns as per instructions
merged_df.columns = ['Fighter', 'Nickname', 'Birth Date', 'Nationality', 'Hometown', 'Association', 'Weight Class', 'Height', 'Wins', 'Losses', 'Win_Decision', 'Win_KO', 'Win_Sub', 'Loss_Decision', 'Loss_KO', 'Loss_Sub', 'Fighter_ID', 'Reach', 'Stance']

# Save updated fighter_info.csv
merged_df.to_csv(target_path, index=False)

print(f"✅ Merged stance and reach into: {target_path}")
