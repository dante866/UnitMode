-- UnitMode: WC3 unit presets

UnitMode.Units = {}
local Units = UnitMode.Units

-- Each unit: name, faction, class, core (4 ability display names), ultimate
-- Ability names are guidance only — player drags the actual spells into the slots.
Units.library = {

    -- ── Alliance ──────────────────────────────────────────────────────────────
    footman = {
        name     = "Footman",
        faction  = "Alliance",
        class    = "Warrior",
        core     = { "Sunder Armor", "Shield Bash", "Shield Block", "Taunt" },
        ultimate = "Shield Wall",
    },
    paladin_hero = {
        name     = "Paladin Hero",
        faction  = "Alliance",
        class    = "Paladin",
        core     = { "Holy Light", "Devotion Aura", "Divine Shield", "Blessing of Might" },
        ultimate = "Resurrection",
    },
    priest_alliance = {
        name     = "Priest",
        faction  = "Alliance",
        class    = "Priest",
        core     = { "Heal", "Dispel Magic", "Inner Fire", "Power Word: Shield" },
        ultimate = "Prayer of Healing",
    },
    sorceress = {
        name     = "Sorceress",
        faction  = "Alliance",
        class    = "Mage",
        core     = { "Arcane Missiles", "Slow (Frostbolt)", "Polymorph", "Blink" },
        ultimate = "Blizzard",
    },
    rifleman = {
        name     = "Dwarven Rifleman",
        faction  = "Alliance",
        class    = "Hunter",
        core     = { "Aimed Shot", "Concussive Shot", "Hunter's Mark", "Multi-Shot" },
        ultimate = "Flare",
    },

    -- ── Horde ─────────────────────────────────────────────────────────────────
    orc_grunt = {
        name     = "Orc Grunt",
        faction  = "Horde",
        class    = "Warrior",
        core     = { "Battle Shout", "Cleave", "Whirlwind", "Intimidating Shout" },
        ultimate = "Berserker Rage",
    },
    troll_headhunter = {
        name     = "Troll Headhunter",
        faction  = "Horde",
        class    = "Hunter",
        core     = { "Raptor Strike", "Mongoose Bite", "Serpent Sting", "Wing Clip" },
        ultimate = "Berserking",
    },
    far_seer = {
        name     = "Far Seer",
        faction  = "Horde",
        class    = "Shaman",
        core     = { "Chain Lightning", "Far Sight", "Earth Shock", "Purge" },
        ultimate = "Earthquake (Thunderstorm)",
    },
    tauren_warrior = {
        name     = "Tauren Warrior",
        faction  = "Horde",
        class    = "Warrior",
        core     = { "Thunderclap", "Mocking Blow", "Shockwave (Retaliation)", "War Stomp" },
        ultimate = "Retaliation",
    },

    -- ── Undead ────────────────────────────────────────────────────────────────
    forsaken_ghoul = {
        name     = "Forsaken Ghoul",
        faction  = "Undead",
        class    = "Rogue",
        core     = { "Sinister Strike", "Slice and Dice", "Kidney Shot", "Cannibalize" },
        ultimate = "Evasion",
    },
    necromancer = {
        name     = "Necromancer",
        faction  = "Undead",
        class    = "Warlock",
        core     = { "Shadow Bolt", "Curse of Agony", "Corruption", "Fear" },
        ultimate = "Rain of Fire",
    },

    -- ── Night Elf ─────────────────────────────────────────────────────────────
    archer = {
        name     = "Archer",
        faction  = "Night Elf",
        class    = "Hunter",
        core     = { "Shoot", "Multi-Shot", "Scatter Shot", "Concussive Shot" },
        ultimate = "Rapid Fire",
    },
    keeper = {
        name     = "Keeper of the Grove",
        faction  = "Night Elf",
        class    = "Druid",
        core     = { "Entangling Roots", "Force of Nature", "Rejuvenation", "Moonfire" },
        ultimate = "Hurricane",
    },
}

-- Canonical display order for factions in the UI
Units.factionOrder = { "Alliance", "Horde", "Undead", "Night Elf" }

-- Looks up a unit by key, checking built-ins first then custom units.
-- Custom units are stored under their plain key in UnitModeDB.customUnits
-- but exposed in the sorted list as "custom_<key>" to avoid collisions.
function Units:Get(key)
    if self.library[key] then return self.library[key] end
    if UnitMode.db and UnitMode.db.customUnits then
        local customKey = key:match("^custom_(.+)$")
        if customKey then
            return UnitMode.db.customUnits[customKey]
        end
    end
    return nil
end

-- Returns all units (built-in + custom) sorted by faction order then name.
function Units:GetSorted()
    local factionIndex = {}
    for i, f in ipairs(self.factionOrder) do
        factionIndex[f] = i
    end

    local list = {}
    for key, unit in pairs(self.library) do
        list[#list + 1] = { key = key, unit = unit }
    end
    if UnitMode.db and UnitMode.db.customUnits then
        for key, unit in pairs(UnitMode.db.customUnits) do
            list[#list + 1] = { key = "custom_" .. key, unit = unit }
        end
    end

    table.sort(list, function(a, b)
        local fa = factionIndex[a.unit.faction] or 99
        local fb = factionIndex[b.unit.faction] or 99
        if fa ~= fb then return fa < fb end
        return a.unit.name < b.unit.name
    end)

    return list
end
