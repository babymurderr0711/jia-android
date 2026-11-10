# Jia's Place — character art and animation pipeline

## Canonical source and constraints

The approved turnaround is the 1480×1536 four-view sheet supplied in the conversation. The first 370×1536 panel is the front view used for the in-game rig. Preserve the face, copper-red hairstyle, proportions, linework, palette and texture. The source sheet must remain untouched. Do not substitute a generated or generic character.

The source is a single flattened pose. It is not possible to obtain clean independent limb motion by simply stretching or rotating the whole bitmap. A proper production rig requires aligned transparent layers and reconstruction of the anatomy hidden in the original pose.

## Current implementation

- A live `Skeleton2D` hierarchy is instantiated in `Main.tscn`: root, pelvis, torso, neck, head, hair, shoulders, elbows, wrists, hips, knees and ankles.
- CI extracts the front panel from the approved four-view turnaround and generates 14 registered transparent cutouts: head, torso, upper arms, forearms, hands, thighs, shins and feet.
- All 14 cutouts are attached to their corresponding bones with pivots aligned to the front-view artwork. Hands now have separate wrist sprites, so wave gestures can rotate the hand independently of the forearm.
- Cutout alpha is intersected with the source alpha; transparent background pixels are not made opaque. Draw order is layered back-to-front to reduce joint overlap artifacts.
- Five pose states are supported. Bone rotations blend toward pose targets while breathing and small idle movements continue. A wrist gesture target drives the separate hand sprites.
- CI smoke tests check the 14 texture attachments, shoulder/elbow/wrist/knee/ankle bone mapping, pose changes and finite bone rotations.
- The artwork pipeline currently uses overlapping polygon masks on a flattened front view. It is a segmented cutout rig, not a skinned mesh; hidden anatomy is not yet fully reconstructed and extreme rotations can expose seams or missing pixels.
- Face geometry responds to sleepy, shy and surprised states; outfit color/silhouette, manicure and pedicure remain connected to gameplay state.
- Touch zones, relationship dialogue, mood/energy responses and a timed rhythm mini-game are connected to the world simulation.
- Daily needs, schedule events, inventory, rest/time progression and save/load are implemented.
- The room is a static illustrated bedroom background. Procedural ambient music and soft original chime effects have volume/on-off controls saved in the player profile.

**Important limitation:** the approved front-view artwork is now imported as 14 articulated cutouts, but the character is not yet production-finished. This is not smooth mesh deformation, and the side/rear turnaround panels are reference-only. Joint seams, hidden anatomy, and transitions between views still need visual review and correction.

## Remaining production tracks

### 1. Articulated cutout refinement
- Review generated layers in the running Godot scene at native scale.
- Refine mask contours and overlap at shoulders, elbows, wrists, hips, knees and ankles.
- Reconstruct missing anatomy under joints so moderate bends do not reveal gaps.
- Keep manicure and pedicure overlays attached to the hand and foot bones.

### 2. Production art rig
- Add mesh deformation or authored replacement shapes where cutout rotation produces visible distortion.
- Validate shoulder, elbow, wrist, hip, knee and ankle movement from front, side and rear poses.
- Keep the turnaround side and rear views as references for future alternate-view sprites; do not rotate the front sprite to fake a side view.

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
