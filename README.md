# UnitMode

> Play WoW Classic as a Warcraft III unit — 4 abilities, no more.

A World of Warcraft Classic addon that strips your action bar down to 4 core abilities + 1 ultimate, applies a WC3-style unit portrait overlay, and lets you roleplay as a Warcraft III unit. Pick a preset (Paladin → Uther the Lightbringer, Warlock → Warlock Adept), or build your own and share it as a UMv1 export string — like WeakAuras but for your unit identity.

---

## Status

**v0.1.0 — Unreleased.** All core features implemented. Targeting WoW Classic Era (1.15.x). Pending CurseForge review submission.

---

## Features

- **13 built-in unit presets** across 4 factions (Alliance, Horde, Undead, Night Elf)
- **Action bar lockdown** — 4 core slots + 1 ultimate; all other bars hidden while UnitMode is active
- **WC3-style portrait overlay** with class icon and faction color accent
- **Custom unit builder** — define your own unit name, faction, portrait, and ability loadout; export/import as a UMv1 string (shareable in chat or Discord)
- **Per-character SavedVariables** — settings don't bleed between alts
- **Minimap button** for quick toggle access

---

## Commands

```
/unitmode       — Open the UnitMode panel
/um             — Shorthand alias

/um enable      — Enable UnitMode for this character
/um disable     — Disable UnitMode (restores default action bars)
/um reset       — Reset to default settings for this character
/um status      — Print current unit, faction, and enabled state to chat
```

---

## Installation

### Manual
1. Download the latest release
2. Extract to `World of Warcraft/_classic_era_/Interface/AddOns/UnitMode/`
3. Restart WoW or reload the UI (`/reload`)
4. Enable UnitMode in the AddOns list at the character select screen

### CurseForge
*(Pending approval — Curse Project ID: 1550490)*

---

## File Structure

```
UnitMode/
├── UnitMode.toc        Interface version, load order
├── Init.lua            SavedVariables setup, defaults
├── UnitLibrary.lua     Built-in unit preset definitions
├── ActionBar.lua       Bar lockdown and slot assignment logic
├── CustomBuilder.lua   Custom unit editor + UMv1 export/import
├── Portrait.lua        WC3 portrait overlay frame
├── MinimapBtn.lua      Minimap button
└── UI.lua              Main panel, preset browser, settings
```

---

## UMv1 Export Format

Custom units can be shared as a compact string:

```
UMv1:UnitName:Faction:PortraitID:Ability1:Ability2:Ability3:Ability4:Ultimate
```

Paste the string into the Custom Builder import field to load a unit shared by another player.

---

## Roadmap

- **v0.1.0** — CurseForge submission + initial release
- **v0.2.0** — Expanded preset library; additional factions (Burning Legion, Draenei)
- **v0.3.0** — Per-zone auto-switching (e.g., enable automatically in Alterac Valley)
- **Future** — Wrath of the Lich King Classic compatibility

---

## Compatibility

- WoW Classic Era (Interface 11508)
- Does not modify protected frames — fully Blizzard ToS compliant
- Compatible with ElvUI and WeakAuras (action bar modifications may conflict — disable bar overlays in those addons if needed)

---

## License

MIT
