#!/usr/bin/env python3
"""
ACNH Sprite Sheet Analyzer
Analyzes the acnh-item-sprites.png to map out every item and coordinate positions.
"""

import json
from pathlib import Path
from PIL import Image
from typing import Dict, List, Tuple
import re

ROOT = Path(__file__).resolve().parents[1]
SPRITESHEET = ROOT / "acnh-item-sprites.png"
SPRITEMANIFEST = ROOT / "src" / "shared" / "SpriteManifest.luau"
NOOKIPEDIA_ITEMS = ROOT / "nookipedia_items.json"
DATA_ITEMS = ROOT / "data" / "items.json"
OUTPUT_DIR = ROOT / "tools" / "spritesheet_analysis"
OUTPUT_MAPPING = OUTPUT_DIR / "item_mapping.json"

class SpriteSheetAnalyzer:
    def __init__(self):
        self.sprite_config = {
            "SHEET_ASSET": "rbxassetid://74324628581851",
            "COLUMNS": 21,
            "ROWS": 24,
            "TILE": 36.6,
            "INNER": (6, 6),
            "OUTER": (4, 4),
            "BLEED_FIX": 0.25,
        }
        self.sprite_manifest = {}
        self.nookipedia_data = {}
        self.items_data = {}
        self.output = []
        
    def load_sprite_manifest(self):
        """Load existing sprite manifest."""
        if SPRITEMANIFEST.exists():
            content = SPRITEMANIFEST.read_text()
            # Parse luau table
            for line in content.split('\n'):
                if '{' in line and 'name' in line and 'spriteIndex' in line:
                    match = re.search(r'(\w+)\s*=\s*\{\s*name\s*=\s*"([^"]+)",\s*spriteIndex\s*=\s*(\d+)', line)
                    if match:
                        key, name, index = match.groups()
                        self.sprite_manifest[key] = {
                            'name': name,
                            'spriteIndex': int(index)
                        }
            
            print(f"Loaded {len(self.sprite_manifest)} items from SpriteManifest")
    
    def load_nookipedia_data(self):
        """Load Nookipedia JSON data."""
        if NOOKIPEDIA_ITEMS.exists():
            data = json.loads(NOOKIPEDIA_ITEMS.read_text())
            furniture = data.get('furniture', [])
            recipes = data.get('recipes', [])
            
            for item in furniture:
                name = item.get('name', '')
                slug = self.slugify(name)
                self.nookipedia_data[slug] = item
            
            print(f"Loaded {len(self.nookipedia_data)} items from Nookipedia")
    
    def load_items_data(self):
        """Load existing items.json."""
        if DATA_ITEMS.exists():
            data = json.loads(DATA_ITEMS.read_text())
            items = data.get('items', [])
            for item in items:
                self.items_data[item['id']] = item
            print(f"Loaded {len(self.items_data)} items from items.json")
    
    def slugify(self, name: str) -> str:
        """Convert name to slug ID."""
        return re.sub(r'[^0-9a-zA-Z]+', '-', name.lower()).strip('-')
    
    def get_grid_position(self, index: int) -> Tuple[int, int]:
        """Convert sprite index to grid (row, col)."""
        zero_based = index - 1
        col = zero_based % self.sprite_config['COLUMNS']
        row = zero_based // self.sprite_config['COLUMNS']
        return row, col
    
    def get_sprite_coords(self, index: int) -> Dict:
        """Calculate sprite coordinates in pixels."""
        row, col = self.get_grid_position(index)
        
        offset_x = self.sprite_config['OUTER'][0] + col * (self.sprite_config['TILE'] + self.sprite_config['INNER'][0])
        offset_y = self.sprite_config['OUTER'][1] + row * (self.sprite_config['TILE'] + self.sprite_config['INNER'][1])
        
        size_value = round(self.sprite_config['TILE'] - self.sprite_config['BLEED_FIX'] * 2)
        
        return {
            'row': row,
            'col': col,
            'x': int(round(offset_x + self.sprite_config['BLEED_FIX'])),
            'y': int(round(offset_y + self.sprite_config['BLEED_FIX'])),
            'width': size_value,
            'height': size_value
        }
    
    def analyze_spritesheet(self):
        """Analyze the sprite sheet image to identify items."""
        if not SPRITESHEET.exists():
            print(f"ERROR: Sprite sheet not found at {SPRITESHEET}")
            return
        
        try:
            img = Image.open(SPRITESHEET)
            width, height = img.size
            print(f"\nSprite Sheet: {width}x{height} pixels")
            print(f"Grid: {self.sprite_config['COLUMNS']} columns x {self.sprite_config['ROWS']} rows")
            print(f"Total slots: {self.sprite_config['COLUMNS'] * self.sprite_config['ROWS']}")
            
            # Get all sprite indices from manifest
            all_indices = set()
            for entry in self.sprite_manifest.values():
                all_indices.add(entry['spriteIndex'])
            
            # Map out all items
            for item_id, entry in self.sprite_manifest.items():
                index = entry['spriteIndex']
                name = entry['name']
                coords = self.get_sprite_coords(index)
                
                # Try to match with Nookipedia data
                nookipedia_match = None
                nookipedia_slug = self.slugify(name)
                if nookipedia_slug in self.nookipedia_data:
                    nookipedia_match = self.nookipedia_data[nookipedia_slug]
                else:
                    # Try partial matching
                    for slug, data in self.nookipedia_data.items():
                        if name.lower() in slug or slug in name.lower():
                            nookipedia_match = data
                            break
                
                # Try to match with items.json
                items_match = None
                if item_id in self.items_data:
                    items_match = self.items_data[item_id]
                else:
                    nookipedia_slug = self.slugify(name)
                    if nookipedia_slug in self.items_data:
                        items_match = self.items_data[nookipedia_slug]
                
                item_info = {
                    'id': item_id,
                    'name': name,
                    'spriteIndex': index,
                    'gridPosition': {
                        'row': coords['row'],
                        'col': coords['col']
                    },
                    'coordinates': {
                        'x': coords['x'],
                        'y': coords['y'],
                        'width': coords['width'],
                        'height': coords['height']
                    },
                    'hasNookipediaData': nookipedia_match is not None,
                    'hasItemsData': items_match is not None,
                }
                
                # Add Nookipedia data if available
                if nookipedia_match:
                    item_info['nookipedia'] = {
                        'category': nookipedia_match.get('category'),
                        'sell': nookipedia_match.get('sell'),
                        'buy': nookipedia_match.get('buy', [{}])[0].get('price') if nookipedia_match.get('buy') else None,
                        'variations': len(nookipedia_match.get('variations', [])),
                    }
                
                # Add items.json data if available
                if items_match:
                    item_info['itemsData'] = {
                        'category': items_match.get('category'),
                        'sell': items_match.get('sell'),
                        'buy': items_match.get('buy'),
                    }
                
                self.output.append(item_info)
            
            # Sort by sprite index
            self.output.sort(key=lambda x: x['spriteIndex'])
            
        except Exception as e:
            print(f"ERROR analyzing sprite sheet: {e}")
    
    def generate_statistics(self):
        """Generate statistics about the sprite sheet."""
        total_slots = self.sprite_config['COLUMNS'] * self.sprite_config['ROWS']
        used_slots = len(self.output)
        empty_slots = total_slots - used_slots
        
        nookipedia_matches = sum(1 for item in self.output if item['hasNookipediaData'])
        items_data_matches = sum(1 for item in self.output if item['hasItemsData'])
        
        print(f"\n=== SPRITE SHEET STATISTICS ===")
        print(f"Total grid slots: {total_slots}")
        print(f"Used slots: {used_slots}")
        print(f"Empty slots: {empty_slots}")
        print(f"Items with Nookipedia data: {nookipedia_matches}/{used_slots}")
        print(f"Items with items.json data: {items_data_matches}/{used_slots}")
    
    def save_mapping(self):
        """Save the item mapping to JSON."""
        OUTPUT_DIR.mkdir(exist_ok=True)
        
        output_data = {
            'metadata': {
                'spriteSheet': str(SPRITESHEET.name),
                'assetId': self.sprite_config['SHEET_ASSET'],
                'grid': {
                    'columns': self.sprite_config['COLUMNS'],
                    'rows': self.sprite_config['ROWS'],
                    'totalSlots': self.sprite_config['COLUMNS'] * self.sprite_config['ROWS']
                },
                'layout': {
                    'tileSize': self.sprite_config['TILE'],
                    'innerSpacing': self.sprite_config['INNER'],
                    'outerMargin': self.sprite_config['OUTER'],
                    'bleedFix': self.sprite_config['BLEED_FIX']
                },
                'totalItems': len(self.output),
                'nookipediaMatches': sum(1 for item in self.output if item['hasNookipediaData']),
                'itemsDataMatches': sum(1 for item in self.output if item['hasItemsData'])
            },
            'items': self.output
        }
        
        OUTPUT_MAPPING.write_text(json.dumps(output_data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        print(f"\nSaved mapping to {OUTPUT_MAPPING}")
    
    def generate_report(self):
        """Generate a human-readable report."""
        report_path = OUTPUT_DIR / "analysis_report.txt"
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("ACNH Sprite Sheet Analysis Report\n")
            f.write("=" * 60 + "\n\n")
            
            f.write(f"Total Items: {len(self.output)}\n")
            f.write(f"Grid: {self.sprite_config['COLUMNS']}x{self.sprite_config['ROWS']}\n\n")
            
            f.write("Items by Index:\n")
            f.write("-" * 60 + "\n")
            
            for item in self.output:
                f.write(f"\nIndex {item['spriteIndex']}: {item['name']}\n")
                f.write(f"  Grid: Row {item['gridPosition']['row']}, Col {item['gridPosition']['col']}\n")
                f.write(f"  Coords: ({item['coordinates']['x']}, {item['coordinates']['y']})\n")
                
                if item['hasNookipediaData']:
                    nook = item.get('nookipedia', {})
                    f.write(f"  Nookipedia: ✓ (Category: {nook.get('category')})\n")
                
                if item['hasItemsData']:
                    data = item.get('itemsData', {})
                    f.write(f"  items.json: ✓ (Category: {data.get('category')})\n")
                
                if not item['hasNookipediaData'] and not item['hasItemsData']:
                    f.write(f"  No matching data found\n")
        
        print(f"Saved report to {report_path}")
    
    def run(self):
        """Run the complete analysis."""
        print("ACNH Sprite Sheet Analyzer")
        print("=" * 60)
        
        self.load_sprite_manifest()
        self.load_nookipedia_data()
        self.load_items_data()
        self.analyze_spritesheet()
        self.generate_statistics()
        self.save_mapping()
        self.generate_report()
        
        print("\nAnalysis complete!")


if __name__ == "__main__":
    analyzer = SpriteSheetAnalyzer()
    analyzer.run()

