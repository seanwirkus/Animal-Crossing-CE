# Island Day 0 Flow

The goal of the Day 0 experience is to make a newly selected island feel welcoming, establish the cast, and seed the player with tools/quests that match the chosen biome template. This doc captures the flow plus future hooks so we can expand over time.

## Ceremony Beats
1. **Arrival Splash** – Fade in from black, show the island name and template tagline with ambient audio. The ceremony is triggered after the player chooses their island in the picker.
2. **Meet Your Neighbors** – Present portraits / names of the starter villagers defined on the template. Later we will swap portraits for actual renders and trigger VO barks.
3. **Starter Kit Briefing** – Highlight the tools, resources, and quest unlocks granted on Day 0. Reinforce how they support the island’s core loop (e.g., fishing gear on Coral Cove).
4. **Ready To Explore** – Player confirms. We hand over the starter inventory, activate starter quests, and spawn NPCs/props.

## Data Inputs
- `Data.Islands.Templates` provides the starting villager IDs, resources, and difficulty tags.
- The spreadsheet (`docs/acnh.xlsx`) will eventually seed villager biographies, crafting recipes, and seasonal intro VO lines.
- Starter inventory is defined per template (see TODOs below) and delivered through the inventory/economy services.

## Systems Involved
- **Remote Registry** – Adds `OnboardingBegin` (server → client) and `OnboardingComplete` (client → server) events.
- **IslandService** – Keeps track of each player’s chosen template.
- **OnboardingService** – Listens for selections, packages ceremony payloads, fires `OnboardingBegin`, and grants starter rewards once the client confirms completion.
- **Client UI** – `IslandSelection` leads directly into the ceremony module, which controls the screen fade, slide progression, and callback into the HUD.

## Starter Rewards (Initial Pass)
| Template | Villagers | Starter Tools | Resources | Bonus Currency | Starter Quests |
| --- | --- | --- | --- | --- | --- |
| Coral Cove | Finn, Tangy | Fishing Rod, Bug Net | Sunrise Fruit basket, Shell bundle | +500 Bells | “Cast 3 Lines”, “Collect 5 Shells” |
| Forest Glade | Maple, Poppy | Flimsy Axe, Watering Can | Softwood stack, Flower seeds | +300 Bells / +200 Miles | “Chop 3 Trees (without felling)”, “Water 5 Flowers” |
| Highland Spring | Apollo, Sheldon | Shovel, Bug Net | Hardwood stack, Hot spring stone | +400 Bells | “Dig up 2 Fossils”, “Catch 3 Cliff bugs” |

> Once the inventory system is live we will swap placeholder prints for actual item grants; quests will point to the quest pipeline.

## Future Extensions
- **Cutscene Staging** – Teleport the player to a plaza with villagers + the Resident Rep for a fully staged ceremony.
- **Choice Moments** – Allow the player to pick a tent location during the ceremony for more agency.
- **Multiplayer** – Handle multiple players joining simultaneously by queuing ceremonies per session or offering a group event.

Implementing the MVP now will give us the hooks to layer on animations, VO, and deeper questing without revisiting core wiring.
