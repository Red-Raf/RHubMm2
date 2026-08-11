import urllib.request
import json
import re

# Страницы с предметами на Supreme Values
URLS = [
    "https://supremevaluelist.com/mm2/godlies.html",
    "https://supremevaluelist.com/mm2/ancients.html",
    "https://supremevaluelist.com/mm2/chromas.html",
    "https://supremevaluelist.com/mm2/vintage.html"
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

items = {}

print("Начинаем скачивание цен с Supreme Values...")

for url in URLS:
    try:
        req = urllib.request.Request(url, headers=headers)
        html = urllib.request.urlopen(req).read().decode('utf-8', errors='ignore')
        
        # Находим пары: Название предмета и его Цену
        matches = re.findall(r'class="item-name"[^>]*>([^<]+)<.*?class="value-number"[^>]*>([\d,]+)<', html, re.DOTALL)
        
        for name, val in matches:
            clean_name = name.strip()
            clean_val = int(val.replace(',', ''))
            items[clean_name] = clean_val
    except Exception as e:
        print(f"Ошибка при скачивании {url}: {e}")

# Если удалось скачать цены, обновляем файл values.json
if items:
    with open('values.json', 'w', encoding='utf-8') as f:
        json.dump(items, f, indent=2, ensure_ascii=False)
    print(f"Успешно обновлено предметов: {len(items)}")
else:
    print("Не удалось загрузить новые цены, оставляем старые.")
  
