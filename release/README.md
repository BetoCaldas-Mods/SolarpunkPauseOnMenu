# SolarpunkPauseOnMenu

Pauses the game when you open the ESC menu and unpauses when you close it.

## Requirements

- **Solarpunk** (Steam)
- **UE4SS** (experimental build) — minimum tested: `UE4SS_v3.0.1-954-g272ce2f8`
  or newer with UE 5.7.1 support  
  https://github.com/UE4SS-RE/RE-UE4SS/releases
- UE4SS installed in the game's **shipping** folder:
  ```
  <Steam>\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\
  ```
  (next to `SolarpunkSteam-Win64-Shipping.exe`, not the root launcher)

> UE4SS is **not** included in this zip. You must install it separately.

### UE 5.7.1 setup (if UE4SS fails to start)

In `UE4SS-settings.ini`, set:

```
[EngineVersionOverride]
MajorVersion = 5
MinorVersion = 7
```

If UE4SS logs `PS Scan failed` or hangs at startup, you may need custom
signatures. See the full guide:  
https://github.com/BetoCaldas-Mods/SolarpunkPauseOnMenu

---

## Install

1. Install UE4SS in `...\Solarpunk\Binaries\Win64\` (see Requirements).
2. Copy the `SolarpunkPauseOnMenu` folder from this zip into:
   ```
   <Steam>\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\Mods\
   ```
3. The mod is enabled via `enabled.txt` (included).  
   Alternatively, add this line to `Mods\mods.txt`:
   ```
   SolarpunkPauseOnMenu : 1
   ```

Final layout:

```
...\Win64\Mods\SolarpunkPauseOnMenu\
    enabled.txt
    scripts\
        main.lua
```

---

## Usage

- Press **ESC** to open the menu → game pauses.
- Press **ESC** again to close the menu → game unpauses.

Default mode is `toggle` (pause on each ESC). No extra configuration needed.

### Optional: discover menu widget (advanced)

Press **F8** with the ESC menu open to list on-screen widgets in the UE4SS
console. Use this only if you switch to `detect` mode in `scripts/main.lua`.

---

## Troubleshooting

| Problem | What to try |
|---|---|
| Nothing happens | Confirm UE4SS loaded (console may be hidden). Check files are in the `Win64` shipping folder. |
| UE4SS won't start | Use experimental build + engine override 5.7. See full README on GitHub. |
| Pause desyncs | Press ESC once more, or switch to `detect` mode (see full guide). |

---

## Full documentation

https://github.com/BetoCaldas-Mods/SolarpunkPauseOnMenu
