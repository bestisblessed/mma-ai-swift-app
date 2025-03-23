#!/bin/bash

scp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv /Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv Trinity:~/mma-ai-swift-app/data/
cp /Users/td/Code/mma-ai/Scrapers/data/event_data_sherdog.csv /Users/td/Code/mma-ai/Scrapers/data/fighter_info.csv data/

# Upcoming Event
python scrape_upcoming_event_sherdog.py
scp data/upcoming_event_data_sherdog.csv Trinity:~/mma-ai-swift-app/data/ 
