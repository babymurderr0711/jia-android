# Jia's Place — character art and animation pipeline

## Canonical source and constraints

The approved source is the transparent 1245×1040 PNG supplied in the conversation. Preserve the face, copper-red hairstyle, proportions, linework, palette and texture. The original must remain untouched. Do not substitute a generated or generic character.

The source is a single flattened pose. It is not possible to obtain clean independent limb motion by simply stretching or rotating the whole bitmap. A proper rig needs aligned transparent layers and reconstruction of the anatomy hidden in the original pose.

## Current implementation (procedural interaction prototype)

- Idle motion: breathing, body bob, blink timing, eye gaze and hair sway.
- Facial reactions: soft, happy, shy, surprised and sleepy states.
- Joint-segment drawing: upper/lower arm segments with elbow points and upper/lower leg segments with knee points.
- Pose editor: independent arm and leg bend controls, plus pose presets.
- Interaction: drag-based massage progress, reaction pulse, mood / closeness / energy feedback.
- Customization: manicure and pedicure color overlays.

This pass makes the current placeholder react and articulate more convincingly. It is not yet a production Skeleton2D rig and it does not yet render the approved reference artwork.

## Four parallel production tracks

### 1. Canonical artwork import
- Bring the exact approved PNG into godot/assets/jia/source/.
- Preserve the original file as the immutable source.
- Create aligned transparent layers on the original canvas: rear hair, torso/hips, legs, head/face, fringe/front hair, upper arms, forearms/hands, outfit details, feet and nail overlays.
- Keep a source-to-layer manifest so the pieces can be revised without losing alignment.

### 2. Skeleton and joint rig
- Build a Skeleton2D hierarchy for torso, neck/head, shoulders, elbows, wrists, hips, knees and ankles.
- Attach the separated art layers to the corresponding bones.
- Reconstruct hidden anatomy rather than distorting the original bitmap.
- Keep manicure and pedicure overlays parented to the hand and foot bones.

### 3. Animation set
- AnimationPlayer clips: idle breathing, blink, gaze, hair sway, head turns, arm gestures, leg/foot movement, pose transitions and reactions.
- Blend pose transitions instead of snapping between presets.
- Use additive micro-motion for breathing and hair on top of the selected pose.
- Tie animation states to mood, closeness and energy.

### 4. Pose editor and interactions
- Expand the current arm/leg controls into per-joint editing with saveable pose presets.
- Add touch zones for head, hands, feet and body with distinct feedback animations.
- Make massage and beauty interactions visible on the character, not just in dialogue or counters.
- Ensure nail overlays follow the animated fingers and toes.

## Acceptance checks

- The canonical art is visibly the same character as the approved reference.
- No limb stretches unnaturally at elbows or knees during supported poses.
- Hands and feet keep their nail overlays attached during movement.
- Idle animation is continuous and subtle; expressions do not flicker.
- Each interaction produces a visible character response and a state change.
- The Android export completes and the APK is installable before calling the build finished.
