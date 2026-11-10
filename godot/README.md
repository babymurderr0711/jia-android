# Jia's Place — Godot prototype

A native Godot 4 project for the Jia character-life game.

## Open
Open this folder in Godot 4.3+ and run Main.tscn.

## Prototype interactions
- Bottom buttons cycle through preset poses, manicure, pedicure, and massage.
- Drag on the screen to interact with the massage gesture.
- Right-side buttons offer pose, massage, beauty, and gift actions.
- Mood, closeness, energy, coins, and dialogue update in real time.

## Next production pass
Replace the procedural articulated placeholder with the approved layered character artwork and a Skeleton2D rig. Keep the same state/actions API so cosmetics and poses continue to drive the live model.


## Android CI export
The Android Gradle template is installed by the repository workflow into `android/build`. Keep this directory visible to Godot's `res://` filesystem; do not add `android/.gdignore`, because the Android exporter checks `res://android/build/build.gradle`.
