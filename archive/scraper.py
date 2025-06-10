### 1) Setup and Imports ###
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import warnings
import re
import csv
import os
from datetime import datetime
import glob
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
from xml.etree.ElementTree import fromstring 
import shutil
import random
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
import aiohttp
import asyncio
import nest_asyncio
from tqdm import tqdm
from tqdm.asyncio import tqdm as tqdm_async
import requests
import lxml.html
import requests
import lxml.html
import pandas as pd
import os
from tqdm.notebook import tqdm
from xml.etree.ElementTree import ElementTree
from xml.etree.ElementTree import parse
from xml.etree.ElementTree import fromstring
import csv
from bs4 import BeautifulSoup
import time
from datetime import datetime, timedelta
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException, WebDriverException
from tqdm import tqdm
from concurrent.futures import ThreadPoolExecutor, as_completed
from time import sleep
from random import uniform


### 2) Data Directory Initialization ###
if os.path.exists("data"):
    shutil.rmtree("data")
os.makedirs("data")

### 3) Sherdog Event URLs Scraping ###
urls = [
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/1',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/2',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/3',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/4',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/5',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/6',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/7',
    'https://www.sherdog.com/organizations/Ultimate-Fighting-Championship-UFC-2/recent-events/8'
]
user_agents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0"
]
headers = {"User-Agent": random.choice(user_agents)}
df = pd.read_csv('./data/event_urls_sherdog.csv') if os.path.isfile('./data/event_urls_sherdog.csv') else pd.DataFrame(columns=['Event_URL'])
existing_urls = set(df['Event_URL'])
print(f"Starting to scrape {len(urls)} URLs...")
for i, url in enumerate(urls, 1):
    print(f"Processing URL {i}/{len(urls)}")
    try:
        response = requests.get(url, headers=headers)
        soup = BeautifulSoup(response.content, 'html.parser')
        specific_div = soup.find('div', {'class': 'single_tab', 'id': 'recent_tab'})
        if specific_div:
            new_urls = [a.get('href') for a in specific_div.find_all('a', itemprop='url') if a.get('href') and a.get('href') not in existing_urls]
            df = pd.concat([df, pd.DataFrame(new_urls, columns=['Event_URL'])], ignore_index=True)
    except requests.RequestException:
        print(f"Failed to process URL {i}")
        pass
df.to_csv('./data/event_urls_sherdog.csv', index=False)
print("Updated event URLs saved.")

### 4) Sherdog: Remove Broken URLs ###
urls_to_delete = {
    "/events/UFC-233-Ultimate-Fighting-Championship-233-72021",
    "/events/UFC-Fight-Night-97-Lamas-vs-Penn-90890",
    "/events/UFC-176-Aldo-vs-Mendes-2-37609",
    "/events/UFC-151-Jones-vs-Henderson-25809"
}
df = pd.read_csv("./data/event_urls_sherdog.csv")
df = df[~df["Event_URL"].isin(urls_to_delete)]
df.to_csv("./data/event_urls_sherdog.csv", index=False)
print("Broken URLs removed.")

### 5) Sherdog: Scrape Event Dates ###
user_agents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
]
df = pd.read_csv('./data/event_urls_sherdog.csv')
df['Event_URL'] = "https://sherdog.com" + df['Event_URL'].astype(str)
event_dates = []
with requests.Session() as session:
    session.headers.update({"User-Agent": random.choice(user_agents)})
    with ThreadPoolExecutor(max_workers=40) as executor:
        futures = {executor.submit(lambda url: session.get(url, headers={"User-Agent": random.choice(user_agents)}, timeout=30), url): url for url in df['Event_URL']}
        for future in tqdm(as_completed(futures), total=len(df['Event_URL']), desc="Scraping Events", unit="Event"):
            url = futures[future]
            try:
                response = future.result()
                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    event_date_meta = soup.find('meta', itemprop='startDate')
                    event_dates.append(event_date_meta['content'].strip() if event_date_meta else None)
                else:
                    event_dates.append("Error")
            except requests.exceptions.RequestException:
                event_dates.append("Error")
df['Event Date'] = event_dates
df.to_csv('./data/event_urls_sherdog.csv', index=False)
print("Event dates appended successfully.")
print(f"Total number of rows including the header in event_urls_sherdog.csv: {len(df)}")
print(f"Column names: {list(df.columns)}")

