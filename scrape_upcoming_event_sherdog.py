import warnings
import requests
import pandas as pd
import os
from bs4 import BeautifulSoup

def scrape_single_event(event_url):
    warnings.filterwarnings("ignore", category=FutureWarning)
    
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
    }
    
    # Ensure URL is complete
    full_url = f'https://sherdog.com{event_url}' if not event_url.startswith('http') else event_url
    
    print(f"Scraping data from {full_url}")
    all_data = []
    
    try:
        response = requests.get(full_url, headers=headers)
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            event_name = soup.find('span', itemprop='name').text.strip()
            event_location = soup.find('span', itemprop='location').text.strip()
            event_date = soup.find('meta', itemprop='startDate')['content'].strip()
            
            # Extract main event data
            main_event_fighters = soup.find_all('div', class_='fighter')
            if main_event_fighters:
                fighter1 = main_event_fighters[0].find('span', itemprop='name').text.strip()
                fighter2 = main_event_fighters[1].find('span', itemprop='name').text.strip()
                fighter1_id = main_event_fighters[0].find('a', itemprop='url')['href'].split('-')[-1]
                fighter2_id = main_event_fighters[1].find('a', itemprop='url')['href'].split('-')[-1]
                weight_class = soup.find('span', class_='weight_class').text.strip()
                winning_method_em = soup.find('em', string='Method').parent
                winning_method = winning_method_em.contents[2].strip() if winning_method_em else "N/A"
                winning_round_em = soup.find('em', string='Round').parent
                winning_round = winning_round_em.contents[2].strip() if winning_round_em else "N/A"
                winning_time_em = soup.find('em', string='Time').parent
                winning_time = winning_time_em.contents[2].strip() if winning_time_em else "N/A"
                referee_em = soup.find('em', string='Referee').parent
                referee = referee_em.find('a').text.strip() if referee_em and referee_em.find('a') else "N/A"
                
                all_data.append({
                    'Event Name': event_name,
                    'Event Location': event_location,
                    'Event Date': event_date,
                    'Fighter 1': fighter1,
                    'Fighter 2': fighter2,
                    'Fighter 1 ID': fighter1_id,
                    'Fighter 2 ID': fighter2_id,
                    'Weight Class': weight_class,
                    'Winning Fighter': fighter1,  # Default to fighter1, adjust as needed
                    'Winning Method': winning_method,
                    'Winning Round': winning_round,
                    'Winning Time': winning_time,
                    'Referee': referee,
                    'Fight Type': 'Main Event'
                })
            
            # Extract undercard bout data
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
                    
                    winning_method_elem = bout.find('td', class_='winby')
                    winning_method = winning_method_elem.find('b').get_text(strip=True) if winning_method_elem and winning_method_elem.find('b') else "N/A"
                    
                    td_elements = bout.find_all('td')
                    winning_round = td_elements[-2].get_text(strip=True) if len(td_elements) >= 2 else "N/A"
                    winning_time = td_elements[-1].get_text(strip=True) if len(td_elements) >= 1 else "N/A"
                    
                    referee = "N/A"
                    if winning_method_elem and winning_method_elem.find('a'):
                        referee = winning_method_elem.find('a').get_text(strip=True)
                    
                    all_data.append({
                        'Event Name': event_name,
                        'Event Location': event_location,
                        'Event Date': event_date,
                        'Fighter 1': fighter1,
                        'Fighter 2': fighter2,
                        'Fighter 1 ID': fighter1_id,
                        'Fighter 2 ID': fighter2_id,
                        'Weight Class': weight_class,
                        'Winning Fighter': fighter1,  # Default to fighter1, adjust as needed
                        'Winning Method': winning_method,
                        'Winning Round': winning_round,
                        'Winning Time': winning_time,
                        'Referee': referee,
                        'Fight Type': 'Undercard'
                    })
            
            # Create DataFrame and save to CSV
            df = pd.DataFrame(all_data)
            file_path = './data/upcoming_event_data_sherdog.csv'
            
            # Create data directory if it doesn't exist
            os.makedirs('./data', exist_ok=True)
            
            # Determine write mode (append if file exists, write if not)
            write_mode = 'a' if os.path.isfile(file_path) else 'w'
            df.to_csv(file_path, mode=write_mode, header=not os.path.isfile(file_path), index=False)
            
            # Clean the data by stripping strings
            df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
            
            print(f"Data successfully written to {file_path}")
            print(f"Total number of fights scraped: {len(df)}")
            print(f"Column names: {list(df.columns)}")
            
            return df
        else:
            print(f"Failed to retrieve data. Status code: {response.status_code}")
            return None
    except Exception as e:
        print(f"Error scraping event: {e}")
        return None

# Example usage
if __name__ == "__main__":
    # You can input a single event URL here
    event_url = input("Enter the Sherdog event URL: ")
    scrape_single_event(event_url)