#!/bin/bash

cd /home/trinity/mma-ai-swift-app

# Run Scraper
/home/trinity/.pyenv/shims/python scraper.py >> log.log 2>&1

# Remove Fighter_ID_UFCStats column from fighter_info.csv for server copy
/home/trinity/.pyenv/shims/python -c "
import pandas as pd
df = pd.read_csv('/home/trinity/mma-ai-swift-app/data/fighter_info.csv')
df.drop('Fighter_ID_UFCStats', axis=1, inplace=True)
df.to_csv('/tmp/fighter_info_no_ufcstats.csv', index=False)
"

# Query OpenAI for the upcoming Sherdog event URL
today=$(date +%Y-%m-%d)
response=$(curl "https://api.openai.com/v1/responses" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
        "model": "gpt-4o-mini",
        "tools": [{"type": "web_search_preview"}],
        "input": "Please provide the Sherdog URL for the next upcoming UFC event the upcoming Saturday from today: $today. If not this upcoming Saturday than check the one after. Use this ESPN page to find the upcoming events I wants names https://www.espn.com/mma/schedule/_/league/ufc first, then find the sherdog url of it. Provide in this format and ONLY the url as a response: ex) https://www.sherdog.com/events/UFC-316-Dvalishvili-vs-OMalley-2-107105"
    }')
echo "Response: $response"

# Extract the URL text (and trim any surrounding whitespace)
event_url=$(jq -r '
  .output[] 
  | select(.type=="message") 
  | .content[0].text
' <<<"$response" | xargs)
echo "Event URL: $event_url"

# Send Pushover notification with the found URL
if [ -n "$event_url" ]; then
  curl -s \
    --form-string "token=auyzqkk5v848crxcv356heyzqdif69" \
    --form-string "user=ucdzy7t32br76dwht5qtz5mt7fg7n3" \
    --form-string "message=Sherdog event URL: $event_url" \
    https://api.pushover.net/1/messages.json
  echo "Using URL: $event_url"
else
  curl -s \
    --form-string "token=auyzqkk5v848crxcv356heyzqdif69" \
    --form-string "user=ucdzy7t32br76dwht5qtz5mt7fg7n3" \
    --form-string "message=Failed to retrieve event URL from OpenAI." \
    https://api.pushover.net/1/messages.json
  echo "Failed to retrieve event URL from OpenAI."
fi

# Scrape Upcoming Event
echo "Using URL: $event_url"
if [ -n "$event_url" ]; then
  /home/trinity/.pyenv/shims/python scrape_upcoming_event_sherdog.py "$event_url"
else
  echo "Failed to retrieve event URL from OpenAI."
fi
rm sherdog_event_page.html
