# Animation VS — Design System

## Product direction

Animation VS is a friendly top-down stick-figure duel where player choices create a fair but unpredictable CPU rival. Sessions last one minute, provide visible progression, and encourage experimentation with optional equipment and earned cosmetics.

## Match contract

- Weapons are mandatory and establish the CPU weapon tier.
- New profiles receive one random Rough-tier starter weapon rather than a fixed weapon.
- CPU weapons are randomly drawn from a separate pool and can never be the player's weapon.
- Vehicles and abilities are optional. Each occupied player slot produces a different CPU counterpart at the same tier; each empty player slot forces the matching CPU slot to remain empty.
- A knockout ends the match immediately. Timeout compares remaining-health percentages so vehicle armour does not create an unfair tiebreaker.

## Visual language

- **Atmosphere:** moonlit techno-forest with deep navy surfaces, luminous mint vegetation, and warm cream typography.
- **Sides:** the player uses mint and cream; the CPU uses magenta, violet, and red. These side colours remain consistent across health bars, vehicles, projectiles, vines, and effects.
- **Palette:** `#07121e` night, `#43d9bd` player mint, `#f5f0d7` cream, `#e969a0` CPU magenta, `#ffd56b` parts.
- **Fighters:** both sides are unmistakable animated stick figures. Moving limbs communicate travel; skins change head silhouettes and details without weakening the readable line-body form.
- **Shapes:** rounded panels and controls contrast with angular vehicles, projectiles, and mountain silhouettes.
- **Motion:** drifting spores, pulsing terrain, growing vines, expanding ability rings, projectile trails, strafing CPU movement, and vehicle effects provide feedback without imported animation assets.

All visuals are generated through `_draw()` methods or Godot primitives. Future art should preserve the silhouette-first approach and include clear licence provenance.

## Navigation and loadouts

The home screen uses one dominant Play action followed by Garage, Control Mode, Loadout, Customize Fighter, and How to Play. Parts and best score remain visible at the bottom. The loadout page presents explicit **On Foot** and **No Ability** choices before unlocked equipment, while never offering an empty weapon slot.

Gear is grouped into Rough, Good, Great, and Legendary tiers. Tier colour communicates value, while every item also has a text tier so progression never depends on colour alone.

Skins are purchased in the Garage exclusively with earned parts. Customize Fighter separates owned-skin selection from free line-colour and face-design controls. CPU appearance always differs in silhouette and face design so the two stick figures remain easy to distinguish.

## Input principles

- Desktop and mobile are explicit player-selected modes.
- Mobile targets are at least 60 virtual pixels high.
- Attack is always available; Power and Boost communicate when their optional slots are empty.
- Targeted powers use a short instruction at the top of the arena.
- Vine Weaver connects two chosen world points and snaps its origin to nearby branches, making background terrain mechanically meaningful.

## Gameplay readability

The arena header mirrors **YOU** and **CPU**, with separate colour-coded health bars, weapon names, and a central timer. The CPU's complete randomized draw appears briefly as the round begins. Match results report victory, defeat, draw, or forfeit along with damage, score, opposing weapon, and parts earned.
