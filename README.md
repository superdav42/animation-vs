# Animation VS

A complete 2D stick-figure player-versus-CPU arena game built with Godot 4.7. Build and customize a fighter, draw a matched but different CPU rival, and win a one-minute duel in a living techno-forest.

All visuals are drawn procedurally in GDScript. The project does not depend on third-party art, music, or sound packs.

## Play

Open the project in Godot 4.7.x and press **F5**, or run:

```sh
godot --path .
```

The home screen provides eight destinations:

1. **Play a Round** — fight a randomized CPU rival and earn parts.
2. **Multiplayer** — start a face-to-face local duel with mirrored touch controls.
3. **Choose Arena** — select Neon Forest, Moon Dojo, Ember Foundry, or Crystal Cavern before starting.
4. **Garage** — buy vehicles, weapons, abilities, and cosmetic skins using earned parts.
5. **Control Mode** — switch between desktop keybinds and on-screen mobile controls.
6. **Loadout** — equip a required weapon plus an optional vehicle and ability.
7. **Customize Fighter** — wear an owned skin and choose line colour and face design.
8. **How to Play** — view duel rules, controls, and targeting instructions.

Progress, purchases, selected equipment, control mode, and best score are saved locally under Godot's `user://` storage.

## CPU matching rules

- A first-time player receives one randomly selected Rough-tier weapon from the Rusty Dagger, Battered Bat, and Tin Popgun.
- The player must always keep a weapon equipped.
- Every CPU receives a randomly selected weapon from a separate pool at the player's tier. When possible, it also uses a different combat style, such as melee versus projectile.
- If the player equips a vehicle, the CPU receives a different vehicle at the same tier.
- If the player equips an ability, the CPU receives a different ability at the same tier.
- If the player leaves the vehicle or ability slot empty, the CPU must leave that slot empty too.
- Defeat the CPU before 60 seconds expire. At timeout, the fighter with the greater percentage of health remaining wins.
- Gravity keeps ordinary fighters and every vehicle on the floor. Gravity Wings are required for free flight; teleport abilities can move upward, but the fighter falls afterward.
- Most rounds award parts. A 12% reward roll replaces parts with one random unowned weapon, vehicle, or ability; Rough gear is most common and Legendary gear is rarest.

## Controls

### Keyboard mode

- **A / D or left / right arrows:** move along the ground
- **W / up arrow:** fly only while Gravity Wings are equipped
- **Space:** attack
- **Q:** use the equipped ability, when present
- **Shift:** boost the equipped vehicle, when present
- **Mouse:** aim and choose ability targets
- **Escape:** forfeit the round

### Mobile mode

Touch and drag in the left movement zone. A large joystick appears under the thumb only while it is being used and disappears on release. Drag sideways to move or upward to fly when Gravity Wings are equipped. The larger **Attack**, **Power**, and **Boost** buttons remain on the right. Power and Boost clearly show as unavailable when their optional gear slots are empty. Vine Weaver asks for a start and destination tap; nearby environment anchors act as snap points. Phase Blink asks for a destination tap.

### Face-to-face multiplayer

Player 1 uses the large controls at the bottom of the device. Player 2 uses a second control set at the top, rotated 180 degrees so opponents can play from opposite sides of a phone or tablet. Both players receive different gear, and neither fighter is controlled by the CPU.

## Player progression

| Tier | Vehicle | Weapon | Ability |
| --- | --- | --- | --- |
| Rough | Scrap Board | Rusty Dagger | Ember Pop |
| Good | Trail Bike | Pulse Bow | Vine Weaver |
| Great | Neon Buggy | Arc Blaster | Phase Blink / Gravity Wings |
| Legendary | Pocket Rocket | Flamethrower | Solar Inferno |

The CPU has multiple visually distinct vehicles, weapons, and abilities across the tiers. Selection favours a different combat style as well as different names and silhouettes, so it never copies the player's loadout.

## Stick fighters and skins

Both sides use animated stick figures with moving arms and legs. Player skins alter the head silhouette and details: Classic Lines, Street Runner, Shadow Ninja, Frame Bot, and Cosmic Orbit. Skins cost only parts earned in-game—there are no real-money purchases. The CPU automatically chooses a different silhouette, colour, and face design for each fight. Weapons and vehicles use procedural rivets, tape, circuits, vents, grids, hazard stripes, and energy details; abilities use layered rings, leaves, sparks, mist, and animated wing patterns.

## Verification

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/smoke_test.gd
```

See [`DESIGN.md`](DESIGN.md) for the visual and interaction system and [`assets/ATTRIBUTION.md`](assets/ATTRIBUTION.md) for asset provenance.
