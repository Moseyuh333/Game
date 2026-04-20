# Game Design Document: The Clerk's Ascent

## 1. Overview

**Title:** The Clerk's Ascent  
**Engine:** Godot 4.6  
**Platform:** PC (Windows, Linux, macOS)  
**Target Playtime:** 8–12 minutes  
**Genre:** Top-down RPG / Adventure

**Core Loop:**  
The player controls Tick-7, a clockwork repair bot navigating a frozen bureaucratic afterlife. Move through rooms, defeat broken machinery (enemies), collect soul-fragments (loot), and use fragments to unlock doors toward the Central Archive exit. Survive with careful resource management and strategic combat.

---

## 2. Core Mechanics

### 2.1 Movement (8-directional top-down)
- Input: WASD or Arrow keys
- Speed: data-driven from `assets/data/player_stats.json` (default: 120 px/s)
- No diagonal speed penalty (normalize vector)
- Collision: CharacterBody2D with TileMap collision; no wall clipping

### 2.2 Melee Combat
- Input: Space or Left Mouse Button
- Attack type: Arc Area2D hitbox in facing direction (90° cone, 60px range)
- Attack cooldown: 0.5s
- Damage formula: `max(1, player_attack - enemy_defense)`
- Knockback: enemy pushed 40px away from player on hit
- Player invincibility: 0.5s after taking damage (blink visual)

### 2.3 NPC Dialogue
- Input: E key when near NPC (interaction range: 60px)
- System: Branching dialogue trees loaded from `assets/data/dialogue.json`
- UI: DialogueBox with typewriter text effect, choice buttons
- Constraints: Dialogue cannot start while player is in combat

### 2.4 Inventory System
- Capacity: 10 slots
- Item pickup: auto-pickup on overlap with Area2D ItemPickup
- Use/Equip: Click item in inventory (I key to toggle); consumes consumables, toggles equippables
- Equip slots: weapon (right hand), armor (body)
- Stats: equippable items apply delta to PlayerStats on equip

---

## 3. Player Stats (data-driven)

Loaded from `assets/data/player_stats.json`:

| Stat | Default | Notes |
|------|---------|-------|
| `max_hp` | 100 | |
| `current_hp` | 100 | starts at max |
| `attack` | 15 | base weapon damage |
| `defense` | 5 | damage reduction |
| `speed` | 120 | px/sec |

Player death when `current_hp <= 0`.

---

## 4. Enemy Design

All stats loaded from `assets/data/enemies.json`.

### 4.1 Grunt (x4 in exploration area)
**Role:** Basic melee patrol

| Stat | Value |
|------|-------|
| max_hp | 30 |
| attack | 8 |
| defense | 0 |
| speed | 60 |
| chase_speed | 90 |
| chase_range | 150px |
| patrol_radius | 100px |

**AI States:**
- **Patrol:** Move to random point within patrol radius; wait 1–2s
- **Chase:** When player within 150px, pathfind to player (speed 90)
- **Attack:** On contact, deal damage every 1s; apply knockback to player

**Drops:** soul_fragment (100%), minor_health_potion (25%)

---

### 4.2 Ranged (x2 in corridor)
**Role:** Ranged harassment

| Stat | Value |
|------|-------|
| max_hp | 20 |
| attack | 12 |
| defense | 0 |
| speed | 40 |
| projectile_speed | 150px/s |
| shoot_interval | 2.0s |
| shoot_range | 300px |

**AI States:**
- **Idle:** Face player, maintain distance (100–250px)
- **Shoot:** Every 2s if player in range, fire projectile (Area2D with lifetime 3s)
- **Flee:** If player within 50px, move away

**Drops:** soul_fragment (100%)

**Projectile behavior:**
- Travels in straight line toward player's last known position
- On hit: applies damage + knockback to player
- Despawns after 3s or on hit

---

### 4.3 MiniBoss (x1 in boss room)
**Role:** Phase-based challenge guarding exit

