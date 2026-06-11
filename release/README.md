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

The experimental UE4SS layout looks like this after install:

```
...\Win64\
    dwmapi.dll
    ue4ss\
        UE4SS.dll
        UE4SS-settings.ini
        Mods\
```

---

## Install

### 1. Install UE4SS

Extract the experimental UE4SS package into `...\Solarpunk\Binaries\Win64\`.

### 2. Engine version override (required)

Open `...\Win64\ue4ss\UE4SS-settings.ini` and set:

```ini
[EngineVersionOverride]
MajorVersion = 5
MinorVersion = 7
```

### 3. Copy UE4SS signatures (required for SolarPunk)

SolarPunk uses UE **5.7.1**. The built-in UE4SS scanner cannot find all
required functions on its own. This zip includes custom signatures for the
current game build.

Copy the `UE4SS_Signatures` folder from this zip into:

```
<Steam>\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\ue4ss\UE4SS_Signatures\
```

Result:

```
...\ue4ss\UE4SS_Signatures\
    FName_Constructor.lua
    GUObjectArray.lua
    StaticConstructObject.lua
```

> After a game patch, signatures may need to be regenerated. Check the GitHub
> repo for updated files or the full guide.

### 4. Copy the mod

Copy the `SolarpunkPauseOnMenu` folder from this zip into:

```
<Steam>\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\ue4ss\Mods\
```

> **Not** `Win64\Mods\` at the root. The experimental UE4SS build loads mods
> from `ue4ss\Mods\`.

The mod is enabled via `enabled.txt` (included).  
Alternatively, add this line to `ue4ss\Mods\mods.txt`:

```
SolarpunkPauseOnMenu : 1
```

### Final layout

```
...\Win64\
    dwmapi.dll
    ue4ss\
        UE4SS-settings.ini
        UE4SS_Signatures\
            FName_Constructor.lua
            GUObjectArray.lua
            StaticConstructObject.lua
        Mods\
            SolarpunkPauseOnMenu\
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
| Nothing happens | Confirm the mod is in `ue4ss\Mods\`, not `Win64\Mods\`. Check `ue4ss\UE4SS.log`. |
| UE4SS won't start / `PS scan timed out` | Install signatures from this zip into `ue4ss\UE4SS_Signatures\`. Set engine override 5.7. |
| Worked before a game update | Regenerate or download new signatures from GitHub. |
| Pause desyncs | Press ESC once more, or switch to `detect` mode (see full guide). |

---

## Full documentation

https://github.com/BetoCaldas-Mods/SolarpunkPauseOnMenu
