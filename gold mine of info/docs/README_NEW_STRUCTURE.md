# 🏝️ Animal Crossing: New Horizons - Roblox Game

## 🎮 **REBUILT FROM SCRATCH USING PROPER TEMPLATE STRUCTURE**

This Animal Crossing game has been completely rebuilt using the proper Roblox Game Template framework, ensuring clean architecture and maintainable code.

## 📁 **Project Structure**

```
src/
├── shared/                    # Shared code between client and server
│   ├── ModuleLoader.luau     # Module loading system
│   ├── Configs/              # Game configuration
│   │   └── PlayerData.luau   # Player data structure
│   └── Remotes.luau         # Remote events
├── client/                   # Client-side code
│   ├── Controllers/         # Client controllers
│   │   └── PlayerController.luau  # Main player controller
│   ├── Loader.client.luau   # Client entry point
│   └── init.client.luau     # Client initialization
└── server/                  # Server-side code
    ├── Services/            # Server services
    │   ├── PlayerDataService.luau    # Player data management
    │   ├── OnboardingService.luau    # Onboarding flow
    │   ├── IslandService.luau        # Island management
    │   └── HubService.luau           # Hub creation
    ├── Loader.server.luau   # Server entry point
    └── init.server.luau     # Server initialization
```

## 🚀 **Key Features**

### ✅ **Proper Module System**
- Uses ModuleLoader for clean dependency management
- Services and Controllers auto-load on startup
- Proper separation of client/server code

### ✅ **Player Data System**
- Persistent player data with DataStore
- Bells, Miles, and Nook Miles currency
- Island data management
- Inventory system

### ✅ **Onboarding Flow**
- Tom Nook greeting system
- Island selection
- Island naming
- Proper UI flow

### ✅ **Hub System**
- Beautiful hub with NPCs
- Tom Nook, Isabelle, Orville, Blathers, Timmy & Tommy
- Decorative trees and flowers
- Animal Crossing lighting

### ✅ **NPC Interaction**
- Proximity prompts for all NPCs
- Different dialogue for each character
- Proper interaction handling

## 🎯 **How to Run**

1. **Open in Roblox Studio**
2. **Click Run** - The game will automatically:
   - Load all modules
   - Create the hub
   - Set up NPCs
   - Initialize player data
   - Start onboarding

## 🎮 **Gameplay Flow**

1. **Player Joins** → Data loads, hub appears
2. **Talk to Tom Nook** → Onboarding starts
3. **Select Island** → Choose from 3 templates
4. **Name Island** → Customize your paradise
5. **Explore Hub** → Interact with NPCs
6. **Build & Decorate** → Create your dream island

## 🛠️ **Technical Details**

### **Module Loading**
- `ModuleLoader.luau` handles all module loading
- Services auto-initialize on server
- Controllers auto-initialize on client
- Clean dependency management

### **Data Management**
- `PlayerDataService.luau` handles all player data
- DataStore integration
- Auto-save every 30 seconds
- Proper error handling

### **UI System**
- `PlayerController.luau` manages all client UI
- Responsive design
- Clean separation of concerns
- Proper event handling

## 🎨 **Visual Features**

- **Animal Crossing Lighting** - Warm, cozy atmosphere
- **Hub Platform** - 200x200 grass platform
- **NPCs with Emojis** - Visual character representation
- **Decorative Elements** - Trees, flowers, spawn location
- **Currency Display** - Bells and Miles in top bar

## 🔧 **Development**

This structure follows the **Roblox Game Template** best practices:
- Clean module organization
- Proper service architecture
- Client-server separation
- Maintainable code structure

The game is now **production-ready** with a solid foundation for expansion! 🎉