### 6) Sherdog: Event Data Extraction ###
warnings.filterwarnings("ignore", category=FutureWarning)
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
}
urls_df = pd.read_csv('data/event_urls_sherdog.csv')
all_data = []
def fetch_event_data(url, session):
    full_url = f'https://sherdog.com{url}' if not url.startswith('http') else url
    event_data = []
    try:
        with session.get(full_url, headers=headers) as response:
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                event_name = soup.find('span', itemprop='name').text.strip()
                event_location = soup.find('span', itemprop='location').text.strip()
                event_date = soup.find('meta', itemprop='startDate')['content'].strip()
                main_event_fighters = soup.find_all('div', class_='fighter')
                if main_event_fighters:
                    fighter1 = main_event_fighters[0].find('span', itemprop='name').text.strip()
                    fighter2 = main_event_fighters[1].find('span', itemprop='name').text.strip()
                    fighter1_id = main_event_fighters[0].find('a', itemprop='url')['href'].split('-')[-1]
                    fighter2_id = main_event_fighters[1].find('a', itemprop='url')['href'].split('-')[-1]
                    weight_class = soup.find('span', class_='weight_class').text.strip()
                    winning_fighter = fighter1  
                    winning_method_em = soup.find('em', string='Method').parent
                    winning_method = winning_method_em.contents[2].strip()
                    winning_round_em = soup.find('em', string='Round').parent
                    winning_round = winning_round_em.contents[2].strip()
                    winning_time_em = soup.find('em', string='Time').parent
                    winning_time = winning_time_em.contents[2].strip()
                    referee_em = soup.find('em', string='Referee').parent
                    referee = referee_em.find('a').text.strip()
                    event_data.append({
                        'Event Name': event_name,
                        'Event Location': event_location,
                        'Event Date': event_date,
                        'Fighter 1': fighter1,
                        'Fighter 2': fighter2,
                        'Fighter 1 ID': fighter1_id,
                        'Fighter 2 ID': fighter2_id,
                        'Weight Class': weight_class,
                        'Winning Fighter': winning_fighter,
                        'Winning Method': winning_method,
                        'Winning Round': winning_round,
                        'Winning Time': winning_time,
                        'Referee': referee,
                        'Fight Type': 'Main Event'
                    })
                other_bouts = soup.find_all('tr', itemprop='subEvent')
                for bout in other_bouts:
                    fighters = bout.find_all('div', class_='fighter_list')
                    if len(fighters) >= 2:
                        fighter1 = fighters[0].find('img')['title']
                        fighter2 = fighters[1].find('img')['title']
                        fighter1_url = fighters[0].find('a', itemprop='url')['href']
                        fighter2_url = fighters[1].find('a', itemprop='url')['href']
                        fighter1_id = fighter1_url.split('-')[-1]
                        fighter2_id = fighter2_url.split('-')[-1]
                        weight_class = bout.find('span', class_='weight_class')
                        weight_class = weight_class.text.strip() if weight_class else "Unknown"
                        winning_method = bout.find('td', class_='winby').find('b').get_text(strip=True)
                        winning_round = bout.find_all('td')[-2].get_text(strip=True)
                        winning_time = bout.find_all('td')[-1].get_text(strip=True)
                        referee = bout.find('td', class_='winby').find('a').get_text(strip=True)
                        event_data.append({
                            'Event Name': event_name,
                            'Event Location': event_location,
                            'Event Date': event_date,
                            'Fighter 1': fighter1,
                            'Fighter 2': fighter2,
                            'Fighter 1 ID': fighter1_id,
                            'Fighter 2 ID': fighter2_id,
                            'Weight Class': weight_class,
                            'Winning Fighter': fighter1,  
                            'Winning Method': winning_method,
                            'Winning Round': winning_round,
                            'Winning Time': winning_time,
                            'Referee': referee,
                            'Fight Type': 'Undercard'
                        })
        return event_data
    except Exception as e:
        print(f"Request failed for {full_url}: {e}")
        return None
session = requests.Session()
total_urls = len(urls_df['Event_URL'])
completed_requests = 0
with concurrent.futures.ThreadPoolExecutor(max_workers=30) as executor:
    futures = [executor.submit(fetch_event_data, url, session) for url in urls_df['Event_URL']]
    for future in concurrent.futures.as_completed(futures):
        data = future.result()
        completed_requests += 1
        progress_percentage = (completed_requests / total_urls) * 100
        print(f"Completed {completed_requests}/{total_urls} requests ({progress_percentage:.2f}%)")
        if data:
            all_data.extend(data)
df = pd.DataFrame(all_data)
file_path = './data/event_data_sherdog.csv'
write_mode = 'a' if os.path.isfile(file_path) else 'w'
df.to_csv(file_path, mode=write_mode, header=not os.path.isfile(file_path), index=False)
print("Data successfully written to data/event_data_sherdog.csv")
print(f"Total number of rows: {len(df)}")
print(f"Column names: {list(df.columns)}")
df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
df.to_csv(file_path, index=False)

### 7) Sherdog: Fighter IDs Extraction ###
df = pd.read_csv('./data/event_data_sherdog.csv')
df2 = pd.DataFrame(columns=['Fighter', 'Fighter_ID'])
df2.to_csv('./data/fighter_id_sherdog.csv', index=False)
for index, row in df.iterrows():
    fighter1 = row['Fighter 1']
    fighter2 = row['Fighter 2']
    fighter1_id = row['Fighter 1 ID']
    fighter2_id = row['Fighter 2 ID']
    for fighter, fighter_id in zip([fighter1, fighter2], [fighter1_id, fighter2_id]):
        if fighter not in df2['Fighter'].values and fighter_id not in df2['Fighter_ID'].values:
            df2 = pd.concat([df2, pd.DataFrame([{'Fighter': fighter, 'Fighter_ID': fighter_id}])])
df2.to_csv('./data/fighter_id_sherdog.csv', index=False)
print("Data successfully written to data/fighter_id_sherdog.csv")
print(f"Total number of rows: {len(df2)}")
print(f"Column names: {list(df2.columns)}")

### 8) Sherdog: Remove Nicknames from Fighter Names ###
df = pd.read_csv('./data/fighter_id_sherdog.csv')
df['Fighter'] = df['Fighter'].str.replace(r" '.+?'", "", regex=True)
df.to_csv('./data/fighter_id_sherdog.csv', index=False)
df = pd.read_csv('./data/event_data_sherdog.csv')
for col in ['Fighter 1', 'Fighter 2', 'Winning Fighter']:
    df[col] = df[col].str.replace(r" '.+?'", "", regex=True)
df.to_csv('./data/event_data_sherdog.csv', index=False)

