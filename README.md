# Animation VS

A complete 2D stick-figure player-versus-CPU arena game built with Godot 4.7. Build and customize a fighter, draw a matched but different CPU rival, and win a one-minute duel in a living techno-forest.

All visuals are drawn procedurally in GDScript. The project does not depend on third-party art, music, or sound packs.

## Play

Open the project in Godot 4.7.x and press **F6**, or run:

```sh
godot --path .
```

The home screen provides six destinations:

1. **Play a Round** — fight a randomized CPU rival and earn parts.
2. **Garage** — buy vehicles, weapons, abilities, and cosmetic skins using earned parts.
3. **Control Mode** — switch between desktop keybinds and on-screen mobile controls.
4. **Loadout** — equip a required weapon plus an optional vehicle and ability.
5. **Customize Fighter** — wear an owned skin and choose line colour and face design.
6. **How to Play** — view duel rules, controls, and targeting instructions.

Progress, purchases, selected equipment, control mode, and best score are saved locally under Godot's `user://` storage.

## CPU matching rules

- A first-time player receives one randomly selected Rough-tier weapon from the Rusty Dagger, Battered Bat, and Tin Popgun.
- The player must always keep a weapon equipped.
- Every CPU receives a randomly selected, different weapon from the same tier as the player's weapon.
- If the player equips a vehicle, the CPU receives a different vehicle at the same tier.
- If the player equips an ability, the CPU receives a different ability at the same tier.
- If the player leaves the vehicle or ability slot empty, the CPU must leave that slot empty too.
- Defeat the CPU before 60 seconds expire. At timeout, the fighter with the greater percentage of health remaining wins.

## Controls

### Keyboard mode

- **WASD / arrow keys:** move
- **Space:** attack
- **Q:** use the equipped ability, when present
- **Shift:** boost the equipped vehicle, when present
- **Mouse:** aim and choose ability targets
- **Escape:** forfeit the round

### Mobile mode

Use the on-screen direction pad and **Attack**, **Power**, and **Boost** buttons. Power and Boost clearly show as unavailable when their optional gear slots are empty. Vine Weaver asks for a start and destination tap; nearby tree branches act as snap points. Phase Blink asks for a destination tap.

## Player progression

| Tier | Vehicle | Weapon | Ability |
| --- | --- | --- | --- |
| Rough | Scrap Board | Rusty Dagger | Ember Pop |
| Good | Trail Bike | Pulse Bow | Vine Weaver |
| Great | Neon Buggy | Arc Blaster | Phase Blink |
| Legendary | Pocket Rocket | Flamethrower | Solar Inferno |

The CPU has its own visually distinct vehicle and ability for every tier, plus two possible weapons per tier so repeat rounds can produce different matchups.

## Stick fighters and skins

Both sides use animated stick figures with moving arms and legs. Player skins alter the head silhouette and details: Classic Lines, Street Runner, Shadow Ninja, Frame Bot, and Cosmic Orbit. Skins cost only parts earned in-game—there are no real-money purchases. The CPU automatically chooses a different silhouette, colour, and face design for each fight.

## Verification

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/smoke_test.gd
```

See [`DESIGN.md`](DESIGN.md) for the visual and interaction system and [`assets/ATTRIBUTION.md`](assets/ATTRIBUTION.md) for asset provenance.
