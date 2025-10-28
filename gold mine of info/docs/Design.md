# ACNH-Inspired Experience Plan

## Vision
- Cozy social sim on a small island with daily routines, gentle pacing, and collectible progression.
- Emphasis on relaxing activities: fishing, bug catching, gardening, decorating, and chatting with villagers.
- Built to expand easily with new critters, furniture themes, seasonal events, and multiplayer social hubs.

## Core Player Loop
1. Log in at any time; server syncs island clock and weather.
2. Greet villagers for rewards, conversation, and relationship points.
3. Collect resources (fruit, shells, fish, bugs) and turn them in for Bells or crafting materials.
4. Check the quest board for daily tasks that award Nook Miles-like currency.
5. Spend currency to upgrade the player’s home, buy furniture, or unlock new island amenities.

## Key Systems
- **Time & Weather**: Shared day-night cycle, rotating weather presets, and time-gated spawns.
- **Villagers**: Personality-driven schedules, talk prompts, gifting preferences, and rotating dialogue.
- **Economy**: Bells for buying/selling, Miles for long-term goals, density-based resource respawns.
- **Quests**: Procedural mix of gather, deliver, and socialize missions refreshed every real-time day.
- **Decorating**: Placeable furniture with placement validation and themed sets for bonus scores.
- **Progression**: Home expansion tiers, upgradeable facilities (shop, museum, garden), unlocks at milestone counts.

## Initial Content Targets
- 6 launch villagers spanning Lazy, Peppy, Cranky, Normal, Snooty, and Jock personalities.
- 25 catalog items (mix of furniture, tools, decor) with rarity tiers.
- 12 fish, 12 bugs, and 6 forage items tuned to time-of-day windows.
- 15 quest templates covering beginner-friendly activities.

## Player Tools
- Pocket inventory with limited slots; upgrades via Miles.
- Tool durability tracking with repair stations.
- Context-sensitive prompt UI for chatting, gifting, fishing, bug catching, harvesting, and placing furniture.

## Multiplayer Considerations
- Instanced islands support up to 6 concurrent players.
- Visitor mode prevents island destruction but allows gifting and co-op activities.
- Session achievements reward hosts and visitors for collaborative tasks.

## Extensibility Notes
- Content lives in `src/shared/Data/*` modules for simple balancing.
- Systems expose builder hooks so designers can drop in new assets without code changes.
- Server scripts isolate state changes to support future persistence layers.