### 9) Sherdog: Add UFC Indicator ###
df = pd.read_csv('./data/fighter_id_sherdog.csv')
df['UFC'] = 'y'
df.to_csv('./data/fighter_id_sherdog.csv', index=False)
df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
df.to_csv('./data/fighter_id_sherdog.csv', index=False)

### 10) Sherdog: Fighter Info Scraping ###
def scrape_fighter_general_info_sherdog(fighter, fighter_id):
    url = f'https://www.sherdog.com/fighter/{fighter_id}'
    headers = {"User-Agent": "'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'"}
    max_retries = 6
    retry_count = 0
    while retry_count < max_retries:
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                break
        except (requests.exceptions.ConnectionError, requests.exceptions.RequestException) as e:
            retry_count += 1
            if retry_count == max_retries:
                print(f"Failed to fetch data for fighter {fighter} after {max_retries} retries")
                return {}
            print(f"Connection error, retrying in 10 seconds... (Attempt {retry_count}/{max_retries})")
            time.sleep(10)
            continue
    if response.status_code != 200:
        return {}
    soup = BeautifulSoup(response.content, 'html.parser')
    fighter_dict = {}
    try:
        fighter_data = soup.find('div', class_='fighter-data')
    except AttributeError:
        fighter_data = None
    try:
        birthdate = soup.find('span', itemprop='birthDate')
        birthdate = (birthdate.text).strip('""')
    except AttributeError:
        birthdate = '-'
    try:
        nationality = soup.find('strong', itemprop='nationality')
        nationality = (nationality.text).strip()
    except AttributeError:
        nationality = '-'
    try:
        hometown = soup.find('span', {'itemprop': 'addressLocality'}).text
        hometown = hometown.strip()
    except AttributeError:
        hometown = '-'
    try:
        association = soup.find('span', {'itemprop': 'name'}).text
        association = association.strip()
    except AttributeError:
        association = '-'
    try:
        weight_class_div = fighter_data.find('div', {'class': 'association-class'})
        links = weight_class_div.find_all('a')
        weight_class = links[-1].text
        weight_class = weight_class.strip()
    except (AttributeError, IndexError):
        weight_class = ''
    try:
        nickname = soup.find('span', class_='nickname')
        nickname = (nickname.text).strip('"')
    except AttributeError:
        nickname = '-'
    try:
        height = soup.find('b', itemprop='height')
        height = (height.text).strip('"')
    except AttributeError:
        height = '-'
    try:
        wins = soup.find('div', class_='winloses win').find_all('span')[1]
        wins = (wins.text).strip()
    except AttributeError:
        wins = '-'
    try:
        losses = soup.find('div', class_='winloses lose').find_all('span')[1]
        losses = (losses.text).strip()
    except AttributeError:
        losses = '-'
    dec_data_list = []
    try:
        win_type = fighter_data.find_all('div', class_='meter-title', string='DECISIONS')
        for method in win_type:
            if method.text.startswith('DECISIONS'):
                dec_data = method.find_next('div', class_='pl').text
                dec_data_list.append(dec_data)
        wins_dec = (dec_data_list[0]).strip()
        losses_dec = (dec_data_list[1]).strip()
    except (AttributeError, IndexError):
        wins_dec = '-'
        losses_dec = '-'
    ko_data_list = []
    try:
        win_type = soup.find_all('div', class_='meter-title')
        for method in win_type:
            if method.text.startswith('KO'):
                ko_data = method.find_next('div', class_='pl').text
                ko_data_list.append(ko_data)
        wins_ko = (ko_data_list[0]).strip()
        losses_ko = (ko_data_list[1]).strip()
    except (AttributeError, IndexError):
        wins_ko = '-'
        losses_ko = '-'
    sub_data_list = []
    try:
        win_type = fighter_data.find_all('div', class_='meter-title', string='SUBMISSIONS')
        for method in win_type:
            if method.text.startswith('SUBMISSIONS'):
                sub_data = method.find_next('div', class_='pl').text
                sub_data_list.append(sub_data)
        wins_sub = (sub_data_list[0]).strip()
        losses_sub = (sub_data_list[1]).strip()
    except (AttributeError, IndexError):
        wins_sub = '-'
        losses_sub = '-'
    fighter_dict = {
        'Fighter': fighter,
        'Nickname': nickname,
        'Birth Date': birthdate,
        'Nationality': nationality,
        'Hometown': hometown,
        'Association': association,
        'Weight Class': weight_class,
        'Height': height,
        'Wins': wins,
        'Losses': losses,
        'Win_Decision': wins_dec,
        'Win_KO': wins_ko,
        'Win_Sub': wins_sub,
        'Loss_Decision': losses_dec,
        'Loss_KO': losses_ko,
        'Loss_Sub': losses_sub,
        'Fighter_ID': fighter_id
    }
    return fighter_dict
def scrape_fighters_concurrently():
    warnings.filterwarnings("ignore", category=FutureWarning)
    df_fighter_id = pd.read_csv('./data/fighter_id_sherdog.csv')
    fighter_data_list = []
    total_fighters = len(df_fighter_id)
    fighters_processed = 0
    with ThreadPoolExecutor(max_workers=40) as executor:
        future_to_fighter = {executor.submit(scrape_fighter_general_info_sherdog, row['Fighter'], row['Fighter_ID']): row for index, row in df_fighter_id.iterrows()}
        for future in tqdm(as_completed(future_to_fighter), total=len(future_to_fighter)):
            fighter_data = future.result()
            if fighter_data:
                fighter_data_list.append(fighter_data)
            fighters_processed += 1
            print(f"Scraping Fighter Info: {fighters_processed}/{total_fighters} fighters processed")
    new_df = pd.DataFrame(fighter_data_list)
    new_df.to_csv('./data/fighter_info.csv', index=False)
