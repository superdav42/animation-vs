# Henry's Wild Run

A complete 2D arena-game vertical slice built with Godot 4.7. Ride strange vehicles, unlock increasingly powerful gear, and survive a 60-second round in a living techno-forest.

All game visuals are drawn procedurally in GDScript. The project does not depend on third-party art, music, or sound packs.

## Play

Open the project in Godot 4.7.x and press **F6**, or run:

```sh
godot --path .
```

The home screen provides five destinations:

1. **Play a Round** — survive escalating enemy waves and earn parts.
2. **Garage** — buy four vehicles, four weapons, and four abilities across four power tiers.
3. **Control Mode** — switch between desktop keybinds and on-screen mobile controls.
4. **Loadout** — equip one unlocked item from each category.
5. **How to Play** — view controls and ability instructions.

Progress, purchases, selected equipment, control mode, and best score are saved locally under Godot's `user://` storage.

## Controls

### Keyboard mode

- **WASD / arrow keys:** move
- **Space:** attack
- **Q:** use the equipped ability
- **Shift:** boost the equipped vehicle
- **Mouse:** aim and choose ability targets
- **Escape:** leave the current round

### Mobile mode

Use the on-screen direction pad and **Attack**, **Power**, and **Boost** buttons. Vine Weaver asks for a start and destination tap; nearby tree branches act as snap points. Phase Blink asks for a destination tap.

## Progression

| Tier | Vehicles | Weapons | Abilities |
| --- | --- | --- | --- |
| Rough | Scrap Board | Rusty Dagger | Ember Pop |
| Good | Trail Bike | Pulse Bow | Vine Weaver |
| Great | Neon Buggy | Arc Blaster | Phase Blink |
| Legendary | Pocket Rocket | Flamethrower | Solar Inferno |

## Verification

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/smoke_test.gd
```

See [`DESIGN.md`](DESIGN.md) for the visual and interaction system and [`assets/ATTRIBUTION.md`](assets/ATTRIBUTION.md) for asset provenance.
