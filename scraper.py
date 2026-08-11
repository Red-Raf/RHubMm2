import json
import cloudscraper
from bs4 import BeautifulSoup

# Инициализируем парсер с обходом Cloudflare
scraper = cloudscraper.create_scraper()

def parse_supreme():
    print("Запрос к Supreme Values...")
    
    # Ссылка на страницу (или API, если есть)
    url = "https://supremevaluelist.com/mm2/godlies"
    
    try:
        response = scraper.get(url)
        if response.status_code != 200:
            print(f"Ошибка доступа к сайту: {response.status_code}")
            return

        soup = BeautifulSoup(response.text, 'html.parser')
        new_values = {}

        # Логика поиска элементов с ценами на странице
        # (Ищет карточки предметов и извлекает название и цену)
        for item in soup.find_all('div', class_='item-card'):
            name_elem = item.find('div', class_='item-name')
            value_elem = item.find('div', class_='item-value')
            
            if name_elem and value_elem:
                name = name_elem.text.strip()
                # Преобразуем цену в число
                val_str = value_elem.text.strip().replace(',', '')
                try:
                    val = int(val_str)
                    new_values[name] = val
                except ValueError:
                    continue

        if new_values:
            # Перезаписываем values.json новым содержимым
            with open('values.json', 'w', encoding='utf-8') as f:
                json.dump(new_values, f, indent=4, ensure_ascii=False)
            print(f"Успешно обновлено предметов: {len(new_values)}")
            
    except Exception as e:
        print(f"Произошла ошибка при парсинге: {e}")

if __name__ == "__main__":
    parse_supreme()
    