scrape_fighters_concurrently()
df = pd.read_csv('./data/fighter_info.csv')
df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
df.to_csv('./data/fighter_info.csv', index=False)
print("Data successfully written to data/fighter_info.csv")
print(f"Total number of rows: {len(df)}")
print(f"Column names: {list(df.columns)}")


# Sherdog: Fighters
# data/fighters/*

### 11) Sherdog: Fighters - Asynchronous Scraping ###
nest_asyncio.apply()
os.makedirs('./data/fighters/', exist_ok=True)
df_fighter_id = pd.read_csv('./data/fighter_id_sherdog.csv')
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36'
}
async def fetch_fighter_data(session, fighter_name, fighter_id):
    url = f"https://www.sherdog.com/fighter/{fighter_name.replace(' ', '-')}-{fighter_id}"
    for _ in range(6):
        try:
            async with session.get(url, headers=HEADERS, timeout=aiohttp.ClientTimeout(total=60), raise_for_status=True) as response:
                return fighter_name, fighter_id, await response.text()
        except aiohttp.ClientResponseError as e:
            if e.status == 429:
                print(f"Rate limited on {fighter_name}. Sleeping for 10 sec...")
                await asyncio.sleep(10)
            else:
                print(f"HTTP error {e.status} on {fighter_name}. Retrying...")
        except asyncio.TimeoutError:
            print(f"Timeout error on {fighter_name}. Retrying...")
        except aiohttp.ClientError as e:
            print(f"Request error for {fighter_name}: {e}")
        await asyncio.sleep(11)
    return fighter_name, fighter_id, None
async def parse_fighter_data(session, fighter_name, fighter_id):
    _, _, html = await fetch_fighter_data(session, fighter_name, fighter_id)
    if not html:
        return None
    soup = BeautifulSoup(html, 'html.parser')
    table = soup.find('table', {'class': 'new_table fighter'})
    rows = table.find_all('tr')[1:] if table else []
    fight_data = []
    for row in rows:
        cols = row.find_all('td')
        fight_dict = {
            'Result': cols[0].text.strip(),
            'Opponent': cols[1].find('a').text.strip() if cols[1].find('a') else '-',
            'Event Date': cols[2].find_all('span')[-1].text.strip() if cols[2].find_all('span') else '-',
            'Method/Referee': cols[3].text.strip().split('\n')[0],
            'Rounds': cols[4].text.strip(),
            'Time': cols[5].text.strip()
        }
        fight_data.append(fight_dict)
    return fighter_name, fighter_id, fight_data
async def main():
    connector = aiohttp.TCPConnector(limit=10)
    async with aiohttp.ClientSession() as session:
        tasks = [
            parse_fighter_data(session, row['Fighter'], row['Fighter_ID'])
            for _, row in df_fighter_id.iterrows()
        ]
        results = await tqdm_async.gather(*tasks)
    for fighter_name, fighter_id, fight_data in results:
        if fight_data:
            output_file = f"./data/fighters/{fighter_name.replace(' ', '_')}_{fighter_id}.csv"
            pd.DataFrame(fight_data).to_csv(output_file, index=False)
asyncio.get_event_loop().run_until_complete(main())


### 12) Sherdog: Cleaning and Deduplication ###
fighter_info_df = pd.read_csv('./data/fighter_info.csv')
event_data_df = pd.read_csv('./data/event_data_sherdog.csv')
print(f"Number of rows in fighter_info.csv: {len(fighter_info_df)}")
print(f"Number of rows in event_data_sherdog.csv: {len(event_data_df)}")
fighter_info_df = fighter_info_df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
event_data_df = event_data_df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
print(f"Dropped {fighter_info_df.drop_duplicates(inplace=True)} duplicates from fighter_info_df")
print(f"Dropped {event_data_df.drop_duplicates(inplace=True)} duplicates from event_data_df")
fighter_info_df.to_csv('./data/fighter_info.csv', index=False)
event_data_df.to_csv('./data/event_data_sherdog.csv', index=False)
print(f"Number of rows in fighter_info.csv: {len(fighter_info_df)}")
print(f"Number of rows in event_data_sherdog.csv: {len(event_data_df)}")