| Stat | Value |
|------|-------|
| max_hp | 150 |
| attack | 20 |
| defense | 5 |
| speed | 50 |
| phase2_threshold | 50% HP |

**AI States:**
- **Phase 1:** Aggressive melee; every 1.5s, charge 200px toward player, then slam (AoE 80px radius, 15 damage)
- **Phase 2** (trigger at ≤75 HP): Speed increases to 80; add 360° spin slam every 5s (AoE, 20 damage)
- **Stun:** Vulnerable for 1s after completing slam attack

**Drops:** boss_soul_fragment (100%), powerful_weapon

**Special:** Door to exit remains locked until MiniBoss defeated (broadcast signal).

---

## 5. Item System

All items defined in `assets/data/items.json`.

### 5.1 Consumables (2)

**Healing Potion**
```json
{
  "id": "heal_potion",
  "name": "Minor Repair Kit",
  "type": "consumable",
  "effect": "heal",
  "value": 50,
  "rarity": "common"
}
```
Effect: restore 50 HP (cannot exceed max_hp)

**Speed Boost**
```json
{
  "id": "speed_boost",
  "name": "Clockwork Accelerant",
  "type": "consumable",
  "effect": "speed_multiply",
  "value": 2.0,
  "duration": 10.0,
  "rarity": "uncommon"
}
```
Effect: 2x speed for 10s

---

### 5.2 Equippables (3)

**Wrench Weapon**
```json
{
  "id": "wrench",
  "name": "Standard Wrench",
  "type": "weapon",
  "slot": "weapon",
  "attack_delta": 0,
  "rarity": "common"
}
```
Default starting weapon (equipped at game start).

**Precision Cutter**
```json
{
  "id": "cutter",
  "name": "Precision Cutter",
  "type": "weapon",
  "slot": "weapon",
  "attack_delta": 10,
  "rarity": "rare"
}
```
Dropped by MiniBoss; +10 attack.

**Reinforced Plating**
```json
{
  "id": "plating",
  "name": "Reinforced Plating",
  "type": "armor",
  "slot": "armor",
  "defense_delta": 5,
  "rarity": "uncommon"
}
```
Drop from Grunts (5% chance); +5 defense.

---

## 6. Dialogue System

Format: `assets/data/dialogue.json` with node-based tree structure:

```json
{
  "npc_01_start": {
    "npc": "Archive Clerk",
    "text": "Tick-unit! You're... mobile? That's not in the schema.",
    "choices": [
      {"label": "I'm seeking the Central Archive.", "next": "npc_01_archive"},
      {"label": "Just fixing machinery.", "next": "npc_01_fix"}
    ]
  },
  "npc_01_archive": {
    "npc": "Archive Clerk",
    "text": "The Archive is sealed. Only those with sufficient soul-fragments may enter. You'll need at least 3 fragments to unlock the final door.",
    "choices": [
      {"label": "Where do I find fragments?", "next": "npc_01_hint"},
      {"label": "Thanks.", "next": "end"}
    ]
  },
  "npc_01_hint": {
    "npc": "Archive Clerk",
    "text": "The broken machinery in the east wings carry them. But beware the enforcers in the boss chamber.",
    "choices": [{"label": "[Leave]", "next": "end"}]
  },
  "npc_01_fix": {
    "npc": "Archive Clerk",
    "text": "A noble pursuit. Though everything here eventually breaks anyway. Such is the system.",
    "choices": [{"label": "[Leave]", "next": "end"}]
  }
}
```

### NPCs

**NPC 1: Archive Clerk** (in NPC room, zone 3)
- 3 dialogue nodes + end nodes
- Provides quest hint: collect 3 soul_fragments to unlock exit; boss enforcers guard final door

**NPC 2: Wandering Soul** (in exploration area, zone 2)
- 3 dialogue nodes + end nodes
- Flavor dialogue about the afterlife, hints at lore

---

## 7. Win/Lose Conditions

