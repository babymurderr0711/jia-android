# Jia reference artwork and animation pipeline

## Canonical source

The approved character reference is the transparent PNG supplied in the conversation (1245 x 1040 RGBA). Preserve its face, copper-red hairstyle, proportions, linework, palette and pixel texture. Do not redraw or substitute a different character.

The current source is a single flattened pose. It is suitable as a visual reference and temporary portrait, but not as a complete skeletal rig.

## Layer plan

Prepare the character as aligned transparent layers on one shared canvas:

1. rear hair
2. rear torso / hips
3. upper legs and lower legs
4. neck and head base
5. face features: eyes open, eyes closed, brows and mouth expressions
6. front hair and fringe
7. upper arms, forearms and hands
8. outfit details
9. feet and nail overlays

Keep original canvas dimensions and origin so layers can be recombined without drift. Reconstruct only occluded anatomy needed for the supported motion range; do not stretch the flattened original to fake joint movement.

## First animation pass

- idle: subtle breathing and hair sway
- face: blink and a small set of mouth / expression swaps
- pose set: original kneeling pose first, then seated and standing only after the hidden body parts are reconstructed
- interaction: hand/foot response animations tied to actual interaction zones
- customization: manicure and pedicure overlays attached to the corresponding hand/foot layers

## Godot implementation

Use Skeleton2D / Bone2D for limbs once the artwork is separated. Use AnimationPlayer for idle, blink, pose transitions and reactions. Keep the source PNG untouched as the canonical reference asset.

Until separated layers are available, the procedural character in main.gd remains a temporary interaction prototype, not the final Jia artwork or a production rig.
