# Pixel Legends Core Smart Contract

## Overview

Pixel Legends Core is a robust and feature-rich smart contract written in Clarity for the Stacks blockchain. It implements a fantasy-themed play-to-earn game with various systems including adventurer management, guilds, quests, artifacts, and crafting.

## File Information

- **Filename:** pixel-legends-core.clar
- **Contract Name:** pixel-legends-core

## Key Features

1. **Adventurer System:** Create and manage adventurer profiles with attributes, levels, and inventories.
2. **Guild System:** Form and manage guilds, including member management and guild treasury.
3. **Quest System:** Embark on quests to earn rewards and experience.
4. **Artifact System:** Manage in-game items with various attributes and rarities.
5. **Crafting System:** Craft new artifacts using recipes and materials.
6. **Moderation System:** Assign and manage game moderators for administrative tasks.

## Constants

- `MAX_GUILD_NAME_LENGTH`: 24 characters
- `MAX_ADVENTURER_NAME_LENGTH`: 24 characters
- `MIN_GUILD_LEVEL_REQUIREMENT`: 10
- `MAX_GUILD_MEMBERS`: 100
- `MIN_CONTRIBUTION_AMOUNT`: 1
- `GUILD_CREATION_COST`: 1000
- `XP_PER_LEVEL`: 1000
- `COOLDOWN_BLOCKS`: 10
- `MAX_INVENTORY_SLOTS`: 50
- `MAX_CRAFTING_LEVEL`: 100

## Error Codes

The contract uses a comprehensive set of error codes (ERR-*) for various failure scenarios, ensuring clear communication of issues to users and developers.

## Data Structures

1. **Adventurer Profiles:** Stores detailed information about each adventurer.
2. **Artifact Inventory:** Manages artifacts owned by adventurers.
3. **Guild Data:** Stores information about each guild.
4. **Guild Members:** Maps adventurers to their respective guilds.
5. **Crafting Recipes:** Define