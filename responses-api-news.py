from openai import OpenAI
import os
import json
import re

client = OpenAI()

#prompt = "Find the top 10 current and trending news stories in MMA or UFC from the last week or about upcoming events. For each, return a title, a 1-2 sentence summary, and a URL. Return as a JSON list."
#prompt = "Find the top 10 current and trending news stories in MMA or UFC from the last 10 days or about upcoming events. For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, and a URL. Return as a JSON list."
#prompt = (
#    "Find the top 10 current and trending news stories in MMA or UFC from the last 7 days or about upcoming events. "
#    "For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, and a URL. Return as a JSON list."
#)
prompt = (
    "Find 10 current and trending news stories in MMA/UFC from the last 1-2 weeks. "
    "Use only news from reputable MMA news sources such as Sherdog, MMAFighting, Tapology, or similar. "
    "For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, the source name, and a URL. "
    "Return ONLY a valid JSON array of 10 objects, no markdown, no bullet points, no extra text."
)

#instructions = (
#    "Only include news stories published in the last 10 days or about upcoming events. "
#    "Prioritize stories from the 'Latest News' section on Sherdog, MMAFighting, Tapology, or similar reputable MMA news sites. "
#    "Exclude anything older or from unreliable sources. Include the source name in the output."
#)
#instructions="Only include news stories published in the last 10 days or about upcoming events. Exclude anything older."

response = client.responses.create(
    model="gpt-4.1",
    #model="gpt-4.1-mini",
    #model="gpt-4.1-nano",
    #model="gpt-4o",
    tools=[{ "type": "web_search_preview" }],
    input=prompt,
    #text={"format": {"type": "json_object"}},
    #temperature=0.3,
    #max_output_tokens=1200,
    #top_p=1.0,
    #instructions=instructions
)
content = ""
if hasattr(response, "output") and isinstance(response.output, list):
    for item in response.output:
        if hasattr(item, "content"):
            for c in getattr(item, "content", []):
                if hasattr(c, "text"):
                    content = c.text
                    break
            if content:
                break
# Try to extract JSON from code fences or markdown if present
match = re.search(r"```json\\s*(\[.*?\])\\s*```", content, re.DOTALL)
if not match:
    match = re.search(r"```\\s*(\[.*?\])\\s*```", content, re.DOTALL)
if match:
    json_str = match.group(1)
else:
    json_str = content
try:
    news_list = json.loads(json_str)
    # Validate that it's a list of dicts with required keys
    if not (isinstance(news_list, list) and all(isinstance(item, dict) for item in news_list)):
        raise ValueError("Not a valid JSON array of objects.")
except Exception as e:
    news_list = [{"title": "Could not parse news.", "summary": str(e), "url": "", "source": "", "date": ""}]

# Save to file
os.makedirs("data", exist_ok=True)
with open("data/news_daily.json", "w") as f:
    json.dump(news_list, f, indent=2)
for i, item in enumerate(news_list, 1):
    print(f"{i}. {item.get('title')}")
    print(f"   {item.get('summary')}")
    print(f"   {item.get('url')}")
    print() 
