# Jia's Place — character art and animation pipeline

## Canonical source and constraints

The approved source is the transparent 1245×1040 PNG supplied in the conversation. Preserve the face, copper-red hairstyle, proportions, linework, palette and texture. The original must remain untouched. Do not substitute a generated or generic character.

The source is a single flattened pose. It is not possible to obtain clean independent limb motion by simply stretching or rotating the whole bitmap. A proper production rig requires aligned transparent layers and reconstruction of the anatomy hidden in the original pose.

## Current implementation

- A live `Skeleton2D` hierarchy is now instantiated in `Main.tscn`: root, pelvis, torso, neck, head, hair, shoulders, elbows, wrists, hips, knees and ankles.
- The fallback character is assembled from separate vector surfaces parented to bones. Hands have five fingers, feet have toe/nail overlays, and clothing has separate upper/lower surfaces.
- Five pose states are supported. Bone rotations blend toward pose targets while breathing and small idle movements continue.
- Face geometry responds to sleepy, shy and surprised states; hair, outfit color/silhouette, manicure and pedicure are controlled by gameplay state.
- Touch zones, relationship dialogue, mood/energy responses and a timed rhythm mini-game are connected to the world simulation.
- Daily needs, schedule events, inventory, rest/time progression and save/load are implemented.
- The room is a static illustrated bedroom background. It is intentionally not an interactive furniture editor.
- Procedural ambient music and soft original chime effects have volume/on-off controls saved in the player profile.

**Important limitation:** this is a functioning articulated fallback rig, not the final approved painted character. The original 1245×1040 image is not yet imported into the Godot project, and the fallback vector surfaces do not reproduce its exact face, texture, clothing detail or anatomy.

## Remaining production tracks

### 1. Canonical artwork import and anatomical reconstruction
- Import the exact approved PNG into `godot/assets/jia/source/`.
- Preserve the original file as the immutable source.
- Create aligned transparent layers on the original canvas: rear hair, torso/hips, legs, head/face, fringe/front hair, upper arms, forearms/hands, outfit details, feet and nail overlays.
- Reconstruct hidden anatomy behind the original pose; do not stretch the flattened image or invent missing limbs by rotating narrow cutouts.
- Keep a source-to-layer manifest so pieces can be revised without losing alignment.

### 2. Production art rig
- Replace the vector fallback surfaces with the reconstructed transparent artwork.
- Bind the art layers to the existing Skeleton2D hierarchy.
- Validate shoulder, elbow, wrist, hip, knee and ankle deformations from front, side and rear poses.
- Keep manicure and pedicure overlays attached to the hand and foot bones.

### 3. Animation polish
- Add authored AnimationPlayer clips for idle breathing, blink, gaze, hair sway, head turns, gestures and transitions.
- Improve the current five pose presets with tested silhouettes and natural joint limits.
- Tie facial and body animation to mood, closeness and energy.
- Check every pose for self-intersections, stretched limbs and foot/hand orientation.

### 4. Gameplay and presentation
- Expand dialogue from sequential lines into contextual conversations and unlockable relationship scenes.
- Add more mini-games, event variety, needs and daily schedule branches.
- Continue balancing wardrobe visuals and visible beauty interactions.
- Finish UI layout, audio options and Android performance profiling.

## Verification

- CI imports the Godot project and launches the main scene headlessly.
- A world simulation smoke test checks consumables, touch progression, rest/time advancement and save/load.
- The Android APK is intentionally not treated as a deliverable until the art/gameplay pass is complete and a final Android export is verified.
