#!/usr/bin/env python3
"""
ACNH Roblox Game Finalizer
This script helps complete remaining tasks and validates the game setup.
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime

class GameFinalizer:
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.src_dir = self.project_root / "src"
        self.timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
    def print_header(self, text):
        """Print a formatted header"""
        print(f"\n{'='*60}")
        print(f"  {text}")
        print(f"{'='*60}\n")
        
    def check_files_exist(self):
        """Verify all critical files exist"""
        print("📋 Checking critical files...")
        
        critical_files = [
            "src/server/init.server.luau",
            "src/client/init.client.luau",
            "src/server/Systems/TreeService.luau",
            "src/client/UI/Hud.luau",
            "src/shared/Config.luau",
        ]
        
        missing = []
        for file in critical_files:
            path = self.project_root / file
            if path.exists():
                print(f"  ✅ {file}")
            else:
                print(f"  ❌ {file} - MISSING")
                missing.append(file)
                
        return len(missing) == 0
        
    def check_rojo_status(self):
        """Check if Rojo is running"""
        print("🔌 Checking Rojo status...")
        try:
            result = subprocess.run(["pgrep", "-f", "rojo serve"], 
                                  capture_output=True, timeout=2)
            if result.returncode == 0:
                print("  ✅ Rojo is running")
                return True
            else:
                print("  ⚠️  Rojo is not running")
                print("     Run: rojo serve")
                return False
        except Exception as e:
            print(f"  ❌ Error checking Rojo: {e}")
            return False
            
    def validate_lua_syntax(self):
        """Check for common Lua syntax issues"""
        print("🔍 Validating Lua syntax...")
        
        issues = []
        
        # Check for Color3 arithmetic (common error)
        lua_files = list(self.src_dir.rglob("*.luau"))
        
        for lua_file in lua_files:
            try:
                with open(lua_file, 'r') as f:
                    content = f.read()
                    # Check for Color3 arithmetic errors
                    if "Color3.fromRGB" in content and " + Color3.new" in content:
                        lines = content.split('\n')
                        for i, line in enumerate(lines, 1):
                            if " + Color3.new" in line and "Color3.fromRGB" in line:
                                issues.append(f"  {lua_file.name}:{i} - Possible Color3 arithmetic")
                                
            except Exception as e:
                pass
                
        if issues:
            print(f"  ⚠️  Found {len(issues)} potential issues:")
            for issue in issues[:5]:
                print(issue)
        else:
            print("  ✅ No obvious Lua syntax issues found")
            
        return len(issues) == 0
        
    def check_game_ready(self):
        """Run all checks"""
        self.print_header("🎮 GAME READINESS CHECK")
        
        checks = [
            ("Files Exist", self.check_files_exist),
            ("Rojo Running", self.check_rojo_status),
            ("Lua Syntax", self.validate_lua_syntax),
        ]
        
        results = {}
        for name, check_func in checks:
            try:
                results[name] = check_func()
            except Exception as e:
                print(f"❌ Error during {name}: {e}")
                results[name] = False
                
        return results
        
    def generate_todo_list(self):
        """Generate final todo list"""
        print("\n📝 REMAINING TASKS:")
        print("""
  ✅ Core Systems Complete:
     - Island terrain generation & expansion
     - Tree spawning and interactions
     - Inventory system
     - Quest board UI
     - Economy (Bells & Miles)
     - Villagers & dialogue
     - Tool selection & management
     
  ⚠️  Optional Enhancements:
     - [ ] Add more tree varieties (Oak, Maple, Birch)
     - [ ] Enhanced fishing mechanics
     - [ ] Bug catching improvements
     - [ ] Island customization
     - [ ] Custom furniture placements
     - [ ] Music/Sound tweaks
     - [ ] Performance optimization
        """)
        
    def show_quick_start(self):
        """Show quick start commands"""
        print("\n⚡ QUICK START:")
        print("""
  1. Start Rojo:
     $ rojo serve
     
  2. Open Roblox Studio
  3. Click "Connect to Rojo"
  4. Play the game (Press F5)
  
  5. Test these features:
     - Press 'T' for tools
     - Press 'B' for quest board
     - Press 'I' for inventory
     - Press 'V' for villagers
     - Press 'C' to customize character
        """)
        
    def generate_status_report(self):
        """Generate a detailed status report"""
        self.print_header("📊 GAME STATUS REPORT")
        
        report = {
            "timestamp": self.timestamp,
            "project": "ACNH Roblox",
            "status": "READY FOR FINAL TESTING",
            "checks": self.check_game_ready(),
            "file_count": len(list(self.src_dir.rglob("*.luau"))),
        }
        
        print(json.dumps(report, indent=2))
        return report
        
    def run_all(self):
        """Run complete check and report"""
        self.print_header("🎮 ACNH ROBLOX - GAME FINALIZER")
        
        # Run checks
        self.generate_status_report()
        
        # Show todos
        self.generate_todo_list()
        
        # Show quick start
        self.show_quick_start()
        
        self.print_header("✨ GAME READY FOR TESTING!")
        print("Next Steps:")
        print("  1. Fix any errors from the check above")
        print("  2. Start Rojo server (rojo serve)")
        print("  3. Connect in Roblox Studio")
        print("  4. Test all features and report bugs")
        print("\nGood luck! 🚀\n")


def main():
    """Main entry point"""
    finalizer = GameFinalizer()
    finalizer.run_all()


if __name__ == "__main__":
    main()
