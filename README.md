# The Clerk's Ascent

> A tiny clockwork repair bot must navigate a frozen bureaucratic afterlife, fixing broken machinery and gathering soul-fragments to earn its passage to the next realm.

A top-down RPG/adventure game built with Godot 4 and Claude Code Game Studios.

## 🎮 How to Play

- **WASD / Arrow keys** — Move
- **Space / Left Click** — Attack
- **E** — Interact with NPCs
- **I** — Open inventory
- **Click item** — Use or equip

## 🎯 Objective

Navigate the Mechanical Afterlife, defeat broken machinery, collect soul fragments, and survive the MiniBoss enforcer to reach the Central Archive exit.

## 📦 Features

- Melee combat with hitbox/hurtbox system
- Branching NPC dialogue (2 characters)
- Inventory with 5 unique items (consumables & equippables)
- Enemy AI with state machines (Grunt, Ranged, MiniBoss)
- Phase-based miniboss fight
- Data-driven design (JSON configs for stats, items, dialogue)
- Polish: screen shake, hit flash, death particles, item bobbing, fade transitions

## 🛠 Built With

- [Godot 4](https://godotengine.org/)
- [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
- Claude Code (Anthropic)

## 🚀 Run Locally

1. Install [Godot 4](https://godotengine.org/download) (version 4.6 recommended)
2. Clone this repo
3. Open `project.godot` in Godot
4. Press F5 to play

## 📁 Project Structure

```
src/gameplay/   — Player, enemies, combat, items
src/ui/         — HUD, dialogue, inventory UI
src/core/       — Game manager, scene transitions, shake camera, fade
assets/data/    — JSON config for all stats and dialogue
design/gdd/     — Game Design Document
```

## 🧪 Testing

Run tests via:

```bash
godot --headless --script tests/gdunit4_runner.gd
```

## 📄 License

MIT — see LICENSE file.
