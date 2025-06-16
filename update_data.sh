#!/bin/bash


# scp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv /Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv Trinity:~/mma-ai-swift-app/data/
# cp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv /Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv data/

# Copy original files to local data directory
cp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv data/
cp /Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv data/

# Remove Fighter_ID_UFCStats column from fighter_info.csv for server copy
python -c "
import pandas as pd
df = pd.read_csv('/Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv')
df.drop('Fighter_ID_UFCStats', axis=1, inplace=True)
df.to_csv('/tmp/fighter_info_no_ufcstats.csv', index=False)
"

# Copy to server (modified fighter_info.csv)
scp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv Trinity:~/mma-ai-swift-app/data/
scp /tmp/fighter_info_no_ufcstats.csv Trinity:~/mma-ai-swift-app/data/fighter_info.csv

# Upcoming Event
python scripts/scrape_upcoming_event_sherdog.py
scp data/upcoming_event_data_sherdog.csv Trinity:~/mma-ai-swift-app/data/ 
rm sherdog_event_page.html

# Odds Movement
cp /Users/td/Code/odds-monitoring/UFC/Analysis/data/ufc_odds_movements.csv data/odds/