#!/usr/bin/env python3
"""
Fetch all character data from Nookipedia API and save to JSON
This pre-fetches data so the game doesn't need to make HTTP requests at runtime
"""

import requests
import json
import time
from pathlib import Path

API_KEY = "153cf201-7ca1-44d7-9f17-efd59e6c45e0"
BASE_URL = "https://api.nookipedia.com"
HEADERS = {
    "X-API-KEY": API_KEY,
    "Accept-Version": "1.0.0"
}

# Characters we want to fetch
CORE_CHARACTERS = [
    "Tom Nook",
    "Isabelle",
    "Orville",
]

TOP_MAIN_CHARACTERS = [
    "K.K. Slider",
    "Blathers",
    "Celeste",
    "Timmy",
    "Tommy",
    "Leif",
    "Resetti",
    "Wilbur",
    "Brewster",
    "Kicks"
]

def fetch_character(name):
    """Fetch a single character's data"""
    print(f"  Fetching: {name}...", end=" ")
    try:
        url = f"{BASE_URL}/nh/characters/{name.replace(' ', '_')}"
        response = requests.get(url, headers=HEADERS)
        
        if response.status_code == 200:
            data = response.json()
            print("✅")
            return data
        else:
            print(f"❌ (Status {response.status_code})")
            return None
    except Exception as e:
        print(f"❌ (Error: {e})")
        return None

def fetch_all_villagers():
    """Fetch all villagers from the API"""
    print("  Fetching all villagers...")
    try:
        url = f"{BASE_URL}/nh/villagers"
        response = requests.get(url, headers=HEADERS)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Got {len(data)} villagers")
            return data
        else:
            print(f"  ❌ Failed to fetch villagers (Status {response.status_code})")
            return []
    except Exception as e:
        print(f"  ❌ Error fetching villagers: {e}")
        return []

def main():
    print("=" * 80)
    print("🦝 Nookipedia Character Data Fetcher")
    print("=" * 80)
    print()
    
    all_characters = {}
    
    # Fetch core characters
    print("📚 Fetching core characters...")
    for name in CORE_CHARACTERS:
        data = fetch_character(name)
        if data:
            all_characters[name] = data
        time.sleep(0.5)  # Rate limiting
    
    print()
    
    # Fetch top main characters
    print("⭐ Fetching top main characters...")
    for name in TOP_MAIN_CHARACTERS:
        data = fetch_character(name)
        if data:
            all_characters[name] = data
        time.sleep(0.5)  # Rate limiting
    
    print()
    
    # Fetch all villagers
    print("🏘️ Fetching all villagers...")
    villagers = fetch_all_villagers()
    
    # Add villagers to character database
    for villager in villagers:
        name = villager.get("name", "Unknown")
        if name not in all_characters:
            all_characters[name] = villager
    
    print()
    print("=" * 80)
    print(f"✅ Total characters fetched: {len(all_characters)}")
    print("=" * 80)
    print()
    
    # Save to JSON file
    output_path = Path(__file__).parent.parent / "data" / "nookipedia_characters.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(all_characters, f, indent=2, ensure_ascii=False)
    
    print(f"💾 Saved to: {output_path}")
    print()
    
    # Print summary
    print("📊 Character Summary:")
    species_count = {}
    personality_count = {}
    
    for name, data in all_characters.items():
        species = data.get("species", "Unknown")
        personality = data.get("personality", "Unknown")
        
        species_count[species] = species_count.get(species, 0) + 1
        personality_count[personality] = personality_count.get(personality, 0) + 1
    
    print(f"  Species:")
    for species, count in sorted(species_count.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"    • {species}: {count}")
    
    print(f"  Personalities:")
    for personality, count in sorted(personality_count.items(), key=lambda x: x[1], reverse=True):
        print(f"    • {personality}: {count}")
    
    print()
    print("✅ Done!")

if __name__ == "__main__":
    main()

