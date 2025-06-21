from openai import OpenAI
import os
import json
import re
import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse
from datetime import datetime

client = OpenAI()

current_date = datetime.now().strftime("%Y-%m-%d")

#prompt = "Find the top 10 current and trending news stories in MMA or UFC from the last week or about upcoming events. For each, return a title, a 1-2 sentence summary, and a URL. Return as a JSON list."
#prompt = "Find the top 10 current and trending news stories in MMA or UFC from the last 10 days or about upcoming events. For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, and a URL. Return as a JSON list."
#prompt = (
#    "Find the top 10 current and trending news stories in MMA or UFC from the last 7 days or about upcoming events. "
#    "For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, and a URL. Return as a JSON list."
#)
prompt = (
    f"Find 10 current and trending news stories in MMA/UFC ONLY from the last 1-2 weeks from today's date ({current_date}). "
    "Use only news from reputable MMA news sources such as X.com, Sherdog (https://www.sherdog.com/), MMAFighting, Tapology, or similar. "
    "For each, return a title, the publication date (YYYY-MM-DD), a 1-2 sentence summary, the source name, a URL, and an image_url (if available, otherwise leave blank). "
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
    if not (isinstance(news_list, list) and all(isinstance(item, dict) and 'image_url' in item for item in news_list)):
        raise ValueError("Not a valid JSON array of objects with image_url.")
except Exception as e:
    news_list = [{"title": "Could not parse news.", "summary": str(e), "url": "", "source": "", "date": "", "image_url": ""}]

# Default logos for known sources
DEFAULT_LOGOS = {
    'Sherdog': 'https://www.sherdog.com/images/sherdog_logo.png',
    'MMAFighting': 'https://www.mmafighting.com/apple-touch-icon.png',
    'Tapology': 'https://www.tapology.com/favicon.ico',
}

def get_best_image(url, source=None):
    try:
        resp = requests.get(url, timeout=5, headers={"User-Agent": "Mozilla/5.0"})
        soup = BeautifulSoup(resp.text, 'html.parser')
        # Try og:image
        og_image = soup.find('meta', property='og:image')
        if og_image and og_image.get('content'):
            print(f"og:image found for {url}")
            return og_image['content']
        # Try twitter:image
        tw_image = soup.find('meta', attrs={'name': 'twitter:image'})
        if tw_image and tw_image.get('content'):
            print(f"twitter:image found for {url}")
            return tw_image['content']
        # Try image_src
        img_src = soup.find('link', rel='image_src')
        if img_src and img_src.get('href'):
            print(f"image_src found for {url}")
            return img_src['href']
        # Try first <img> in article body
        # Heuristic: look for <article> or <div class*='article'>
        article = soup.find('article') or soup.find('div', class_=lambda x: x and 'article' in x)
        if article:
            img = article.find('img')
        else:
            img = soup.find('img')
        if img and img.get('src'):
            print(f"First <img> found for {url}")
            return img['src']
        print(f"No image found for {url}, using default logo.")
    except Exception as e:
        print(f"Failed to get image for {url}: {e}")
    # Fallback to default logo by source
    if source and source in DEFAULT_LOGOS:
        return DEFAULT_LOGOS[source]
    # Fallback to domain favicon
    try:
        domain = urlparse(url).netloc
        return f"https://{domain}/favicon.ico"
    except:
        return ""

for item in news_list:
    if (not item.get('image_url')) and item.get('url'):
        item['image_url'] = get_best_image(item['url'], item.get('source'))

# Save to file
os.makedirs("data", exist_ok=True)
with open("data/news_daily.json", "w") as f:
    json.dump(news_list, f, indent=2)
for i, item in enumerate(news_list, 1):
    print(f"{i}. {item.get('title')}")
    print(f"   {item.get('summary')}")
    print(f"   {item.get('url')}")
    print(f"   {item.get('image_url')}")
    print() 
