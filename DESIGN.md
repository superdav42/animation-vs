# Henry's Wild Run — Design System

## Product direction

Henry's Wild Run is a friendly top-down survival game where scrappy machinery meets living magic. Sessions should be understandable immediately, last one minute, and always advance the player's collection.

## Visual language

- **Atmosphere:** moonlit techno-forest with deep navy surfaces, luminous mint vegetation, and warm cream typography.
- **Palette:** `#07121e` night, `#43d9bd` mint, `#f5f0d7` cream, `#ffd56b` parts, `#ef5d75` danger.
- **Shapes:** rounded panels and controls contrast with angular creatures, vehicles, projectiles, and mountain silhouettes.
- **Typography:** large condensed-feeling uppercase labels using Godot's system font; supporting copy stays short and high contrast.
- **Motion:** drifting spores, pulsing terrain, growing vines, expanding ability rings, projectile trails, and vehicle boost effects provide feedback without imported animation assets.

All visuals are generated through `_draw()` methods or Godot primitives. Future art should preserve the same silhouette-first approach and must include clear licence provenance.

## Navigation

The home screen uses one dominant Play action followed by Garage, Control Mode, Loadout, and How to Play. Parts and best score remain visible at the bottom. Every secondary page has an obvious Home action and avoids modal navigation.

## Progression

Gear is grouped into Rough, Good, Great, and Legendary tiers. Tier colour communicates value, while each item also has a text tier so progression never depends on colour alone. A player equips exactly one vehicle, weapon, and ability.

## Input principles

- Desktop and mobile are explicit player-selected modes.
- Mobile targets are at least 60 virtual pixels high.
- The same three verbs exist in both modes: attack, power, and boost.
- Targeted powers use a short instruction at the top of the arena.
- Vine Weaver connects two chosen world points and snaps its origin to nearby branches, making background terrain mechanically meaningful.

## Gameplay readability

The arena reserves its top strip for score, time, wave, health, and equipment status. Enemies use warm colours, Henry and terrain use cool colours, and rewards use yellow. Hit points appear directly above enemies. Procedural effects fade quickly to avoid obscuring movement.
