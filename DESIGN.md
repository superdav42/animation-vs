# Animation VS — Design System

## Product direction

Animation VS is a friendly top-down stick-figure duel where player choices create a fair but unpredictable CPU rival. Sessions last one minute, provide visible progression, and encourage experimentation with optional equipment and earned cosmetics.

## Match contract

- Weapons are mandatory and establish the CPU weapon tier.
- New profiles receive one random Rough-tier starter weapon rather than a fixed weapon.
- CPU weapons are randomly drawn from a separate pool and can never be the player's weapon.
- Vehicles and abilities are optional. Each occupied player slot produces a different CPU counterpart at the same tier; each empty player slot forces the matching CPU slot to remain empty. CPU selection prefers a different combat style whenever its tier offers one.
- A knockout ends the match immediately. Timeout compares remaining-health percentages so vehicle armour does not create an unfair tiebreaker.
- Fighters have side-view gravity and a grounded jump. Gravity Wings and explicitly flyable vehicles permit sustained flight, and teleported fighters fall naturally.
- In local multiplayer, Player 1 is grounded on the lower platform while upside-down Player 2 uses reversed gravity from the upper platform. Larger jump impulses let both fighters contest the central lane.
- A 12% post-round roll replaces parts with one unowned gear item. Relative tier weights are Rough 60, Good 25, Epic 10, and Legendary 3.

## Visual language

- **Atmosphere:** four selectable original procedural stages—Neon Forest, Moon Dojo, Ember Foundry, and Crystal Cavern—share deep surfaces, restrained background contrast, and bright gameplay accents. Moon Dojo is the default for new and migrated profiles so the redesigned setting is immediately visible.
- **Sides:** the player uses mint and cream; the CPU uses magenta, violet, and red. These side colours remain consistent across health bars, vehicles, projectiles, vines, and effects.
- **Palette:** `#07121e` night, `#43d9bd` player mint, `#f5f0d7` cream, `#e969a0` CPU magenta, `#ffd56b` parts.
- **Fighters:** both sides are unmistakable animated stick figures. Dark outer strokes, bright inner limbs, highlighted joints, moving limbs, and distinct head silhouettes keep each pose readable against every arena.
- **Shapes:** rounded panels and controls contrast with angular vehicles, projectiles, and mountain silhouettes.
- **Motion:** drifting spores, foundry sparks, cavern mist, growing vines, layered ability rings, brighter projectile trails, speed streaks, wheel highlights, and animated rocket exhaust provide feedback without imported animation assets.
- **Texture:** equipment remains vector-drawn but no longer flat. Rivets, taped grips, circuitry, vents, tread marks, warning stripes, crystal facets, energy nodes, and layered ability effects create material identity without third-party texture files.

All visuals are generated through `_draw()` methods or Godot primitives. Future art should preserve the silhouette-first approach and include clear licence provenance.

The arena redesign follows background research principles used by successful 2D fighters: keep a broad, quiet combat lane; separate foreground, midground, and distant layers; reduce contrast with depth; reserve the highest contrast for fighters and projectiles; animate atmospheric details; and let environment storytelling support rather than overpower fighter silhouettes. Upper and lower multiplayer platforms use matching accent lines so both gravity surfaces read instantly. The resulting stages are original implementations, not copied assets.

## Navigation and loadouts

The home screen gives equal prominence to solo Play and local Multiplayer, then provides arena selection, Garage, Control Mode, Loadout, Customize Fighter, and How to Play. Parts and best score remain visible at the bottom. The loadout page presents explicit **On Foot** and **No Ability** choices before unlocked equipment, while never offering an empty weapon slot.

Gear is grouped into Rough, Good, Epic, and Legendary tiers. Rough prices start at 100 parts, Epic at 1,000, and Legendary at 1,500. Vehicles cost more than weapons at the same tier because their speed, armour, boost, and possible flight affect every moment of a round. Tier colour communicates value, while every item also has a text tier so progression never depends on colour alone.

Skins are purchased in the Garage exclusively with earned parts. Customize Fighter separates owned-skin selection from free line-colour and face-design controls. CPU appearance always differs in silhouette and face design so the two stick figures remain easy to distinguish.

## Input principles

- Desktop and mobile are explicit player-selected modes; keyboard controls remain conventional and never use the touch joystick.
- Mobile movement uses a dynamic joystick that appears at the initial touch point and disappears on release, preserving visibility while keeping thumb travel short.
- Persistent mobile action targets are at least 94 virtual pixels high.
- A dedicated persistent Jump button provides an unambiguous grounded jump for each mobile fighter; upward joystick input remains reserved for Gravity Wings flight.
- Attack is always available; Power and Boost communicate when their optional slots are empty.
- Targeted powers use a short instruction at the top of the arena.
- Vine Weaver connects two chosen world points and snaps its origin to nearby branches, making background terrain mechanically meaningful.
- Multiplayer first presents Player 2 with the owner's purchased weapons, vehicles, and abilities. A weapon is mandatory; vehicle and ability provide explicit empty choices.
- Local multiplayer mirrors two dynamic joysticks and action sets. Player 2, the top platform, and the top controls are rotated 180 degrees, while joystick vectors are inverted into screen space for face-to-face play across a phone or tablet.

## Gameplay readability

The arena header mirrors **YOU** and **CPU**, with separate colour-coded health bars, weapon names, and a central timer. The CPU's complete randomized draw appears briefly as the round begins. Match results report victory, defeat, draw, or forfeit along with damage, score, opposing weapon, and parts earned.