**Win:** Player reaches exit portal (Central Archive door) AND MiniBoss is defeated  
**Lose:** Player `current_hp <= 0` → Game Over screen → Restart option

---

## 8. Level Layout: Single Map (Level01.tscn)

**Zones (TileMap layers): floor, wall, decoration)**

1. **Entrance Room** (20x15 tiles) — spawn point, tutorial signage (implicit)
2. **Open Exploration Area** (40x30 tiles) — 4 Grunts patrolling; 2 item spawns (heal_potion, speed_boost)
3. **NPC Room** (15x12 tiles) — Archive Clerk (static); wall decoration
4. **Corridor** (10x20 tiles) — 2 Ranged enemies on platforms; item spawn (plating)
5. **Boss Room** (25x25 tiles) — MiniBoss spawn point; locked door (exit) on far side; 2 soul_fragment pickup points; atmospheric lighting (PointLight2D dim, color blue)
6. **Exit Portal** — Animated Node2D (rotation tween); only activates after boss death

**Lighting:**
- Player carries PointLight2D (radius 200px, color #fff5e0)
- Boss room: ambient darkness (ColorRect dark overlay) until boss defeated, then light fades in

**Doors & Progress Gates:**
- Corridor → Boss Room: unlocked initially
- Boss Room → Exit: locked until MiniBoss death (Area2D with collision; disabled on `enemy_died` signal with `is_boss=true`)

---

## 9. Balance Targets

- **Playtime:** 8–12 minutes for first-time player
- **Difficulty:** Moderate — player can survive with 1–2 hits per enemy if using cover and healing
- **Encounters:** Grunt (solo or pairs), Ranged (from distance), MiniBoss (3–5 attempts expected)
- **Resources:** Starting 100 HP + 1 heal potion found in exploration; additional drops random
- **Soul Fragment Requirement:** 3 total dropped from Grunts (25% chance) and Ranged (100%) → average 3+ available by boss

**Tuning Knobs:** JSON stats — adjust `attack`, `defense`, `hp` values; cooldowns in .gd scripts.

---

## 10. Required Assets (all placeholder)

- **Sprites:** Colored rectangles via ColorRect or Sprite2D with CanvasItemMaterial
  - Player: #4488ff (blue)
  - Grunt: #ff4444 (red)
  - Ranged: #ffaa00 (orange)
  - MiniBoss: #aa00ff (purple)
  - Items: green (heal), cyan (speed), yellow (weapon), gray (armor)
- **Tiles:** 32x32 pixel colored squares
  - floor: #666666 (dark gray)
  - wall: #333333 (dark charcoal)
  - decoration: #888888 (medium gray)
- **UI:** Basic Theme with default Control styling
- **Audio:** None (silent placeholder)

---

## 11. Architecture Notes

- **Autoload:** GameManager (scene switching, global state), DialogueManager (dialogue trees), SaveManager (optional, not required)
- **Data Loading:** JSON parse at startup into global dictionaries
- **Signals:** `player_died`, `enemy_died`, `item_picked_up`, `dialogue_closed`
- **Testing:** Unit tests for formulas; integration tests for state machine transitions

---

## 12. Acceptance Criteria

**Phase 3 (Implementation) completes when:**
1. Player moves 8-dir with correct speed
2. Combat deals damage with knockback and invincibility
3. All 3 enemy types behave as specified
4. Inventory collects and uses 5 items correctly
5. Dialogue system branches with typewriter effect
6. HUD displays HP, inventory hotbar, notifications
7. Level01.tscn contains all zones and transitions
8. Win/lose conditions trigger appropriate screens

**Phase 4 (QA) completes when:**
- All checklist items pass with 0 high-severity bugs
- Balance targets met (playtest 5min → 12min range)

**Phase 5 (Polish) completes when:**
- Screen shake, hit flash, particles, damage numbers, item bobbing, transitions all implemented

---

**Document Status:** Ready for implementation.