### 13) GitHub: Download Data ###
os.makedirs('./data/github/', exist_ok=True)
urls = [
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_event_details.csv',
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_fight_details.csv',
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_fight_results.csv',
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_fight_stats.csv',
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_fighter_details.csv',
    'https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/main/ufc_fighter_tott.csv'
]
for url in urls:
    filename = os.path.join('./data/github/', url.split('/')[-1])
    response = requests.get(url)
    if response.status_code == 200:
        with open(filename, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded: {filename}")
    else:
        print(f"Failed to download: {url}")
for url in urls:
    filename = os.path.join('./data/github/', url.split('/')[-1])
    df = pd.read_csv(filename)
    print(f"Total rows in {filename}: {len(df)}")

### 14) GitHub: Cleaning and Merging ###
ufc_fighter_tott = pd.read_csv("data/github/ufc_fighter_tott.csv")
ufc_fighter_details = pd.read_csv("data/github/ufc_fighter_details.csv")
print(f"Total rows in ufc_fighter_tott: {len(ufc_fighter_tott)}")
print(f"Total rows in ufc_fighter_details: {len(ufc_fighter_details)}")
merged_df = pd.merge(ufc_fighter_tott, ufc_fighter_details[['URL', 'NICKNAME']], on='URL', how='left')
matching_count = merged_df['NICKNAME'].notnull().sum()
print(f"Found {matching_count} matching URL entries.")
print(f"Total rows in master: {len(merged_df)}")
merged_df.to_csv("data/github/master_fighters.csv", index=False)
os.remove("data/github/ufc_fighter_details.csv")
os.remove("data/github/ufc_fighter_tott.csv")
print("Deleted files: data/github/ufc_fighter_details.csv and data/github/ufc_fighter_tott.csv")
os.remove("data/github/ufc_fight_details.csv")
print("Deleted, don't need this shit: data/github/ufc_fight_details.csv")
event_details_df = pd.read_csv('./data/github/ufc_event_details.csv')
event_details_df.rename(columns={'URL': 'EVENT_URL'}, inplace=True)
event_details_df.to_csv('./data/github/ufc_event_details.csv', index=False)
event_details_df = pd.read_csv('./data/github/ufc_event_details.csv')
fight_results_df = pd.read_csv('./data/github/ufc_fight_results.csv')
event_details_df['EVENT'] = event_details_df['EVENT'].str.strip()
fight_results_df['EVENT'] = fight_results_df['EVENT'].str.strip()
print(f"Rows in event_details_df: {len(event_details_df)}")
print(f"Rows in fight_results_df: {len(fight_results_df)}")
merged_df = pd.merge(fight_results_df, event_details_df[['EVENT', 'DATE', 'LOCATION', 'EVENT_URL']], on='EVENT', how='left')
merged_df.to_csv('./data/github/master_fights.csv', index=False)
matches_found = len(merged_df)
print(f"Rows in master_fights.csv: {matches_found}")
print('Saved to ./data/github/master_fights.csv')
os.remove("data/github/ufc_event_details.csv")
os.remove("data/github/ufc_fight_results.csv")
print("Deleted original files: data/github/ufc_event_details.csv and data/github/ufc_fight_results.csv")

### 15) GitHub: Merge REACH and STANCE from master_fighters.csv to fighter_info.csv ###
master_df = pd.read_csv('./data/github/master_fighters.csv')
fighter_info_df = pd.read_csv('./data/fighter_info.csv')
fighter_info_df['Fighter_CLEAN'] = fighter_info_df['Fighter'].str.lower().str.strip().str.replace(r'[^\w\s]', '', regex=True)
master_df['FIGHTER_CLEAN'] = master_df['FIGHTER'].str.lower().str.strip().str.replace(r'[^\w\s]', '', regex=True)
master_df['REACH'] = master_df['REACH'].replace('--', np.nan)
master_df['STANCE'] = master_df['STANCE'].replace('--', np.nan)
deduped_master = master_df[~master_df['FIGHTER_CLEAN'].duplicated(keep=False)]
merged_cleaned_df = fighter_info_df.merge(
    deduped_master[['FIGHTER_CLEAN', 'REACH', 'STANCE', 'URL']],
    left_on='Fighter_CLEAN',
    right_on='FIGHTER_CLEAN',
    how='left'
)
merged_cleaned_df.rename(columns={'REACH': 'Reach'}, inplace=True)
merged_cleaned_df.rename(columns={'STANCE': 'Stance'}, inplace=True)
merged_cleaned_df.rename(columns={'URL': 'Fighter_ID_UFCStats'}, inplace=True)
merged_cleaned_df['Fighter_ID_UFCStats'] = merged_cleaned_df['Fighter_ID_UFCStats'].str.extract(r'fighter-details/([a-zA-Z0-9]+)')
merged_cleaned_df.drop(columns=['Fighter_CLEAN', 'FIGHTER_CLEAN'], inplace=True)
merged_cleaned_df.to_csv('data/fighter_info.csv', index=False)
reach_match_count = merged_cleaned_df['Reach'].notna().sum()
reach_missing_count = merged_cleaned_df['Reach'].isna().sum()
print("Reach merged:", reach_match_count)
print("Reach missing:", reach_missing_count)
stance_match_count = merged_cleaned_df['Stance'].notna().sum()
stance_missing_count = merged_cleaned_df['Stance'].isna().sum()
print("Stance merged:", stance_match_count)
print("Stance missing:", stance_missing_count)
url_match_count = merged_cleaned_df['Fighter_ID_UFCStats'].notna().sum()
url_missing_count = merged_cleaned_df['Fighter_ID_UFCStats'].isna().sum()
print("Fighter_ID_UFCStats merged:", url_match_count)
print("Fighter_ID_UFCStats missing:", url_missing_count)

### 16) GitHub: Second Pass (Substring Match) ###
fighter_info_df = pd.read_csv('data/fighter_info.csv')
master_df = pd.read_csv('./data/github/master_fighters.csv')
fighter_info_df['Fighter_CLEAN'] = (
    fighter_info_df['Fighter']
    .str.lower()
    .str.strip()
    .str.replace(r'[^\w\s]', '', regex=True)
)
master_df['FIGHTER_CLEAN'] = (
    master_df['FIGHTER']
    .str.lower()
    .str.strip()
    .str.replace(r'[^\w\s]', '', regex=True)
)
master_df['REACH'] = master_df['REACH'].replace('--', np.nan)
master_df['STANCE'] = master_df['STANCE'].replace('--', np.nan)
deduped_master = master_df[~master_df['FIGHTER_CLEAN'].duplicated(keep=False)]
missing_mask = fighter_info_df['Fighter_ID_UFCStats'].isna()
unmatched_df = fighter_info_df.loc[missing_mask].copy()
additional_matches = 0
matched_rows = []
for idx, row in unmatched_df.iterrows():
    fi_clean = row['Fighter_CLEAN']
    possible = deduped_master[deduped_master['FIGHTER_CLEAN'].str.contains(fi_clean, na=False)]
    if len(possible) == 1:
        match_row = possible.iloc[0]
        fighter_info_df.loc[idx, 'Reach'] = match_row['REACH']
        fighter_info_df.loc[idx, 'Stance'] = match_row['STANCE']
        if pd.notna(match_row['URL']):
            new_id = pd.Series(match_row['URL']).str.extract(r'fighter-details/([a-zA-Z0-9]+)').iloc[0,0]
            fighter_info_df.loc[idx, 'Fighter_ID_UFCStats'] = new_id
        additional_matches += 1
        matched_rows.append({
            'Matched Name (Fighter Info)': row['Fighter'],
            'Matched Name (Master)': match_row['FIGHTER'],
            'Fighter_ID': new_id if pd.notna(match_row['URL']) else None
        })
fighter_info_df.drop(columns=['Fighter_CLEAN'], errors='ignore', inplace=True)
fighter_info_df.to_csv('data/fighter_info.csv', index=False)
print(f"Additional matches found by second pass: {additional_matches}")
print(additional_matches)
reach_match_count = fighter_info_df['Reach'].notna().sum()
reach_missing_count = fighter_info_df['Reach'].isna().sum()
print("Final - Reach merged:", reach_match_count)
print("Final - Reach missing:", reach_missing_count)
stance_match_count = fighter_info_df['Stance'].notna().sum()
stance_missing_count = fighter_info_df['Stance'].isna().sum()
print("Final - Stance merged:", stance_match_count)
print("Final - Stance missing:", stance_missing_count)
url_match_count = fighter_info_df['Fighter_ID_UFCStats'].notna().sum()
url_missing_count = fighter_info_df['Fighter_ID_UFCStats'].isna().sum()
print("Final - Fighter_ID_UFCStats merged:", url_match_count)
print("Final - Fighter_ID_UFCStats missing:", url_missing_count)
if matched_rows:
    matched_df = pd.DataFrame(matched_rows)
    print("\n✅ Fighters matched in second pass:")
    print(matched_df.to_string(index=False))
else:
    print("\n❌ No matches found in second pass.")

### 17) GitHub: Third Pass (Fuzzy Match) ###
import difflib
bad_fuzzy_matches = {
    'yana santos': '5078e1dacf9d25f4',
}
merged_cleaned_df = pd.read_csv('data/fighter_info.csv')
original_df = merged_cleaned_df.copy()
master_df = pd.read_csv('./data/github/master_fighters.csv')
merged_cleaned_df['Fighter_CLEAN'] = merged_cleaned_df['Fighter'].str.lower().str.strip().str.replace(r'[^\w\s]', '', regex=True)
master_df['FIGHTER_CLEAN'] = master_df['FIGHTER'].str.lower().str.strip().str.replace(r'[^\w\s]', '', regex=True)
deduped_master = master_df[~master_df['FIGHTER_CLEAN'].duplicated(keep=False)]
master_names = deduped_master['FIGHTER_CLEAN'].tolist()
missing_mask = merged_cleaned_df['Fighter_ID_UFCStats'].isna()
merged_cleaned_df.loc[missing_mask, 'Fighter_ID_UFCStats'] = merged_cleaned_df.loc[missing_mask, 'Fighter_CLEAN'].apply(
    lambda x: (
        pd.NA if (
            (close := difflib.get_close_matches(x, master_names, n=1, cutoff=0.85)) and
            (match_id := re.search(
                r'fighter-details/([a-zA-Z0-9]+)',
                str(deduped_master.loc[deduped_master['FIGHTER_CLEAN'] == close[0], 'URL'].values[0])
            )) and
            bad_fuzzy_matches.get(x) == match_id.group(1)
        ) else (
            match_id.group(1) if close and match_id else pd.NA
        )
    )
)
original_missing = missing_mask.sum()
new_missing = merged_cleaned_df['Fighter_ID_UFCStats'].isna().sum()
fuzzy_matches_added = original_missing - new_missing
print("Additional fuzzy matches added:", fuzzy_matches_added)
merged_cleaned_df.drop(columns=['Fighter_CLEAN', 'FIGHTER_CLEAN'], inplace=True, errors='ignore')
merged_cleaned_df.to_csv('data/fighter_info.csv', index=False)
master_df['Fighter_ID_UFCStats'] = master_df['URL'].str.extract(r'fighter-details/([a-zA-Z0-9]+)')
original_df_ids = original_df[original_df['Fighter_ID_UFCStats'].notna()]['Fighter'].tolist()
fuzzy_only = merged_cleaned_df[
    (merged_cleaned_df['Fighter_ID_UFCStats'].notna()) &
    (~merged_cleaned_df['Fighter'].isin(original_df_ids))
]
comparison_table = fuzzy_only.merge(
    master_df[['FIGHTER', 'Fighter_ID_UFCStats']],
    on='Fighter_ID_UFCStats',
    how='left'
)[['Fighter', 'FIGHTER', 'Fighter_ID_UFCStats']].rename(columns={
    'Fighter': 'Fighter_Info_Name',
    'FIGHTER': 'Matched_Master_Name'
})
print("\nFuzzy Match Comparison Table:")
print(comparison_table.to_string(index=True))

### 18) GitHub: Fourth Pass (DOB Match) ###
fighter_info_df = pd.read_csv('data/fighter_info.csv')
master_df = pd.read_csv('./data/github/master_fighters.csv')
fighter_info_df['birth_date_clean'] = pd.to_datetime(fighter_info_df['Birth Date'], errors='coerce')
master_df['birth_date_clean'] = pd.to_datetime(master_df['DOB'], errors='coerce')
master_df['REACH'] = master_df['REACH'].replace('--', np.nan)
master_df['STANCE'] = master_df['STANCE'].replace('--', np.nan)
missing_mask = fighter_info_df['Fighter_ID_UFCStats'].isna()
unmatched_df = fighter_info_df.loc[missing_mask].copy()
used_ids = fighter_info_df['Fighter_ID_UFCStats'].dropna().unique().tolist()
master_df['Fighter_ID_UFCStats'] = master_df['URL'].str.extract(r'fighter-details/([a-zA-Z0-9]+)')
master_deduped = master_df[~master_df['Fighter_ID_UFCStats'].isin(used_ids)].copy()
dob_matches = unmatched_df.merge(
    master_deduped[['FIGHTER', 'REACH', 'STANCE', 'URL', 'birth_date_clean', 'Fighter_ID_UFCStats']],
    on='birth_date_clean',
    how='left',
    suffixes=('', '_master')
)
match_counts = dob_matches['Fighter'].value_counts()
fighters_with_one_match = match_counts[match_counts == 1].index
dob_matches = dob_matches[dob_matches['Fighter'].isin(fighters_with_one_match)]
additional_matches = 0
for idx, row in dob_matches.iterrows():
    fighter_idx = fighter_info_df[fighter_info_df['Fighter'] == row['Fighter']].index
    if not fighter_idx.empty:
        if pd.notna(row['REACH']):
            fighter_info_df.loc[fighter_idx, 'Reach'] = row['REACH']
        if pd.notna(row['STANCE']):
            fighter_info_df.loc[fighter_idx, 'Stance'] = row['STANCE']
        if pd.notna(row['URL']):
            new_id = pd.Series(row['URL']).str.extract(r'fighter-details/([a-zA-Z0-9]+)').iloc[0, 0]
            fighter_info_df.loc[fighter_idx, 'Fighter_ID_UFCStats'] = new_id
        additional_matches += 1
fighter_info_df.drop(columns=['birth_date_clean'], errors='ignore', inplace=True)
fighter_info_df.to_csv('data/fighter_info.csv', index=False)
print(f"Additional matches found by DOB pass: {additional_matches}")
reach_match_count = fighter_info_df['Reach'].notna().sum()
reach_missing_count = fighter_info_df['Reach'].isna().sum()
print("Final - Reach merged:", reach_match_count)
print("Final - Reach missing:", reach_missing_count)
stance_match_count = fighter_info_df['Stance'].notna().sum()
stance_missing_count = fighter_info_df['Stance'].isna().sum()
print("Final - Stance merged:", stance_match_count)
print("Final - Stance missing:", stance_missing_count)
url_match_count = fighter_info_df['Fighter_ID_UFCStats'].notna().sum()
url_missing_count = fighter_info_df['Fighter_ID_UFCStats'].isna().sum()
print("Final - Fighter_ID_UFCStats merged:", url_match_count)
print("Final - Fighter_ID_UFCStats missing:", url_missing_count)

### 19) GitHub: Manual Merging the Rest ###
fighter_info_df = pd.read_csv('data/fighter_info.csv')
master_df = pd.read_csv('./data/github/master_fighters.csv')
master_df['Fighter_ID_UFCStats'] = master_df['URL'].str.extract(r'fighter-details/([a-zA-Z0-9]+)')
manual_matches = {
    'Steve Erceg': 'Stephen Erceg',
    'Ateba Abega Gautier': 'Ateba Gautier',
    'Mick Parkin': 'Michael Parkin',
    'Kangjie Zhu': 'Zhu Kangjie',
    'Jingliang Li': 'Li Jingliang',
    'Shuai Yin': 'Shuai Yin',
    'Yunfeng Li': 'Li Yunfeng',
    'Kait Blink\' Kara-France': 'Kai Kara-France',
    'Yana Santos': 'Yana Kunitskaya',
    'Rayanne dos Santos': 'Rayanne Amanda',
    'Josefine Lindgren Knutsson': 'Josefine Knutsson',
    'Niushiyue Ji': 'Ji Niushiyue',
    'Nathan Maness': 'Nate Maness',
    'Abusupiyan Magomedov': 'Abus Magomedov',
    'Kaiwen Li': 'Li Kaiwen',
    'Valentine Woodburn': 'Val Woodburn',
    'Jiahefu Wuziazibieke': 'Wuziazibieke Jiahefu',
    "KyleArce Knight' Daukaus": 'Kyle Daukaus'
}
for info_name, master_name in manual_matches.items():
    info_idx = fighter_info_df[fighter_info_df['Fighter'] == info_name].index
    master_row = master_df[master_df['FIGHTER'] == master_name]
    if not info_idx.empty and not master_row.empty:
        master_row = master_row.iloc[0]
        fighter_info_df.loc[info_idx, 'Reach'] = master_row['REACH']
        fighter_info_df.loc[info_idx, 'Stance'] = master_row['STANCE']
        fighter_info_df.loc[info_idx, 'Fighter_ID_UFCStats'] = master_row['Fighter_ID_UFCStats']
fighter_info_df.to_csv('data/fighter_info.csv', index=False)
print("✅ Manual merges applied for confirmed matches.")
missing_rows = fighter_info_df[fighter_info_df['Fighter_ID_UFCStats'].isna()]
print(f"\n❗ Remaining fighters missing UFC Stats ID: {len(missing_rows)}")
print(missing_rows[['Fighter', 'Birth Date']].to_string(index=False))

### 20) Tapology: Create Directories ###
os.makedirs('./data/tapology', exist_ok=True)

### 21) Tapology: Get sitemap.xml ###
sitemap_url = 'https://www.tapology.com/sitemap.xml'
response = requests.get(sitemap_url)
if response.status_code == 200:
    with open('./data/tapology/sitemap.xml', 'w') as file:
        file.write(response.text)
    print('Sitemap has been successfully downloaded and saved.')
else:
    print(f'Failed to download the sitemap. HTTP status code: {response.status_code}')
time.sleep(5)

### 22) Tapology: Get Fighter URLs ###
urls = []
base_url = 'https://www.tapology.com/fightcenter/fighters/sitemap'
total_sitemaps = 114
for i in range(1, total_sitemaps + 1):
    sitemap_url = f'{base_url}_{i}.xml' if i > 1 else f'{base_url}.xml'
    response = requests.get(sitemap_url)
    if response.status_code == 200:
        root = fromstring(response.content)
        for sitemap in root.findall('{http://www.sitemaps.org/schemas/sitemap/0.9}url'):
            loc = sitemap.find('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')
            if loc is not None:
                urls.append([loc.text])
        print(f'Processed sitemap {i}/{total_sitemaps}')
with open('./data/tapology/fighter_urls_tapology.csv', mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['URL'])
    writer.writerows(urls)
print('Finished saving fighter URLs to fighter_urls_tapology.csv')
time.sleep(5)

### 23) Tapology: Get Bout URLs ###
urls = []
base_url = 'https://www.tapology.com/fightcenter/bouts/sitemap'
total_sitemaps = 222
for i in range(1, total_sitemaps + 1):
    sitemap_url = f'{base_url}_{i}.xml' if i > 1 else f'{base_url}.xml'
    response = requests.get(sitemap_url)
    if response.status_code == 200:
        root = fromstring(response.content)
        for sitemap in root.findall('{http://www.sitemaps.org/schemas/sitemap/0.9}url'):
            loc = sitemap.find('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')
            if loc is not None:
                urls.append([loc.text])
        print(f'Processed sitemap {i}/{total_sitemaps}')
        time.sleep(.5)
with open('./data/tapology/bout_urls_tapology.csv', mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['URL'])
    writer.writerows(urls)
print('Finished saving bout URLs to bout_urls_tapology.csv')
time.sleep(5)

### 24) Tapology: Get Event URLs ###
urls = []
base_url = 'https://www.tapology.com/events/sitemap'
total_sitemaps = 35
for i in range(1, total_sitemaps + 1):
    sitemap_url = f'{base_url}.xml' if i == 1 else f'{base_url}_{i}.xml'
    response = requests.get(sitemap_url)
    if response.status_code == 200:
        root = fromstring(response.content)
        for sitemap in root.findall('{http://www.sitemaps.org/schemas/sitemap/0.9}url'):
            loc = sitemap.find('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')
            if loc is not None:
                urls.append([loc.text])
        print(f'Processed event sitemap {i}/{total_sitemaps}')
        time.sleep(.5)
with open('./data/tapology/event_urls_tapology.csv', mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(['URL'])
    writer.writerows(urls)
print('Finished saving event URLs to event_urls_tapology.csv')

### 25) Tapology: Filter Only UFC Event URLs ###
df = pd.read_csv('data/tapology/event_urls_tapology.csv')
ufc_urls = df[df['URL'].str.contains('-ufc-', case=False, na=False) & ~df['URL'].str.contains('road-to-ufc', case=False, na=False) & ~df['URL'].str.contains('invitational', case=False, na=False)]
ufc_urls.to_csv('data/tapology/event_urls_tapology_ufc.csv', index=False)
print(f"Filtered {len(ufc_urls)} UFC event URLs")

### 26) Tapology: Merge Tapology URL to fighter_info.csv and Drop Duplicates ###
fighter_info_path = "data/fighter_info.csv"
fighter_urls_path = "data/tapology/fighter_urls_tapology.csv"
df_fighter_info = pd.read_csv(fighter_info_path)
df_fighter_urls = pd.read_csv(fighter_urls_path)
df_fighter_urls['Extracted_Name'] = df_fighter_urls['URL'].apply(
    lambda x: re.search(r'fighters/\d+-(.*)', x).group(1) if re.search(r'fighters/\d+-(.*)', x) else ''
)
df_fighter_urls['Formatted_Name'] = df_fighter_urls['Extracted_Name'].str.replace("-", " ")
df_fighter_info['Formatted_Fighter'] = df_fighter_info['Fighter']
df_merged = df_fighter_info.merge(
    df_fighter_urls[['Formatted_Name', 'URL']],
    left_on='Formatted_Fighter',
    right_on='Formatted_Name',
    how='inner'
)
df_merged.drop_duplicates(inplace=True)
df_merged.drop(columns=['Formatted_Fighter', 'Formatted_Name'], inplace=True)
updated_file_path = "data/tapology/fighter_info_with_urls.csv"
df_merged.to_csv(updated_file_path, index=False)
print(f"Updated file saved: {updated_file_path}")
matches_found = len(df_merged)
print(f"Number of matches found: {matches_found}")