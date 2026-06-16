-- ============================================
-- ESP Game Mod - Complete Version
-- ============================================
-- This script provides comprehensive game modifications including:
--   ESP (Extra Sensory Perception) - Player detection with name, weapon, team ID, distance
--   Environment Control - Rain, Snow, Black Sky, Fog/Grass/Tree/Water removal
--   Movement Control - Anti-gravity, speed boost, character rotation, wall climb, size control
--   Weapon Effects - Weapon orbit (Luffy), rainbow outline, weapon scaling
--   Visual Settings - 165 FPS, iPad view
--   Combat Settings - No recoil, quick scope, fast switch, wallbang, super bullet, infinite ammo
--   Wallhack - Player visibility through walls with customizable colors
-- 
-- THIS LUA SOURCE CODE IS PROVIDED FOR FREE
-- If you paid for this, you have been scammed
-- Join the official community for updates
-- ============================================
_G.ESPConfig = _G.ESPConfig or {
    -- ESP Settings
    Enabled = true,
    ShowAI = true,
    ShowName = true,
    ShowWeapon = true,
    ShowTeamId = true,
    ShowDistance = true,
    DrawDistance = 350,
    MinNameFont = 0.33,
    MaxNameFont = 1.0,
    
    -- Environment Settings
    RainEnabled = false,
    SnowEnabled = false,
    BlackSky = false,
    RemoveFog = false,
    RemoveGrass = false,
    RemoveTree = false,
    RemoveWater = false,
    ForceChinese = false,
    
    -- Movement/Character Settings
    AntiGravity = false,
    GravityScale = -0.45,
    JumpHeight = 1350,
    SpeedBoost = false,
    SpeedPercent = 250,
    CharacterRotation = false,
    CharacterRotationSpeed = 360,
    WallClimb = false,
    CharScale = 1.0,
    EnemyScale = 1.0,
    
    -- Weapon Settings
    WeaponLuffy = false,
    WeaponSoul = false,
    WeaponRainbow = false,
    WeaponScale = 1.0,
    
    -- Visual Settings
    FPS165 = false,
    IpadView = false,
    IpadFov = 90,
    
    -- Combat Settings
    NoRecoil = false,
    NoRecoilADS = false,
    AntiShake = false,
    CrossDeviation = false,
    QuickScope = false,
    FastSwitch = false,
    GunWallbang = false,
    SuperBullet = 1,
    SuperFireRate = false,
    SuperFireRateValue = 0.008,
    InfiniteAmmo = false,
    AutoAim = false,
    HitEffect = 3.5,
    
    -- Wallhack Settings
    Wallhack = false,
    WallhackVisibleColor = 1,
    WallhackInvisibleColor = 2,
    WallhackBrightness = 25,
    WallhackGlow = 3.0
}

-- ESP State
-- Module variables
local SettingUtil
local GameplayData

-- Initialize required game modules (SettingUtil, GameplayData)
-- Free publisher @zmkzkz4
local function InitializeModules()
    if not SettingUtil then
        SettingUtil = require("client.slua.logic.setting.setting_util")
    end
    if not GameplayData then
        GameplayData = require("GameLua.GameCore.Data.GameplayData")
    end
end

-- Check if object is valid
-- Free publisher @zmkzkz4
local function IsValid(obj)
    return slua.isValid(obj)
end

-- Get game instance for console commands
-- Free publisher @zmkzkz4
local function GetGameInstance()
    if slua_GameFrontendHUD then
        return slua_GameFrontendHUD:GetGameInstance()
    end
    InitializeModules()
    if SettingUtil and SettingUtil.GetGameInstance then
        return SettingUtil:GetGameInstance()
    end
    return nil
end

-- Get player controller
-- Free publisher @zmkzkz4
local function GetPlayerController()
    if slua_GameFrontendHUD then
        return slua_GameFrontendHUD:GetPlayerController()
    end
    return nil
end

-- Get player character from controller
-- Free publisher @zmkzkz4
local function GetPlayerCharacter()
    local playerController = GetPlayerController()
    if playerController then
        if playerController.GetPlayerCharacterSafety then
            return playerController:GetPlayerCharacterSafety()
        elseif playerController.GetPlayerCharacter then
            return playerController:GetPlayerCharacter()
        end
    end
    return nil
end

-- Execute console command through game instance
-- Free publisher @zmkzkz4
local function ExecuteConsoleCommand(cmd, value)
    local instance = GetGameInstance()
    if instance then
        pcall(function()
            instance:ExecuteCMD(cmd, value)
        end)
    end
end

-- Clamp value between min and max
-- Free publisher @zmkzkz4
local function ClampValue(value, min, max)
    return math.max(min or 0, math.min(max or 1000, value or 0))
end

-- Slider value conversion constants
-- GravityScale: range -0.45 to 1.0
-- CharScale/WeaponScale/EnemyScale: range 1 to 10
local GRAVITY_MIN = -0.45
local GRAVITY_MAX = 1.0
local GRAVITY_RANGE = 1.45
local SCALE_MIN = 1.0
local SCALE_MAX = 10.0
local SCALE_RANGE = 9.0

-- Normalize gravity value from -0.45-1.0 to 0-100 for UI slider
-- Free publisher @zmkzkz4
local function NormalizeGravity(value)
    return ((value - GRAVITY_MIN) / GRAVITY_RANGE) * 100
end

-- Denormalize gravity value from 0-100 to -0.45-1.0
-- Free publisher @zmkzkz4
local function DenormalizeGravity(normalized)
    return GRAVITY_MIN + (normalized / 100) * GRAVITY_RANGE
end

-- Normalize scale value from 1-10 to 0-100 for UI slider
-- Free publisher @zmkzkz4
local function NormalizeScale(value)
    return ((value - SCALE_MIN) / SCALE_RANGE) * 100
end

-- Denormalize scale value from 0-100 to 1-10
-- Free publisher @zmkzkz4
local function DenormalizeScale(normalized)
    return SCALE_MIN + (normalized / 100) * SCALE_RANGE
end

-- Enable or disable rain effect
-- Free publisher @zmkzkz4
function SetRainEnabled(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local EScreenParticleEffectType = import("EScreenParticleEffectType")
            if EScreenParticleEffectType then
                if playerCharacter.SetRainyEffectEnable then
                    if enabled then
                        playerCharacter:SetRainyEffectEnable(EScreenParticleEffectType.ESPET_Rainy, true, 500)
                    else
                        playerCharacter:SetRainyEffectEnable(EScreenParticleEffectType.ESPET_Rainy, false, 0)
                    end
                end
            end
        end
        
        local weatherSubsystem = SubsystemMgr.Get("CreativeModeWeatherSubsystem")
        if slua.isValid(weatherSubsystem) then
            if enabled then
                if weatherSubsystem.StartRainScreenEffect then
                    weatherSubsystem:StartRainScreenEffect()
                end
            else
                if weatherSubsystem.StopRainScreenEffect then
                    weatherSubsystem:StopRainScreenEffect()
                end
            end
        end
    end)
end

-- Enable or disable snow effect
-- Free publisher @zmkzkz4
function SetSnowEnabled(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local EScreenParticleEffectType = import("EScreenParticleEffectType")
            if EScreenParticleEffectType then
                if playerCharacter.SetRainyEffectEnable then
                    if enabled then
                        playerCharacter:SetRainyEffectEnable(EScreenParticleEffectType.ESPET_Snowy, true, 500)
                    else
                        playerCharacter:SetRainyEffectEnable(EScreenParticleEffectType.ESPET_Snowy, false, 0)
                    end
                end
            end
        end
        
        local weatherSubsystem = SubsystemMgr.Get("CreativeModeWeatherSubsystem")
        if slua.isValid(weatherSubsystem) then
            if enabled then
                if weatherSubsystem.StartSnowScreenEffect then
                    weatherSubsystem:StartSnowScreenEffect()
                elseif weatherSubsystem.StartRainScreenEffect then
                    weatherSubsystem:StartRainScreenEffect()
                end
            else
                if weatherSubsystem.StopSnowScreenEffect then
                    weatherSubsystem:StopSnowScreenEffect()
                elseif weatherSubsystem.StopRainScreenEffect then
                    weatherSubsystem:StopRainScreenEffect()
                end
            end
        end
    end)
end

-- Enable or disable black sky effect
-- Free publisher @zmkzkz4
function SetBlackSky(enabled)
    InitializeModules()
    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        if logic_setting_graphics and logic_setting_graphics.GetGameInstance then
            local gameInstance = logic_setting_graphics.GetGameInstance()
            if gameInstance then
                gameInstance:ExecuteCMD("r.CylinderMaxDrawHeight", enabled and "9999" or "0")
            end
        end
    end)
end

-- Enable or disable fog removal
-- Free publisher @zmkzkz4
function SetFogRemoval(enabled)
    InitializeModules()
    ExecuteConsoleCommand("r.Fog", enabled and "0" or "1")
    ExecuteConsoleCommand("r.VolumetricFog", enabled and "0" or "1")
end

-- Enable or disable grass removal
-- Free publisher @zmkzkz4
function SetGrassRemoval(enabled)
    InitializeModules()
    ExecuteConsoleCommand("grass.DensityScale", enabled and "0" or "1")
    ExecuteConsoleCommand("foliage.DensityScale", enabled and "0" or "1")
end

-- Enable or disable tree removal
-- Free publisher @zmkzkz4
function SetTreeRemoval(enabled)
    InitializeModules()
    ExecuteConsoleCommand("foliage.TreeDensityScale", enabled and "0" or "1")
end

-- Enable or disable water removal
-- Free publisher @zmkzkz4
function SetWaterRemoval(enabled)
    InitializeModules()
    ExecuteConsoleCommand("r.Water", enabled and "0" or "1")
end

-- Enable or disable anti-gravity
-- Free publisher @zmkzkz4
function SetAntiGravity(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local movement = playerCharacter.CharacterMovement or playerCharacter.CharMoveComp
            if movement then
                movement.GravityScale = enabled and _G.ESPConfig.GravityScale or 1.0
                if enabled then
                    movement.JumpZVelocity = _G.ESPConfig.JumpHeight
                end
            end
        end
    end)
end

-- Update gravity scale setting
-- Free publisher @zmkzkz4
function SetGravityScale()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local movement = playerCharacter.CharacterMovement or playerCharacter.CharMoveComp
            if movement then
                if _G.ESPConfig.AntiGravity then
                    movement.GravityScale = _G.ESPConfig.GravityScale
                end
            end
        end
    end)
end

-- Update jump height setting
-- Free publisher @zmkzkz4
function SetJumpHeight()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local movement = playerCharacter.CharacterMovement or playerCharacter.CharMoveComp
            if movement then
                movement.JumpZVelocity = _G.ESPConfig.JumpHeight
            end
        end
    end)
end

-- Speed boost using AttrModifyComp
_G.SpeedBoostState = _G.SpeedBoostState or {active = false, timer = nil, modifyId = nil, currentChar = nil, percent = 250}

-- Remove speed modification from character
-- Free publisher @zmkzkz4
local function RemoveSpeedModify(character)
    if not slua.isValid(character) then return end
    if not character.AttrModifyComp then return end
    
    if _G.SpeedBoostState.modifyId then
        pcall(function()
            character.AttrModifyComp:RemoveModifyItemFromCache(_G.SpeedBoostState.modifyId)
        end)
        _G.SpeedBoostState.modifyId = nil
    end
end

-- Apply speed modification to character using AttrModifyComp
-- Free publisher @zmkzkz4
local function ApplySpeedModify(character)
    if not slua.isValid(character) then return end
    if not character.AttrModifyComp then return end
    
    RemoveSpeedModify(character)
    
    local percent = _G.SpeedBoostState.percent
    local rate = (percent / 100.0) - 1.0
    
    pcall(function()
        _G.SpeedBoostState.modifyId = character.AttrModifyComp:AddModifyItemAndCache("SpeedRate", 0, rate, true, character, false)
    end)
end

-- Update speed boost effect every frame
-- Free publisher @zmkzkz4
local function UpdateSpeedBoost()
    if not _G.SpeedBoostState.active then return end
    
    local playerController = slua_GameFrontendHUD:GetPlayerController()
    if not slua.isValid(playerController) then return end
    
    local playerCharacter = playerController:GetPlayerCharacterSafety()
    if not slua.isValid(playerCharacter) then return end
    
    if _G.SpeedBoostState.currentChar ~= playerCharacter then
        if _G.SpeedBoostState.currentChar then
            RemoveSpeedModify(_G.SpeedBoostState.currentChar)
        end
        _G.SpeedBoostState.currentChar = playerCharacter
    end
    
    ApplySpeedModify(playerCharacter)
end

-- Enable or disable speed boost
-- Free publisher @zmkzkz4
function SetSpeedBoost(enabled)
    InitializeModules()
    _G.SpeedBoostState.percent = _G.ESPConfig.SpeedPercent or 250
    
    if enabled then
        if _G.SpeedBoostState.timer then return end
        
        _G.SpeedBoostState.active = true
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(playerController) and playerController.AddGameTimer then
            _G.SpeedBoostState.timer = playerController:AddGameTimer(0.3, true, UpdateSpeedBoost)
        end
    else
        _G.SpeedBoostState.active = false
        
        if _G.SpeedBoostState.timer then
            local playerController = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(playerController) and playerController.RemoveGameTimer then
                playerController:RemoveGameTimer(_G.SpeedBoostState.timer)
            end
            _G.SpeedBoostState.timer = nil
        end
        
        if _G.SpeedBoostState.currentChar then
            RemoveSpeedModify(_G.SpeedBoostState.currentChar)
            _G.SpeedBoostState.currentChar = nil
        end
    end
end

-- Update speed percent setting
-- Free publisher @zmkzkz4
function SetSpeedPercent()
    InitializeModules()
    _G.SpeedBoostState.percent = _G.ESPConfig.SpeedPercent or 250
    
    if _G.SpeedBoostState.active and _G.SpeedBoostState.currentChar then
        ApplySpeedModify(_G.SpeedBoostState.currentChar)
    end
end

-- Character rotation using Mesh rotation (based on reference code)
_G.CharacterRotationState = _G.CharacterRotationState or {
    CONFIG = {
        ENABLED = false,
        SPEED = 999,
        INTERVAL = 0.016,
    },
    timer = nil,
    currentYaw = 0
}

-- Get local player character
-- Free publisher @zmkzkz4
local function GetLocalPlayerChar()
    return GameplayData.GetPlayerCharacter()
end

-- Check if object is valid (safe check)
-- Free publisher @zmkzkz4
local function ValidObj(obj)
    if not obj then return false end
    local ok, r = pcall(function() return slua.isValid(obj) end)
    return ok and r
end

-- Update character mesh rotation every frame
-- Free publisher @zmkzkz4
local function UpdateCharacterRotation()
    if not _G.CharacterRotationState.CONFIG.ENABLED then return end
    
    local ch = GetLocalPlayerChar()
    if not ValidObj(ch) then return end
    
    local mesh = ch.Mesh
    if not ValidObj(mesh) then return end
    
    _G.CharacterRotationState.currentYaw = _G.CharacterRotationState.currentYaw + _G.CharacterRotationState.CONFIG.SPEED * _G.CharacterRotationState.CONFIG.INTERVAL
    if _G.CharacterRotationState.currentYaw >= 360 then 
        _G.CharacterRotationState.currentYaw = _G.CharacterRotationState.currentYaw - 360
    elseif _G.CharacterRotationState.currentYaw < 0 then 
        _G.CharacterRotationState.currentYaw = _G.CharacterRotationState.currentYaw + 360
    end
    
    local rot = mesh:K2_GetComponentRotation()
    rot.Yaw = _G.CharacterRotationState.currentYaw
    mesh:K2_SetWorldRotation(rot, false, nil, false)
end

-- Start character rotation timer
-- Free publisher @zmkzkz4
local function StartCharacterRotation()
    if _G.CharacterRotationState.timer then return end
    
    local ch = GetLocalPlayerChar()
    if not ValidObj(ch) then return end
    
    local mesh = ch.Mesh
    if not ValidObj(mesh) then return end
    
    _G.CharacterRotationState.currentYaw = mesh:K2_GetComponentRotation().Yaw
    _G.CharacterRotationState.timer = ch:AddGameTimer(_G.CharacterRotationState.CONFIG.INTERVAL, true, UpdateCharacterRotation)
end

-- Stop character rotation timer
-- Free publisher @zmkzkz4
local function StopCharacterRotation()
    if _G.CharacterRotationState.timer then
        local ch = GetLocalPlayerChar()
        if ValidObj(ch) and ch.RemoveGameTimer then
            ch:RemoveGameTimer(_G.CharacterRotationState.timer)
        end
        _G.CharacterRotationState.timer = nil
    end
end

-- Enable or disable character rotation
-- Free publisher @zmkzkz4
function SetCharacterRotation(enabled)
    InitializeModules()
    
    _G.CharacterRotationState.CONFIG.ENABLED = enabled
    _G.CharacterRotationState.CONFIG.SPEED = _G.ESPConfig.CharacterRotationSpeed or 999
    
    if enabled then
        pcall(function()
            local function tryStart()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                if not pc then return end
                local ch = GetLocalPlayerChar()
                if not ValidObj(ch) then 
                    pc:AddGameTimer(1.0, false, tryStart)
                    return
                end
                StartCharacterRotation()
            end
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if pc and pc.AddGameTimer then 
                pc:AddGameTimer(2.5, false, tryStart)
            else 
                tryStart()
            end
        end)
    else
        StopCharacterRotation()
    end
end

-- Update character rotation speed setting
-- Free publisher @zmkzkz4
function SetCharacterRotationSpeed()
    InitializeModules()
    _G.CharacterRotationState.CONFIG.SPEED = _G.ESPConfig.CharacterRotationSpeed or 999
end

-- Enable or disable wall climb
-- Free publisher @zmkzkz4
function SetWallClimb(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local movement = playerCharacter.CharacterMovement or playerCharacter.CharMoveComp
            if movement then
                if enabled then
                    movement.WalkableFloorAngle = 199.0
                    movement.MaxStepHeight = 999.0
                else
                    movement.WalkableFloorAngle = 45.0
                    movement.MaxStepHeight = 45.0
                end
            end
        end
    end)
end

-- Update player character scale
-- Free publisher @zmkzkz4
function SetCharScale()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if slua.isValid(playerCharacter) then
            local scale = _G.ESPConfig.CharScale
            playerCharacter:SetActorScale3D(FVector(scale, scale, scale))
        end
    end)
end

-- Update enemy character scale
-- Free publisher @zmkzkz4
function SetEnemyScale()
    InitializeModules()
    pcall(function()
        local allCharacters = Game:GetAllPlayerPawns()
        if not allCharacters then return end
        
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local myTeam = playerCharacter.TeamID or 0
        local scale = _G.ESPConfig.EnemyScale
        
        for _, character in pairs(allCharacters) do
            if slua.isValid(character) and character ~= playerCharacter then
                local targetTeam = character.TeamID or 0
                if targetTeam ~= myTeam then
                    character:SetActorScale3D(FVector.new(scale, scale, scale))
                end
            end
        end
    end)
end

-- Update weapon scale
-- Free publisher @zmkzkz4
function SetWeaponScale()
    InitializeModules()
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local weaponManager = player:GetWeaponManager()
        if not slua.isValid(weaponManager) then return end
        
        local currentSlot = nil
        if weaponManager.GetCurrentUsingPropSlot then
            currentSlot = weaponManager:GetCurrentUsingPropSlot()
        elseif weaponManager.GetCurrentWeaponSlot then
            currentSlot = weaponManager:GetCurrentWeaponSlot()
        elseif weaponManager.CurrentWeaponSlot then
            currentSlot = weaponManager.CurrentWeaponSlot
        end
        
        if currentSlot and weaponManager.GetInventoryWeaponByPropSlot then
            local currentWeapon = weaponManager:GetInventoryWeaponByPropSlot(currentSlot)
            if slua.isValid(currentWeapon) then
                local scale = _G.ESPConfig.WeaponScale
                currentWeapon:SetActorScale3D(FVector.new(scale, scale, scale))
            end
        end
    end)
end

-- Weapon Orbit System
_G.WeaponOrbitState = _G.WeaponOrbitState or {active = false}

-- Check if object is valid (safe check)
-- Free publisher @zmkzkz4
local function IsValidObject(obj)
    if not obj then return false end
    local ok, r = pcall(function() return slua.isValid(obj) end)
    return ok and r
end

-- Get local player character
-- Free publisher @zmkzkz4
local function GetLocalPlayerCharacter()
    return GameplayData.GetPlayerCharacter()
end

-- Get current weapon slot index
-- Free publisher @zmkzkz4
local function GetCurrentWeaponSlot()
    local character = GetLocalPlayerCharacter()
    if not IsValidObject(character) then return nil end
    local weaponManager = character:GetWeaponManager()
    if not IsValidObject(weaponManager) then return nil end
    if weaponManager.GetCurrentUsingPropSlot then
        return weaponManager:GetCurrentUsingPropSlot()
    elseif weaponManager.GetCurrentWeaponSlot then
        return weaponManager:GetCurrentWeaponSlot()
    elseif weaponManager.CurrentWeaponSlot then
        return weaponManager.CurrentWeaponSlot
    end
    return nil
end

-- Get all weapons from character's backpack
-- Free publisher @zmkzkz4
local function GetAllBackWeapons()
    local weaponList = {}
    local character = GetLocalPlayerCharacter()
    if not IsValidObject(character) then return weaponList end
    local weaponManager = character:GetWeaponManager()
    if not IsValidObject(weaponManager) then return weaponList end
    local currentSlot = GetCurrentWeaponSlot()
    for slot = 0, 5 do
        local weapon = nil
        if weaponManager.GetInventoryWeaponByPropSlot then
            weapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
        elseif weaponManager.GetWeaponBySlot then
            weapon = weaponManager:GetWeaponBySlot(slot)
        elseif weaponManager.GetInventoryWeapon then
            weapon = weaponManager:GetInventoryWeapon(slot)
        end
        if IsValidObject(weapon) and slot ~= currentSlot then
            table.insert(weaponList, weapon)
        end
    end
    return weaponList
end

-- Convert HSV color to RGB color
-- Free publisher @zmkzkz4
local function HueToRGB(hue, saturation, value)
    if not saturation then saturation = 1 end
    if not value then value = 1 end
    local index = math.floor(hue * 6)
    local fraction = hue * 6 - index
    local p = value * (1 - saturation)
    local q = value * (1 - fraction * saturation)
    local t = value * (1 - (1 - fraction) * saturation)
    index = index % 6
    if index == 0 then return value, t, p
    elseif index == 1 then return q, value, p
    elseif index == 2 then return p, value, t
    elseif index == 3 then return p, q, value
    elseif index == 4 then return t, p, value
    else return value, p, q end
end

-- Get rainbow color (changes over time)
-- Free publisher @zmkzkz4
local function GetRainbowColor()
    _G.RainbowHue = (_G.RainbowHue or 0) + 0.05
    if _G.RainbowHue >= 1 then _G.RainbowHue = 0 end
    local r, g, b = HueToRGB(_G.RainbowHue, 1, 1)
    return FLinearColor(r, g, b, 1)
end

-- Apply outline effect to weapon with specified color
-- Free publisher @zmkzkz4
local function ApplyOutlineToWeapon(weapon, color)
    if not IsValidObject(weapon) then return false end
    local ok, meshComponent = pcall(function() return import("/Script/Engine.MeshComponent") end)
    if not ok then return false end
    local ok2, components = pcall(function() return weapon:GetComponentsByClass(meshComponent) end)
    if not ok2 then return false end
    local applied = false
    for _, component in pairs(components) do
        if component and slua.isValid(component) then
            if component.SetDrawIdeaOutline then
                pcall(function() component:SetDrawIdeaOutline(true) end)
                if color and component.OverrideIdeaOutlineColor then
                    pcall(function() component:OverrideIdeaOutlineColor(true, color) end)
                end
                if component.OverrideIdeaOutlineThickness then
                    pcall(function() component:OverrideIdeaOutlineThickness(true, 3) end)
                end
                applied = true
            elseif component.SetRenderCustomDepth then
                pcall(function() component:SetRenderCustomDepth(true) end)
                applied = true
            end
        end
    end
    return applied
end

-- Clear outline effect from weapon
-- Free publisher @zmkzkz4
local function ClearOutlineFromWeapon(weapon)
    if not IsValidObject(weapon) then return end
    local ok, meshComponent = pcall(function() return import("/Script/Engine.MeshComponent") end)
    if not ok then return end
    local ok2, components = pcall(function() return weapon:GetComponentsByClass(meshComponent) end)
    if not ok2 then return end
    for _, component in pairs(components) do
        if component and slua.isValid(component) then
            if component.SetDrawIdeaOutline then
                pcall(function() component:SetDrawIdeaOutline(false) end)
            elseif component.SetRenderCustomDepth then
                pcall(function() component:SetRenderCustomDepth(false) end)
            end
        end
    end
end

-- Update rainbow outline for all weapons
-- Free publisher @zmkzkz4
local function UpdateAllWeaponOutlines()
    local character = GetLocalPlayerCharacter()
    if not IsValidObject(character) then return end
    local weaponManager = character:GetWeaponManager()
    if not IsValidObject(weaponManager) then return end
    local color = GetRainbowColor()
    for slot = 0, 10 do
        local weapon = nil
        if weaponManager.GetInventoryWeaponByPropSlot then
            weapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
        end
        if IsValidObject(weapon) then
            ApplyOutlineToWeapon(weapon, color)
        end
    end
end

-- Clear outline effect from all weapons
-- Free publisher @zmkzkz4
local function ClearAllWeaponOutlines()
    local character = GetLocalPlayerCharacter()
    if not IsValidObject(character) then return end
    local weaponManager = character:GetWeaponManager()
    if not IsValidObject(weaponManager) then return end
    for slot = 0, 10 do
        local weapon = nil
        if weaponManager.GetInventoryWeaponByPropSlot then
            weapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
        end
        if IsValidObject(weapon) then
            ClearOutlineFromWeapon(weapon)
        end
    end
end

-- Start weapon effects (orbit, rainbow outline, scaling)
-- Free publisher @zmkzkz4
local function StartWeaponEffects()
    if _G.WeaponOrbitState.active then return end
    
    _G.WeaponOrbitState.active = true
    _G.WeaponOrbitState.timer = nil
    _G.WeaponOrbitState.accumulatedTime = 0
    _G.WeaponOrbitState.orbitWeapons = {}
    _G.WeaponOrbitState.orbitData = {}
    _G.WeaponOrbitState.savedAttachData = {}
    _G.WeaponOrbitState.originalScales = {}
    _G.WeaponOrbitState.detached = false
    
    local function RecordOriginalScale(weapon)
        if not IsValidObject(weapon) then return end
        local key = tostring(weapon)
        if _G.WeaponOrbitState.originalScales[key] then return end
        local ok, scale = pcall(function() return weapon:GetActorScale3D() end)
        if ok then
            _G.WeaponOrbitState.originalScales[key] = FVector(scale.X, scale.Y, scale.Z)
        end
    end
    
    local function RestoreOriginalScale(weapon)
        if not IsValidObject(weapon) then return end
        local key = tostring(weapon)
        if _G.WeaponOrbitState.originalScales[key] then
            pcall(function() weapon:SetActorScale3D(_G.WeaponOrbitState.originalScales[key]) end)
            _G.WeaponOrbitState.originalScales[key] = nil
        end
    end
    
    local function DetachWeapons()
        if _G.WeaponOrbitState.detached then return end
        _G.WeaponOrbitState.detached = true
        
        local attachmentRule = import("EAttachmentRule")
        for _, weapon in ipairs(_G.WeaponOrbitState.orbitWeapons) do
            if IsValidObject(weapon) then
                local key = tostring(weapon)
                if not _G.WeaponOrbitState.savedAttachData[key] then
                    _G.WeaponOrbitState.savedAttachData[key] = {
                        location = weapon:K2_GetActorLocation(),
                        rotation = weapon:K2_GetActorRotation(),
                        parent = weapon:GetAttachParentActor(),
                    }
                end
                weapon:K2_DetachFromActor(attachmentRule.KeepWorld, attachmentRule.KeepWorld, attachmentRule.KeepWorld)
            end
        end
    end
    
    local function InitializeOrbitData()
        for i, weapon in ipairs(_G.WeaponOrbitState.orbitWeapons) do
            if IsValidObject(weapon) and not _G.WeaponOrbitState.orbitData[tostring(weapon)] then
                _G.WeaponOrbitState.orbitData[tostring(weapon)] = {
                    orbitAngle = (360 / #_G.WeaponOrbitState.orbitWeapons) * (i - 1),
                    selfAngle = math.random(0, 360),
                    wobblePhase = math.random(0, 360),
                    radiusOffset = math.random(-20, 20),
                }
            end
        end
    end
    
    local function UpdateWeaponEffects()
        if not _G.WeaponOrbitState.active then return end
        
        local character = GetLocalPlayerCharacter()
        if not IsValidObject(character) then return end
        
        local weaponManager = character:GetWeaponManager()
        if not IsValidObject(weaponManager) then return end
        
        -- 获取当前武器
        local currentSlot = GetCurrentWeaponSlot()
        local currentWeapon = nil
        if currentSlot and weaponManager.GetInventoryWeaponByPropSlot then
            currentWeapon = weaponManager:GetInventoryWeaponByPropSlot(currentSlot)
        end
        
        -- 武器放大 - 只放大当前武器
        if IsValidObject(currentWeapon) and _G.ESPConfig.WeaponScale then
            local scale = _G.ESPConfig.WeaponScale
            if scale > 0 then
                RecordOriginalScale(currentWeapon)
                pcall(function() currentWeapon:SetActorScale3D(FVector(scale, scale, scale)) end)
            end
        end
        
        -- 武器彩虹轮廓 - 只对当前武器应用
        if _G.ESPConfig.WeaponRainbow and IsValidObject(currentWeapon) then
            local color = GetRainbowColor()
            ApplyOutlineToWeapon(currentWeapon, color)
        end
        
        -- 枪魂（武器轨道）
        if _G.ESPConfig.WeaponLuffy then
            _G.WeaponOrbitState.orbitWeapons = GetAllBackWeapons()
            
            if #_G.WeaponOrbitState.orbitWeapons > 0 then
                -- 只分离一次武器
                DetachWeapons()
                
                -- 只初始化一次轨道数据
                InitializeOrbitData()
                
                -- 更新背包武器位置
                _G.WeaponOrbitState.accumulatedTime = _G.WeaponOrbitState.accumulatedTime + 0.016
                local centerLocation = character:K2_GetActorLocation()
                
                for _, weapon in ipairs(_G.WeaponOrbitState.orbitWeapons) do
                    if IsValidObject(weapon) and weapon ~= currentWeapon then
                        local key = tostring(weapon)
                        local data = _G.WeaponOrbitState.orbitData[key]
                        if data then
                            local orbitRad = math.rad(data.orbitAngle + _G.WeaponOrbitState.accumulatedTime * 180)
                            local radius = 150 + data.radiusOffset
                            local wobbleX = math.sin(_G.WeaponOrbitState.accumulatedTime * 3 + math.rad(data.wobblePhase)) * 30
                            local wobbleZ = math.cos(_G.WeaponOrbitState.accumulatedTime * 3.9 + math.rad(data.wobblePhase)) * 30
                            local offsetX = radius * math.cos(orbitRad) + wobbleX
                            local offsetY = radius * math.sin(orbitRad)
                            local offsetZ = 50 + wobbleZ
                            local newLocation = FVector(centerLocation.X + offsetX, centerLocation.Y + offsetY, centerLocation.Z + offsetZ)
                            pcall(function() weapon:K2_SetActorLocation(newLocation, false, nil, false) end)
                            
                            data.selfAngle = data.selfAngle + 5.76
                            if data.selfAngle >= 360 then data.selfAngle = data.selfAngle - 360 end
                            local selfRotation = FRotator(0, data.selfAngle, math.sin(_G.WeaponOrbitState.accumulatedTime * 6) * 15)
                            pcall(function() weapon:K2_SetActorRotation(selfRotation, false) end)
                        end
                    end
                end
            end
        end
    end
    
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and pc.AddGameTimer then
        _G.WeaponOrbitState.timer = pc:AddGameTimer(0.016, true, UpdateWeaponEffects)
    end
end

-- Stop weapon effects and restore original weapon state
-- Free publisher @zmkzkz4
local function StopWeaponEffects()
    if not _G.WeaponOrbitState.active then return end
    
    _G.WeaponOrbitState.active = false
    
    if _G.WeaponOrbitState.timer then
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and pc.RemoveGameTimer then
            pc:RemoveGameTimer(_G.WeaponOrbitState.timer)
        end
        _G.WeaponOrbitState.timer = nil
    end
    
    ClearAllWeaponOutlines()
    
    -- 恢复所有武器的原始缩放
    if _G.WeaponOrbitState.originalScales then
        local character = GetLocalPlayerCharacter()
        if IsValidObject(character) then
            local weaponManager = character:GetWeaponManager()
            if IsValidObject(weaponManager) then
                for slot = 0, 10 do
                    local weapon = nil
                    if weaponManager.GetInventoryWeaponByPropSlot then
                        weapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
                    end
                    if IsValidObject(weapon) then
                        local key = tostring(weapon)
                        if _G.WeaponOrbitState.originalScales[key] then
                            pcall(function() weapon:SetActorScale3D(_G.WeaponOrbitState.originalScales[key]) end)
                            _G.WeaponOrbitState.originalScales[key] = nil
                        end
                    end
                end
            end
        end
        _G.WeaponOrbitState.originalScales = {}
    end
    
    -- 重新附加武器
    if _G.WeaponOrbitState.savedAttachData then
        local attachmentRule = import("EAttachmentRule")
        for key, data in pairs(_G.WeaponOrbitState.savedAttachData) do
            if data.parent and IsValidObject(data.parent) then
                local weapon = nil
                local character = GetLocalPlayerCharacter()
                if IsValidObject(character) then
                    local weaponManager = character:GetWeaponManager()
                    if IsValidObject(weaponManager) then
                        for slot = 0, 10 do
                            if weaponManager.GetInventoryWeaponByPropSlot then
                                weapon = weaponManager:GetInventoryWeaponByPropSlot(slot)
                                if weapon and tostring(weapon) == key then
                                    break
                                end
                            end
                        end
                    end
                end
                if weapon and IsValidObject(weapon) then
                    weapon:K2_AttachToActor(data.parent, "None", attachmentRule.SnapToTarget, attachmentRule.SnapToTarget, attachmentRule.SnapToTarget, false)
                    weapon:K2_SetActorLocation(data.location, false, nil, false)
                    weapon:K2_SetActorRotation(data.rotation, false)
                end
            end
        end
        _G.WeaponOrbitState.savedAttachData = {}
    end
    
    _G.WeaponOrbitState.orbitData = {}
    _G.WeaponOrbitState.detached = false
end

-- Start weapon orbit (Luffy) effect
-- Free publisher @zmkzkz4
function StartWeaponLuffy()
    if not _G.WeaponOrbitState.active then
        StartWeaponEffects()
    end
end

-- Stop weapon orbit (Luffy) effect
-- Free publisher @zmkzkz4
function StopWeaponLuffy()
    if _G.ESPConfig.WeaponSoul == false and _G.ESPConfig.WeaponRainbow == false then
        StopWeaponEffects()
    end
end

-- Start weapon soul effect
-- Free publisher @zmkzkz4
function StartWeaponSoul()
    if not _G.WeaponOrbitState.active then
        StartWeaponEffects()
    end
end

-- Stop weapon soul effect
-- Free publisher @zmkzkz4
function StopWeaponSoul()
    if _G.ESPConfig.WeaponLuffy == false and _G.ESPConfig.WeaponRainbow == false then
        StopWeaponEffects()
    end
end

-- Start weapon rainbow outline effect
-- Free publisher @zmkzkz4
function StartWeaponRainbow()
    if not _G.WeaponOrbitState.active then
        StartWeaponEffects()
    end
end

-- Stop weapon rainbow outline effect
-- Free publisher @zmkzkz4
function StopWeaponRainbow()
    if _G.ESPConfig.WeaponLuffy == false and _G.ESPConfig.WeaponSoul == false then
        StopWeaponEffects()
    end
end

-- Visual control functions
-- Enable or disable 165 FPS
-- Free publisher @zmkzkz4
function SetFPS165(enabled)
    InitializeModules()
    pcall(function()
        local gameInstance = GetGameInstance()
        if slua.isValid(gameInstance) and gameInstance.ExecuteCMD then
            if enabled then
                gameInstance:ExecuteCMD("t.MaxFPS", "165")
                gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
            else
                gameInstance:ExecuteCMD("t.MaxFPS", "60")
                gameInstance:ExecuteCMD("r.FrameRateLimit", "60")
            end
        end
    end)
end

-- Enable or disable iPad view (wide FOV)
-- Free publisher @zmkzkz4
function SetIpadView(enabled)
    InitializeModules()
    pcall(function()
        local player = GetPlayerCharacter()
        if IsValid(player) then
            local camera = player.ThirdPersonCameraComponent
            if IsValid(camera) then
                if enabled then
                    camera:SetFieldOfView(_G.ESPConfig.IpadFov)
                else
                    camera:SetFieldOfView(90)
                end
            end
        end
    end)
end

-- Update iPad FOV setting
-- Free publisher @zmkzkz4
function SetIpadFov()
    InitializeModules()
    pcall(function()
        local player = GetPlayerCharacter()
        if IsValid(player) then
            local camera = player.ThirdPersonCameraComponent
            if IsValid(camera) then
                if _G.ESPConfig.IpadView then
                    camera:SetFieldOfView(_G.ESPConfig.IpadFov)
                else
                    camera:SetFieldOfView(90)
                end
            end
        end
    end)
end

-- Apply no recoil effect to weapon
-- Free publisher @zmkzkz4
function ApplyNoRecoil(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if enabled then
            shootComp.RecoilKick = 0
            shootComp.RecoilKickADS = 0
            shootComp.AnimationKick = 0
            shootComp.AccessoriesVRecoilFactor = 0.3
            shootComp.AccessoriesHRecoilFactor = 0.3
            
            if shootComp.RecoilInfo then
                shootComp.RecoilInfo.VerticalRecoilMin = 0
                shootComp.RecoilInfo.VerticalRecoilMax = 0
                shootComp.RecoilInfo.RecoilSpeedVertical = 0
                shootComp.RecoilInfo.RecoilSpeedHorizontal = 0
                shootComp.RecoilInfo.VerticalRecoveryMax = 0
            end
        else
            shootComp.RecoilKick = 1.0
            shootComp.RecoilKickADS = 1.0
            shootComp.AnimationKick = 1.0
            shootComp.AccessoriesVRecoilFactor = 1.0
            shootComp.AccessoriesHRecoilFactor = 1.0
        end
        
        if _G.ESPConfig.NoRecoilADS then
            shootComp.RecoilKickADS = 0
        end
        
        if _G.ESPConfig.AntiShake then
            shootComp.AnimationKick = 0
            if shootComp.CameraShakeScale then
                shootComp.CameraShakeScale = 0
            end
        end
        
        if _G.ESPConfig.CrossDeviation then
            shootComp.GameDeviationFactor = 0
            shootComp.GameDeviationAccuracy = 0
            shootComp.ShotGunHorizontalSpread = 0
            shootComp.ShotGunVerticalSpread = 0
        end
    end)
end

-- Apply quick scope effect (instant aiming)
-- Free publisher @zmkzkz4
function ApplyQuickScope(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if enabled then
            shootComp.WeaponAimInTime = 25.0
        else
            shootComp.WeaponAimInTime = 0.3
        end
    end)
end

-- Apply fast switch effect (instant weapon switching)
-- Free publisher @zmkzkz4
function ApplyFastSwitch(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if enabled then
            shootComp.SwitchFromBackpackToIdleTime = 0
            shootComp.SwitchFromIdleToBackpackTime = 0
        else
            shootComp.SwitchFromIdleToBackpackTime = 0.5
            shootComp.SwitchFromBackpackToIdleTime = 0.5
        end
    end)
end

-- Apply gun wallbang effect (shoot through walls)
-- Free publisher @zmkzkz4
function ApplyGunWallbang(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if enabled then
            shootComp.WeaponBodyLength = 0
        else
            shootComp.WeaponBodyLength = 100
        end
    end)
end

-- Apply super bullet effect (multiple bullets per shot)
-- Free publisher @zmkzkz4
function ApplySuperBullet()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if _G.ESPConfig.SuperBullet > 1 then
            shootComp.BulletNumSingleShot = _G.ESPConfig.SuperBullet
        else
            shootComp.BulletNumSingleShot = 1
        end
    end)
end

-- Apply super fire rate effect (faster shooting)
-- Free publisher @zmkzkz4
function ApplySuperFireRate(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if enabled then
            shootComp.ShootInterval = _G.ESPConfig.SuperFireRateValue
        else
            shootComp.ShootInterval = 0.1
        end
    end)
end

-- Apply infinite ammo effect
-- Free publisher @zmkzkz4
function ApplyInfiniteAmmo(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        shootComp.bClipHasInfiniteBullets = enabled
        shootComp.bHasInfiniteBullets = enabled
    end)
end

-- Apply auto aim effect
-- Free publisher @zmkzkz4
function ApplyAutoAim(enabled)
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if shootComp.AutoAimingConfig then
            for _, rangeType in ipairs({"OuterRange", "InnerRange"}) do
                local config = shootComp.AutoAimingConfig[rangeType]
                if config then
                    if enabled then
                        config.Speed = 11
                        config.adsorbMaxRange = 800
                        config.adsorbMinRange = 800
                    else
                        config.Speed = 1
                        config.adsorbMaxRange = 100
                        config.adsorbMinRange = 50
                    end
                end
            end
        end
    end)
end

-- Apply hit effect setting
-- Free publisher @zmkzkz4
function ApplyHitEffect()
    InitializeModules()
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local weaponManager = playerCharacter.WeaponManagerComponent
        if not slua.isValid(weaponManager) then return end
        
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not slua.isValid(currentWeapon) then return end
        
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not slua.isValid(shootComp) then return end
        
        if _G.ESPConfig.HitEffect > 0 then
            shootComp.ExtraHitPerformScale = _G.ESPConfig.HitEffect
        else
            shootComp.ExtraHitPerformScale = 1.0
        end
    end)
end

-- Check if character is alive
-- Free publisher @zmkzkz4
local function IsCharacterAlive(character)
    if not slua.isValid(character) then return false end
    
    if character.HealthStatus then
        local SecurityCommonUtils = _G.SecurityCommonUtils
        if SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then
            return SecurityCommonUtils:IsHealthStatusAlive(character.HealthStatus)
        end
    end
    
    if character.IsAlive then
        return character:IsAlive()
    end
    
    if character.GetHealth then
        local health = character:GetHealth() or 0
        return health > 0
    end
    
    return true
end

-- Check if player name is valid (not empty or Unknown)
-- Free publisher @zmkzkz4
local function IsPlayerNameValid(character)
    local name = character.PlayerName or ""
    return not (name == "" or name == "Unknown")
end

-- Get position offset based on character pose state (standing/crouching/prone)
-- Free publisher @zmkzkz4
local function GetPoseStateOffset(character)
    local poseState = character.PoseState or 0
    if poseState == 1 then
        return -30, 50
    elseif poseState == 2 then
        return -60, 20
    else
        return 0, 80
    end
end

-- Get Z offset for ESP text based on distance
-- Free publisher @zmkzkz4
local function GetZOffset(distMeters)
    local step = math.floor(distMeters / 25) * 25
    local t = math.max(0, math.min(1, step / 350))
    return 125 + 450 * t
end

-- Get font size for ESP name based on distance
-- Free publisher @zmkzkz4
local function GetNameFontSize(distMeters, maxDist, minSize, maxSize)
    if distMeters >= maxDist then return minSize end
    local t = (distMeters / maxDist)
    t = t * t
    return maxSize - (maxSize - minSize) * t
end

-- Get weapon name from character's weapon manager
-- Free publisher @zmkzkz4
local function GetWeaponName(character)
    if not _G.ESPConfig.ShowWeapon then return nil end
    
    local weaponManager = character.GetWeaponManager and character:GetWeaponManager()
    if not slua.isValid(weaponManager) then return nil end
    
    local currentSlot = weaponManager.GetCurrentUsingPropSlot and weaponManager:GetCurrentUsingPropSlot()
    local currentWeapon = currentSlot and weaponManager.GetInventoryWeaponByPropSlot and weaponManager:GetInventoryWeaponByPropSlot(currentSlot)
    
    if not slua.isValid(currentWeapon) then return nil end
    
    local weaponName = currentWeapon.WeaponName or ""
    if weaponName ~= "" then
        return weaponName:match("^([A-Za-z0-9_%-]+)") or weaponName
    end
    
    return nil
end

-- Main ESP tick function - renders boxes, names, distances, and health
-- Free publisher @zmkzkz4
function ESPTick()
    if not _G.ESPConfig.Enabled then return end
    
    pcall(function()
        local playerController = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(playerController) then return end
        
        local playerCharacter = playerController:GetPlayerCharacterSafety()
        if not slua.isValid(playerCharacter) then return end
        
        local hud = playerController:GetHUD()
        if not slua.isValid(hud) then return end
        
        local myTeam = playerCharacter.TeamID or 0
        local myPos = playerCharacter:K2_GetActorLocation()
        local myEyePos = playerCharacter.GetHeadLocation and playerCharacter:GetHeadLocation(false) or myPos
        
        local allCharacters = Game:GetAllPlayerPawns()
        if not allCharacters then return end
        
        local playerCount = 0
        local botCount = 0
        
        for _, character in pairs(allCharacters) do
            if slua.isValid(character) and character ~= playerCharacter then
                if IsCharacterAlive(character) then
                    local targetTeam = character.TeamID or 0
                    
                    if myTeam ~= targetTeam then
                        local isAI = character.TeamID and character.TeamID > 100
                        
                        if not _G.ESPConfig.ShowAI and isAI then
                            goto continue
                        end
                        
                        if isAI then
                            botCount = botCount + 1
                        else
                            playerCount = playerCount + 1
                        end
                        
                        local enemyPos = character:K2_GetActorLocation()
                        local dx = enemyPos.X - myPos.X
                        local dy = enemyPos.Y - myPos.Y
                        local dz = enemyPos.Z - myPos.Z
                        local distM = math.sqrt(dx*dx + dy*dy + dz*dz) / 100
                        
                        if distM <= _G.ESPConfig.DrawDistance then
                            local bodyPos = character:K2_GetActorLocation()
                            local bodyZ, headZ = GetPoseStateOffset(character)
                            
                            local checkPositions = {
                                character.GetHeadLocation and character:GetHeadLocation(false) or bodyPos,
                                FVector(bodyPos.X, bodyPos.Y, bodyPos.Z + 60 + bodyZ),
                                FVector(bodyPos.X, bodyPos.Y, bodyPos.Z + 30 + bodyZ),
                                FVector(bodyPos.X + 30, bodyPos.Y, bodyPos.Z + bodyZ),
                                FVector(bodyPos.X - 30, bodyPos.Y, bodyPos.Z + bodyZ),
                                FVector(bodyPos.X, bodyPos.Y + 30, bodyPos.Z + bodyZ),
                                FVector(bodyPos.X, bodyPos.Y - 30, bodyPos.Z + bodyZ),
                                FVector(bodyPos.X, bodyPos.Y, bodyPos.Z - 30 + bodyZ),
                            }
                            
                            local visible = false
                            for _, pos in ipairs(checkPositions) do
                                if Game.IsTargetPosVisible and Game:IsTargetPosVisible(myEyePos, pos, {playerCharacter}) then
                                    visible = true
                                    break
                                end
                            end
                            
                            local boxColor = visible and {R=0,G=255,B=0,A=255} or {R=255,G=0,B=0,A=255}
                            local boxFontSize = GetNameFontSize(distM, _G.ESPConfig.DrawDistance, 0.5, 1.0)
                            
                            local baseZOffset = GetZOffset(distM)
                            
                            if _G.ESPConfig.ShowName and IsPlayerNameValid(character) then
                                local name = character.PlayerName
                                local fontSize = GetNameFontSize(distM, _G.ESPConfig.DrawDistance, _G.ESPConfig.MinNameFont, _G.ESPConfig.MaxNameFont)
                                local teamId = character.TeamID or 0
                                local hp = character.Health or 0
                                local maxHp = character.HealthMax or 100
                                local hpPercent = maxHp > 0 and hp / maxHp or 0
                                
                                local hpColor = {R=255,G=255,B=255,A=255}
                                if hpPercent < 0.001 then
                                    hpColor = {R=0,G=0,B=0,A=255}
                                elseif hpPercent < 0.4 then
                                    hpColor = {R=255,G=0,B=0,A=255}
                                elseif hpPercent < 0.7 then
                                    hpColor = {R=255,G=255,B=0,A=255}
                                end
                                
                                local displayText = ""
                                if _G.ESPConfig.ShowTeamId then
                                    displayText = string.format("[%d] ", teamId)
                                end
                                displayText = displayText .. string.format("%s %.0fm", name, distM)
                                
                                hud:AddDebugText(displayText, character, 0.3, {X=0, Y=0, Z=baseZOffset}, {X=0, Y=0, Z=baseZOffset}, hpColor, true, false, true, nil, fontSize, true)
                            end
                            
                            if _G.ESPConfig.ShowWeapon then
                                local weaponName = GetWeaponName(character)
                                if weaponName then
                                    hud:AddDebugText(weaponName, character, 0.3, {X=0, Y=0, Z=baseZOffset-25}, {X=0, Y=0, Z=baseZOffset-25}, {R=255,G=200,B=0,A=255}, true, false, true, nil, 0.5, true)
                                end
                            end
                            
                            if _G.ESPConfig.ShowAI and isAI then
                                hud:AddDebugText("AI", character, 0.3, {X=0, Y=0, Z=baseZOffset-50}, {X=0, Y=0, Z=baseZOffset-50}, {R=255,G=255,B=0,A=255}, true, false, true, nil, 0.6, true)
                            end
                            
                            if _G.ESPConfig.ShowDistance then
                                hud:AddDebugText(string.format("%.0fm", distM), character, 0.3, {X=0, Y=0, Z=headZ-20}, {X=0, Y=0, Z=headZ-20}, {R=255,G=255,B=255,A=255}, true, false, true, nil, 0.5, true)
                            end
                        end
                    end
                end
            end
            ::continue::
        end
        
        hud:AddDebugText(string.format("Player:%d Bot:%d", playerCount, botCount), playerCharacter, 1, {X=0, Y=0, Z=36}, {X=0, Y=0, Z=36}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.08, true)
        hud:AddDebugText("@zmkzkz4", playerCharacter, 1, {X=0, Y=0, Z=28}, {X=0, Y=0, Z=28}, {R=0,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
    end)
end

-- Wallhack implementation - make enemies visible through walls
-- Free publisher @zmkzkz4
function ApplyWallhack()
    if not _G.ESPConfig.Wallhack then return end
    
    pcall(function()
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) then return end
        
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        
        local myTeam = localPlayer.TeamID or 0
        local allCharacters = Game:GetAllPlayerPawns()
        if not allCharacters then return end
        
        for _, enemy in pairs(allCharacters) do
            if slua.isValid(enemy) and enemy ~= localPlayer then
                local targetTeam = enemy.TeamID or 0
                if targetTeam ~= myTeam then
                    local isAI = enemy.TeamID and enemy.TeamID > 100
                    
                    if not _G.ESPConfig.ShowAI and isAI then
                        goto continue
                    end
                    
                    local isAlive = false
                    pcall(function() isAlive = enemy:IsAlive() end)
                    if not isAlive then goto continue end
                    
                    -- Get all mesh components
                    local meshes = {}
                    pcall(function()
                        if slua.isValid(enemy.Mesh) then
                            table.insert(meshes, enemy.Mesh)
                        end
                        local SkelClass = import("SkeletalMeshComponent")
                        if SkelClass then
                            local childs = enemy:GetComponentsByClass(SkelClass)
                            if childs then
                                local count = childs:Num()
                                for i = 0, count - 1 do
                                    local comp = childs:Get(i)
                                    if slua.isValid(comp) and comp ~= enemy.Mesh then
                                        table.insert(meshes, comp)
                                    end
                                end
                            end
                        end
                    end)
                    
                    -- Set material properties
                    pcall(function()
                        for _, comp in ipairs(meshes) do
                            if slua.isValid(comp) then
                                local ok, matInterface = pcall(function() return comp:GetMaterial(0) end)
                                if matInterface and slua.isValid(matInterface) then
                                    local ok2, baseMat = pcall(function() return matInterface:GetBaseMaterial() end)
                                    if baseMat and slua.isValid(baseMat) then
                                        baseMat.bDisableDepthTest = true
                                        baseMat.BlendMode = 2
                                    end
                                end
                                comp.UseScopeDistanceCulling = false
                                comp.PrimitiveShadingStrategy = 1
                                comp.ShadingRate = 6
                            end
                        end

                        -- Check visibility
                        local isVisible = false
                        if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                            pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
                        end
                        
                        -- Set colors
                        local visibleColorIndex = _G.ESPConfig.WallhackVisibleColor or 1
                        local brightness = _G.ESPConfig.WallhackBrightness or 25
                        
                        local colorMap = {
                            [1] = {R=brightness, G=0, B=0, A=1},     -- Red
                            [2] = {R=brightness, G=brightness, B=brightness, A=1}, -- White
                            [3] = {R=brightness, G=brightness, B=0, A=1},   -- Yellow
                            [4] = {R=0, G=brightness, B=0, A=1},   -- Green
                            [5] = {R=0, G=brightness, B=brightness, A=1},   -- Cyan
                            [6] = {R=0, G=0, B=brightness, A=1},   -- Blue
                            [7] = {R=brightness, G=0, B=brightness, A=1}    -- Purple
                        }
                        
                        local finalColor = isVisible and colorMap[visibleColorIndex] or {R=0, G=brightness, B=0, A=1}
                        local scale = {R=3, G=3, B=0, A=0}
                        
                        enemy.WH_MIDs = enemy.WH_MIDs or {}
                        local stateChanged = (enemy.WH_LastColorR ~= finalColor.R)
                        
                        for _, comp in ipairs(meshes) do
                            if slua.isValid(comp) then
                                local compKey = tostring(comp)
                                enemy.WH_MIDs[compKey] = enemy.WH_MIDs[compKey] or {}
                                for i = 0, 10 do
                                    local ok, matInterface = pcall(function() return comp:GetMaterial(i) end)
                                    if not matInterface or not slua.isValid(matInterface) then break end
                                    
                                    local currentCached = enemy.WH_MIDs[compKey][i]
                                    if not slua.isValid(currentCached) then
                                        local ok2, newMid = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                                        if newMid and slua.isValid(newMid) then
                                            enemy.WH_MIDs[compKey][i] = newMid
                                            currentCached = newMid
                                        end
                                    end
                                    
                                    if slua.isValid(currentCached) and (stateChanged or not enemy._midColorSet) then
                                        pcall(function()
                                            currentCached:SetVectorParameterValue("颜色", finalColor)
                                            currentCached:SetVectorParameterValue("Extra Light Color", finalColor)
                                            currentCached:SetVectorParameterValue("Para_Color", finalColor)
                                            currentCached:SetVectorParameterValue("Para_ColorTint", finalColor)
                                            currentCached:SetVectorParameterValue("Para_Color_1", finalColor)
                                            currentCached:SetVectorParameterValue("Tint", finalColor)
                                            currentCached:SetVectorParameterValue("Color", finalColor)
                                            currentCached:SetVectorParameterValue("BaseColor", finalColor)
                                            currentCached:SetVectorParameterValue("BodyColor", finalColor)
                                            currentCached:SetVectorParameterValue("MainColor", finalColor)
                                            currentCached:SetVectorParameterValue("DiffuseColor", finalColor)
                                            currentCached:SetVectorParameterValue("EmissiveColor", finalColor)
                                            currentCached:SetVectorParameterValue("ParaScaleOffset", scale)
                                        end)
                                        enemy._midColorSet = true
                                    end
                                end
                            end
                        end
                        if stateChanged then
                            enemy.WH_LastColorR = finalColor.R
                        end
                    end)
                end
            end
            ::continue::
        end
    end)
end

-- Setup periodic update timers for all features
-- Free publisher @zmkzkz4
local function SetupUpdateTimer()
    InitializeModules()
    
    local playerController = slua_GameFrontendHUD:GetPlayerController()
    if not playerController then return end
    
    -- ESP Timer - 298ms interval
    playerController:AddGameTimer(0.298, true, ESPTick)
    
    -- Environment Timer - 0.5s interval
    playerController:AddGameTimer(0.5, true, function()
        if _G.ESPConfig.RainEnabled then
            SetRainEnabled(true)
        end
        if _G.ESPConfig.SnowEnabled then
            SetSnowEnabled(true)
        end
        if _G.ESPConfig.BlackSky then
            SetBlackSky(true)
        end
        if _G.ESPConfig.RemoveFog then
            SetFogRemoval(true)
        end
        if _G.ESPConfig.RemoveGrass then
            SetGrassRemoval(true)
        end
        if _G.ESPConfig.RemoveTree then
            SetTreeRemoval(true)
        end
        if _G.ESPConfig.RemoveWater then
            SetWaterRemoval(true)
        end
    end)
    
    -- Movement Timer - 0.1s interval
    playerController:AddGameTimer(0.1, true, function()
        if _G.ESPConfig.AntiGravity then
            SetAntiGravity(true)
        end
        SetGravityScale()
        SetJumpHeight()
        if _G.ESPConfig.SpeedBoost then
            SetSpeedBoost(true)
        end
        SetSpeedPercent()
        if _G.ESPConfig.CharacterRotation then
            SetCharacterRotation(true)
        end
        SetCharacterRotationSpeed()
        SetWallClimb(_G.ESPConfig.WallClimb)
        SetCharScale()
        SetEnemyScale()
    end)
    
    -- Visual Timer - 0.1s interval
    playerController:AddGameTimer(0.1, true, function()
        if _G.ESPConfig.FPS165 then
            SetFPS165(true)
        else
            SetFPS165(false)
        end
        if _G.ESPConfig.IpadView then
            SetIpadView(true)
        else
            SetIpadView(false)
        end
        SetIpadFov()
        ApplyWallhack()
    end)
    
    -- Combat Timer - 0.05s interval
    playerController:AddGameTimer(0.05, true, function()
        if _G.ESPConfig.NoRecoil then
            ApplyNoRecoil(true)
        else
            ApplyNoRecoil(false)
        end
        if _G.ESPConfig.QuickScope then
            ApplyQuickScope(true)
        else
            ApplyQuickScope(false)
        end
        if _G.ESPConfig.FastSwitch then
            ApplyFastSwitch(true)
        else
            ApplyFastSwitch(false)
        end
        if _G.ESPConfig.GunWallbang then
            ApplyGunWallbang(true)
        else
            ApplyGunWallbang(false)
        end
        ApplySuperBullet()
        if _G.ESPConfig.SuperFireRate then
            ApplySuperFireRate(true)
        else
            ApplySuperFireRate(false)
        end
        if _G.ESPConfig.InfiniteAmmo then
            ApplyInfiniteAmmo(true)
        else
            ApplyInfiniteAmmo(false)
        end
        if _G.ESPConfig.AutoAim then
            ApplyAutoAim(true)
        else
            ApplyAutoAim(false)
        end
        ApplyHitEffect()
    end)
    
    -- Weapon Effects Timer - 0.016s interval
    playerController:AddGameTimer(0.016, true, function()
        if _G.ESPConfig.WeaponLuffy or _G.ESPConfig.WeaponSoul or _G.ESPConfig.WeaponRainbow then
            if not _G.WeaponOrbitState.active then
                StartWeaponEffects()
            end
        elseif _G.WeaponOrbitState.active then
            StopWeaponEffects()
        end
        
        SetWeaponScale()
    end)
end

-- Initialize ESP Menu UI
-- Free publisher @zmkzkz4
function _G.InitESPMenu()
    if _G.ESPMenuInitialized then
        return
    end
    _G.ESPMenuInitialized = true
    
    -- Hook LocUtil
    local LocUtil = _G.LocUtil
    if not LocUtil then
        LocUtil = require("client.common.LocUtil")
    end
    
    if LocUtil then
        if not LocUtil._IsESPMenuHooked then
            local originalGetLocalizeResStr = LocUtil.GetLocalizeResStr
            
            LocUtil.GetLocalizeResStr = function(key)
                local keyType = type(key)
                if keyType == "string" then
                    local num = tonumber(key)
                    if not num then
                        return key
                    end
                end
                if originalGetLocalizeResStr then
                    return originalGetLocalizeResStr(key)
                end
                return key
            end
            
            LocUtil._IsESPMenuHooked = true
        end
    end
    
    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    
    if SettingPageDefine.ESPMenu then
        return
    end
    
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    
    -- Create ESP Menu
    local ESPMenu = {
        Key = "ESPMenu",
        loc = "MOD @zmkzkz4",
        UIKey = "Setting_Page_Privacy",
        Category = {}
    }
    
    -- ========== Cat_ESP ==========
    local Cat_ESP = {
        Key = "Cat_ESP",
        loc = "ESP | 透视设置",
        Stack = {
            {
                Key = "ESP_Enabled",
                UI = AliasMap.TitleSwitcher,
                Text = "Master | ESP总开关",
                GetFunc = function() return _G.ESPConfig.Enabled end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.Enabled = value
                    return true
                end
            },
            {
                Key = "ESP_ShowAI",
                UI = AliasMap.TitleSwitcher,
                Text = "Show AI | 显示AI",
                GetFunc = function() return _G.ESPConfig.ShowAI end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ShowAI = value
                    return true
                end
            },
            {
                Key = "ESP_ShowName",
                UI = AliasMap.TitleSwitcher,
                Text = "Show Name | 显示名字",
                GetFunc = function() return _G.ESPConfig.ShowName end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ShowName = value
                    return true
                end
            },
            {
                Key = "ESP_ShowWeapon",
                UI = AliasMap.TitleSwitcher,
                Text = "Show Weapon | 显示武器",
                GetFunc = function() return _G.ESPConfig.ShowWeapon end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ShowWeapon = value
                    return true
                end
            },
            {
                Key = "ESP_ShowTeamId",
                UI = AliasMap.TitleSwitcher,
                Text = "Show TeamID | 显示队伍ID",
                GetFunc = function() return _G.ESPConfig.ShowTeamId end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ShowTeamId = value
                    return true
                end
            },
            {
                Key = "ESP_ShowDistance",
                UI = AliasMap.TitleSwitcher,
                Text = "Show Distance | 显示距离",
                GetFunc = function() return _G.ESPConfig.ShowDistance end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ShowDistance = value
                    return true
                end
            },
            {
                Key = "ESP_DrawDistance",
                UI = AliasMap.Slider,
                Text = "Draw Distance | 绘制距离(米)",
                Min = 100,
                Max = 500,
                Step = 10,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.DrawDistance end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.DrawDistance = value
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_ESP)
    
    -- ========== Cat_Scene ==========
    local Cat_Scene = {
        Key = "Cat_Scene",
        loc = "Scene | 场景设置",
        Stack = {
            {
                Key = "ESP_RainEnabled",
                UI = AliasMap.TitleSwitcher,
                Text = "Rain | 雨天",
                GetFunc = function() return _G.ESPConfig.RainEnabled end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.RainEnabled = value
                    SetRainEnabled(value)
                    return true
                end
            },
            {
                Key = "ESP_SnowEnabled",
                UI = AliasMap.TitleSwitcher,
                Text = "Snow | 雪天",
                GetFunc = function() return _G.ESPConfig.SnowEnabled end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.SnowEnabled = value
                    SetSnowEnabled(value)
                    return true
                end
            },
            {
                Key = "ESP_BlackSky",
                UI = AliasMap.TitleSwitcher,
                Text = "BlackSky | 黑夜天空",
                GetFunc = function() return _G.ESPConfig.BlackSky end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.BlackSky = value
                    SetBlackSky(value)
                    return true
                end
            },
            {
                Key = "ESP_RemoveFog",
                UI = AliasMap.TitleSwitcher,
                Text = "No Fog | 去除雾气",
                GetFunc = function() return _G.ESPConfig.RemoveFog end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.RemoveFog = value
                    SetFogRemoval(value)
                    return true
                end
            },
            {
                Key = "ESP_RemoveGrass",
                UI = AliasMap.TitleSwitcher,
                Text = "No Grass | 去除草地",
                GetFunc = function() return _G.ESPConfig.RemoveGrass end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.RemoveGrass = value
                    SetGrassRemoval(value)
                    return true
                end
            },
            {
                Key = "ESP_RemoveTree",
                UI = AliasMap.TitleSwitcher,
                Text = "No Tree | 去除树木",
                GetFunc = function() return _G.ESPConfig.RemoveTree end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.RemoveTree = value
                    SetTreeRemoval(value)
                    return true
                end
            },
            {
                Key = "ESP_RemoveWater",
                UI = AliasMap.TitleSwitcher,
                Text = "No Water | 去除水面",
                GetFunc = function() return _G.ESPConfig.RemoveWater end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.RemoveWater = value
                    SetWaterRemoval(value)
                    return true
                end
            },
            {
                Key = "ESP_ForceChinese",
                UI = AliasMap.TitleSwitcher,
                Text = "CN | 强制中文",
                GetFunc = function() return _G.ESPConfig.ForceChinese end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.ForceChinese = value
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_Scene)
    
    -- ========== Cat_Character (移动设置) ==========
    local Cat_Character = {
        Key = "Cat_Character",
        loc = "Character | 移动设置",
        Stack = {
            {
                Key = "ESP_AntiGravity",
                UI = AliasMap.TitleSwitcher,
                Text = "AntiGravity | 反重力",
                GetFunc = function() return _G.ESPConfig.AntiGravity end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.AntiGravity = value
                    SetAntiGravity(value)
                    return true
                end
            },
            {
                Key = "ESP_GravityScale",
                UI = AliasMap.Slider,
                Text = "Gravity | 重力强度",
                Min = 0,
                Max = 100,
                Step = 1,
                IsPercent = true,
                GetFunc = function()
                    return NormalizeGravity(_G.ESPConfig.GravityScale)
                end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.GravityScale = DenormalizeGravity(value)
                    SetGravityScale()
                    return true
                end
            },
            {
                Key = "ESP_JumpHeight",
                UI = AliasMap.Slider,
                Text = "Jump Height | 跳跃高度",
                Min = 500,
                Max = 2000,
                Step = 50,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.JumpHeight end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.JumpHeight = value
                    SetJumpHeight()
                    return true
                end
            },
            {
                Key = "ESP_SpeedBoost",
                UI = AliasMap.TitleSwitcher,
                Text = "Speed | 加速",
                GetFunc = function() return _G.ESPConfig.SpeedBoost end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.SpeedBoost = value
                    SetSpeedBoost(value)
                    return true
                end
            },
            {
                Key = "ESP_SpeedPercent",
                UI = AliasMap.Slider,
                Text = "Speed % | 速度百分比",
                Min = 100,
                Max = 500,
                Step = 10,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.SpeedPercent end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.SpeedPercent = value
                    SetSpeedPercent()
                    return true
                end
            },
            {
                Key = "ESP_CharacterRotation",
                UI = AliasMap.TitleSwitcher,
                Text = "Rotate | 角色旋转",
                GetFunc = function() return _G.ESPConfig.CharacterRotation end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.CharacterRotation = value
                    SetCharacterRotation(value)
                    return true
                end
            },
            {
                Key = "ESP_CharacterRotationSpeed",
                UI = AliasMap.Slider,
                Text = "Rotate Speed | 旋转速度",
                Min = 180,
                Max = 1080,
                Step = 30,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.CharacterRotationSpeed end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.CharacterRotationSpeed = value
                    SetCharacterRotationSpeed()
                    return true
                end
            },
            {
                Key = "ESP_WallClimb",
                UI = AliasMap.TitleSwitcher,
                Text = "WallClimb | 攀墙",
                GetFunc = function() return _G.ESPConfig.WallClimb end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WallClimb = value
                    SetWallClimb(value)
                    return true
                end
            },
            {
                Key = "ESP_CharScale",
                UI = AliasMap.Slider,
                Text = "My Size | 自己大小",
                Min = 0,
                Max = 100,
                Step = 1,
                IsPercent = true,
                GetFunc = function()
                    return NormalizeScale(_G.ESPConfig.CharScale)
                end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.CharScale = DenormalizeScale(value)
                    SetCharScale()
                    return true
                end
            },
            {
                Key = "ESP_EnemyScale",
                UI = AliasMap.Slider,
                Text = "Enemy Size | 敌人大小",
                Min = 0,
                Max = 100,
                Step = 1,
                IsPercent = true,
                GetFunc = function()
                    return NormalizeScale(_G.ESPConfig.EnemyScale)
                end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.EnemyScale = DenormalizeScale(value)
                    SetEnemyScale()
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_Character)
    
    -- ========== Cat_Weapon (枪械修改) ==========
    local Cat_Weapon = {
        Key = "Cat_Weapon",
        loc = "Weapon | 枪械修改",
        Stack = {
            {
                Key = "ESP_WeaponLuffy",
                UI = AliasMap.TitleSwitcher,
                Text = "Luffy | 枪械放大",
                GetFunc = function() return _G.ESPConfig.WeaponLuffy end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WeaponLuffy = value
                    return true
                end
            },
            {
                Key = "ESP_WeaponSoul",
                UI = AliasMap.TitleSwitcher,
                Text = "Soul | 枪魂",
                GetFunc = function() return _G.ESPConfig.WeaponSoul end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WeaponSoul = value
                    return true
                end
            },
            {
                Key = "ESP_WeaponRainbow",
                UI = AliasMap.TitleSwitcher,
                Text = "Rainbow | 枪械彩虹",
                GetFunc = function() return _G.ESPConfig.WeaponRainbow end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WeaponRainbow = value
                    return true
                end
            },
            {
                Key = "ESP_WeaponScale",
                UI = AliasMap.Slider,
                Text = "Gun Size | 枪械大小",
                Min = 0,
                Max = 100,
                Step = 1,
                IsPercent = true,
                GetFunc = function()
                    return NormalizeScale(_G.ESPConfig.WeaponScale)
                end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WeaponScale = DenormalizeScale(value)
                    SetWeaponScale()
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_Weapon)
    
    -- ========== Cat_Combat (战斗修改) ==========
    local Cat_Combat = {
        Key = "Cat_Combat",
        loc = "Combat | 战斗修改",
        Stack = {
            {
                Key = "ESP_OneClickEnable",
                UI = AliasMap.TitleButton,
                Text = "One Click | 一键开启",
                GetFunc = function() return "ON" end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.NoRecoil = true
                    _G.ESPConfig.NoRecoilADS = true
                    _G.ESPConfig.AntiShake = true
                    _G.ESPConfig.CrossDeviation = true
                    _G.ESPConfig.QuickScope = true
                    _G.ESPConfig.FastSwitch = true
                    _G.ESPConfig.GunWallbang = true
                    _G.ESPConfig.SuperBullet = 20
                    _G.ESPConfig.SuperFireRate = true
                    _G.ESPConfig.InfiniteAmmo = true
                    _G.ESPConfig.AutoAim = true
                    _G.ESPConfig.HitEffect = 10
                    return true
                end
            },
            {
                Key = "ESP_OneClickDisable",
                UI = AliasMap.TitleButton,
                Text = "One Off | 一键关闭",
                GetFunc = function() return "OFF" end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.NoRecoil = false
                    _G.ESPConfig.NoRecoilADS = false
                    _G.ESPConfig.AntiShake = false
                    _G.ESPConfig.CrossDeviation = false
                    _G.ESPConfig.QuickScope = false
                    _G.ESPConfig.FastSwitch = false
                    _G.ESPConfig.GunWallbang = false
                    _G.ESPConfig.SuperBullet = 1
                    _G.ESPConfig.SuperFireRate = false
                    _G.ESPConfig.InfiniteAmmo = false
                    _G.ESPConfig.AutoAim = false
                    _G.ESPConfig.HitEffect = 3.5
                    return true
                end
            },
            {
                UI = AliasMap.Spacer,
                Key = "ESP_Spacer1"
            },
            {
                Key = "ESP_FPS165",
                UI = AliasMap.TitleSwitcher,
                Text = "165FPS | 165帧",
                GetFunc = function() return _G.ESPConfig.FPS165 end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.FPS165 = value
                    SetFPS165(value)
                    return true
                end
            },
            {
                Key = "ESP_IpadView",
                UI = AliasMap.TitleSwitcher,
                Text = "iPad View | iPad视角",
                GetFunc = function() return _G.ESPConfig.IpadView end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.IpadView = value
                    SetIpadView(value)
                    return true
                end
            },
            {
                Key = "ESP_IpadFov",
                UI = AliasMap.Slider,
                Text = "FOV | iPad视角范围",
                Min = 80,
                Max = 150,
                Step = 1,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.IpadFov end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.IpadFov = value
                    SetIpadFov()
                    return true
                end
            },
            {
                Key = "ESP_NoRecoil",
                UI = AliasMap.TitleSwitcher,
                Text = "No Recoil | 无后坐",
                GetFunc = function() return _G.ESPConfig.NoRecoil end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.NoRecoil = value
                    ApplyNoRecoil(value)
                    return true
                end
            },
            {
                Key = "ESP_NoRecoilADS",
                UI = AliasMap.TitleSwitcher,
                Text = "No Recoil ADS | 无后坐(开镜)",
                GetFunc = function() return _G.ESPConfig.NoRecoilADS end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.NoRecoilADS = value
                    ApplyNoRecoil(_G.ESPConfig.NoRecoil)
                    return true
                end
            },
            {
                Key = "ESP_AntiShake",
                UI = AliasMap.TitleSwitcher,
                Text = "Anti Shake | 抗抖动",
                GetFunc = function() return _G.ESPConfig.AntiShake end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.AntiShake = value
                    ApplyNoRecoil(_G.ESPConfig.NoRecoil)
                    return true
                end
            },
            {
                Key = "ESP_CrossDeviation",
                UI = AliasMap.TitleSwitcher,
                Text = "Focus | 十字准星",
                GetFunc = function() return _G.ESPConfig.CrossDeviation end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.CrossDeviation = value
                    ApplyNoRecoil(_G.ESPConfig.NoRecoil)
                    return true
                end
            },
            {
                Key = "ESP_QuickScope",
                UI = AliasMap.TitleSwitcher,
                Text = "Quick Scope | 快速瞄准",
                GetFunc = function() return _G.ESPConfig.QuickScope end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.QuickScope = value
                    ApplyQuickScope(value)
                    return true
                end
            },
            {
                Key = "ESP_FastSwitch",
                UI = AliasMap.TitleSwitcher,
                Text = "Fast Swap | 快速换枪",
                GetFunc = function() return _G.ESPConfig.FastSwitch end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.FastSwitch = value
                    ApplyFastSwitch(value)
                    return true
                end
            },
            {
                Key = "ESP_GunWallbang",
                UI = AliasMap.TitleSwitcher,
                Text = "Wallbang | 枪械穿墙",
                GetFunc = function() return _G.ESPConfig.GunWallbang end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.GunWallbang = value
                    ApplyGunWallbang(value)
                    return true
                end
            },
            {
                Key = "ESP_SuperBullet",
                UI = AliasMap.Slider,
                Text = "Super Bullet | 超级子弹(穿墙威力)",
                Min = 1,
                Max = 20,
                Step = 1,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.SuperBullet end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.SuperBullet = value
                    ApplySuperBullet()
                    return true
                end
            },
            {
                Key = "ESP_SuperFireRate",
                UI = AliasMap.TitleSwitcher,
                Text = "Super Fire | 超级射速",
                GetFunc = function() return _G.ESPConfig.SuperFireRate end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.SuperFireRate = value
                    ApplySuperFireRate(value)
                    return true
                end
            },
            {
                Key = "ESP_InfiniteAmmo",
                UI = AliasMap.TitleSwitcher,
                Text = "Inf Ammo | 无限弹药",
                GetFunc = function() return _G.ESPConfig.InfiniteAmmo end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.InfiniteAmmo = value
                    ApplyInfiniteAmmo(value)
                    return true
                end
            },
            {
                Key = "ESP_AutoAim",
                UI = AliasMap.TitleSwitcher,
                Text = "Auto Aim | 自动瞄准",
                GetFunc = function() return _G.ESPConfig.AutoAim end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.AutoAim = value
                    ApplyAutoAim(value)
                    return true
                end
            },
            {
                Key = "ESP_HitEffect",
                UI = AliasMap.Slider,
                Text = "Hit Effect | 击中特效强度",
                Min = 1,
                Max = 10,
                Step = 0.5,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.HitEffect end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.HitEffect = value
                    ApplyHitEffect()
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_Combat)
    
    -- ========== Cat_Wallhack (内透) ==========
    local Cat_Wallhack = {
        Key = "Cat_Wallhack",
        loc = "Wallhack | 内透",
        Stack = {
            {
                Key = "ESP_Wallhack",
                UI = AliasMap.TitleSwitcher,
                Text = "WH | 内透开关",
                GetFunc = function() return _G.ESPConfig.Wallhack end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.Wallhack = value
                    return true
                end
            },
            {
                Key = "ESP_WallhackVisibleColor",
                UI = AliasMap.Switcher,
                Text = "Vis Color | 可见颜色",
                SwitcherText = {"Red", "White", "Yellow", "Green", "Cyan", "Blue", "Purple"},
                SwitcherValue = {1, 2, 3, 4, 5, 6, 7},
                GetFunc = function() return _G.ESPConfig.WallhackVisibleColor end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WallhackVisibleColor = value
                    return true
                end
            },
            {
                Key = "ESP_WallhackInvisibleColor",
                UI = AliasMap.Switcher,
                Text = "Invis Color | 不可见颜色",
                SwitcherText = {"Red", "White", "Yellow", "Green", "Cyan", "Blue", "Purple"},
                SwitcherValue = {1, 2, 3, 4, 5, 6, 7},
                GetFunc = function() return _G.ESPConfig.WallhackInvisibleColor end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WallhackInvisibleColor = value
                    return true
                end
            },
            {
                Key = "ESP_WallhackBrightness",
                UI = AliasMap.Slider,
                Text = "Brightness | 亮度",
                Min = 1,
                Max = 50,
                Step = 1,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackBrightness end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WallhackBrightness = value
                    return true
                end
            },
            {
                Key = "ESP_WallhackGlow",
                UI = AliasMap.Slider,
                Text = "Glow | 发光强度",
                Min = 0,
                Max = 10,
                Step = 0.5,
                IsPercent = false,
                GetFunc = function() return _G.ESPConfig.WallhackGlow end,
                SetFunc = function(ctrl, value)
                    _G.ESPConfig.WallhackGlow = value
                    return true
                end
            }
        }
    }
    table.insert(ESPMenu.Category, Cat_Wallhack)
    
    -- Register menu
    SettingPageDefine.ESPMenu = ESPMenu
    table.insert(SettingCatalog, SettingPageDefine.ESPMenu)
    
    -- Hook UIManager
    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsESPMenuHooked then
        local originalShowUI = UIManager.ShowUI
        
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local argCount = select("#", ...)
            
            if config and config.keyName then
                local lowerKeyName = string.lower(config.keyName)
                if string.find(lowerKeyName, "setting") then
                    local catalog = args[1]
                    if type(catalog) == "table" then
                        local hasESPMenu = false
                        for _, page in ipairs(catalog) do
                            if type(page) == "table" and page.Key == "ESPMenu" then
                                hasESPMenu = true
                                break
                            end
                        end
                        if not hasESPMenu then
                            table.insert(catalog, SettingPageDefine.ESPMenu)
                        end
                    end
                end
            end
            
            return originalShowUI(config, table.unpack(args, 1, argCount))
        end
        
        UIManager._IsESPMenuHooked = true
    end
end

-- Initialize on load
pcall(function() _G.InitESPMenu() end)

-- Bypass MD5 packet key check
-- Free publisher @zmkzkz4
_G.TryBypassMD5 = function()
    if _G.MD5Bypassed then return end
    pcall(function()
        require("client.client_entry")
        if _G.NetUtil then
            _G.NetUtil.check_dh_packet_key = function(packet_key, svr_packet_key_md5, from, dh_ext_info, bReportDSInfo)
                if type(dh_ext_info) == "table" then
                    dh_ext_info.packet_key_md5 = svr_packet_key_md5 or ""
                    dh_ext_info.svr_packet_key_md5 = svr_packet_key_md5 or ""
                end
                return true
            end
            _G.MD5Bypassed = true
        end
    end)
end

-- Bypass cache MD5 verification
-- Free publisher @zmkzkz4
_G.BypassCacheMD5 = function()
    if _G.CacheMD5Bypassed then return end
    pcall(function()
        local CacheMgr = require("common.CustomAsset.CustomAssetCacheManager")
        if CacheMgr then
            CacheMgr._UpdateAssetCacheState = function(self, AssetKey, SuffixType)
                local CacheMetaInfo = self:GetCustomAssetCacheMetaInfo(AssetKey, SuffixType)
                if CacheMetaInfo then
                    CacheMetaInfo.CacheVerifyStatus = CustomAssetDefine.CustomAssetCacheVerifyStatus.Valid
                end
            end
            _G.CacheMD5Bypassed = true
        end
    end)
end

-- Bypass security utilities checks
-- Free publisher @zmkzkz4
_G.BypassSecurityUtils = function()
    pcall(function()
        local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommonUtils then
            if SecurityCommonUtils.EStrategyTypeInReplay then
                for k, v in pairs(SecurityCommonUtils.EStrategyTypeInReplay) do
                    SecurityCommonUtils.EStrategyTypeInReplay[k] = 0
                end
            end
            SecurityCommonUtils.LogIf = function(Condition, sFormat, ...) return false end
            SecurityCommonUtils.IsFunctionCheckPass = function(FunctionOuter, sFuncName, ...) return true end
            SecurityCommonUtils.IsHealthStatusHealthy = function(nHealthStatus) return true end
            SecurityCommonUtils.IsHealthStatusAlive = function(nHealthStatus) return true end
            SecurityCommonUtils.IsTrue = function(Value) return true end
            _G.SecurityCommonUtils = SecurityCommonUtils
        end
    end)
end

-- Bypass Higgs boson component security checks
-- Free publisher @zmkzkz4
_G.BypassHiggsComponent = function()
    pcall(function()
        local HiggsComponentClass = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HiggsComponentClass then
            local CHiggsBosonComponent = HiggsComponentClass
            if type(HiggsComponentClass) == "table" and HiggsComponentClass.__index then
                CHiggsBosonComponent = HiggsComponentClass.__index
            end
            CHiggsBosonComponent.StaticShowSecurityAlertInDev = function(uPlayerController, sMessage, bIsClientShowWindow, bSkipServer) end
            CHiggsBosonComponent._ClientShowSecurityAlertWindow = function(sMessage) end
            CHiggsBosonComponent._ReportChatRobot = function(sMessage, uHiggsBosonComponent) end
            CHiggsBosonComponent._ProcessReportChatRobotQueue = function() end
            CHiggsBosonComponent.RecordStrategyTimestampInReplay = function(nStrategyTypeInReplay, nValue, uController, nTimeInSecondsOffSet) end
            CHiggsBosonComponent.SendAntiDataFlow = function(self) end
            CHiggsBosonComponent.SendHitFireBtnFlow = function(self) end
            CHiggsBosonComponent.OnBattleResult = function(self) end
            CHiggsBosonComponent.SendHisarData = function() end
            if CHiggsBosonComponent.ClientRPC then
                CHiggsBosonComponent.ClientRPC.RPC_Client_ShowSecurityAlertWindow = function(self, sMessage) end
                CHiggsBosonComponent.ClientRPC.RPC_Client_ServerNameAck = function(self) end
            end
            if CHiggsBosonComponent.ServerRPC then
                CHiggsBosonComponent.ServerRPC.RPC_Server_TellServerName = function(self, sServerName) end
            end
        end
    end)
end

-- Show legal credit popup
-- Free publisher @zmkzkz4
_G.TryShowLegalCredit = function()
    if _G.LegalShown then return end
    pcall(function()
        local Legal = require("client.slua.logic.common.logic_common_legal_msg")
        if Legal and Legal.ShowOnePopUI then
            Legal.ShowOnePopUI({
                tabType = 999,
                title = "CREDIT",
                content = "ESP MOD - Complete Deobfuscated Version\n\nAll features restored.\nEnjoy And Keep Safe!",
                tipsText = nil,
                btnOKText = "OK",
                btnCancleText = "CLOSE",
                acceptFunc = function() end,
                refuseFunc = function() end
            })
            _G.LegalShown = true
        end
    end)
end

-- Execute initialization functions
pcall(function() _G.TryShowLegalCredit() end)
pcall(function() _G.TryBypassMD5() end)
pcall(function() _G.BypassCacheMD5() end)
pcall(function() _G.BypassSecurityUtils() end)
pcall(function() _G.BypassHiggsComponent() end)
pcall(function() SetupUpdateTimer() end)

-- Module return
local M = {}
function M.OnCtor(self) end

function M.OnPost(self)
    self:OnAdvance()
    self:OnTick(DeltaTime or 0)
end

function M.OnTick(self, DeltaTime)
    if _G.ESPConfig.Enabled then
        ESPTick()
    end
    
    if _G.ESPConfig.RainEnabled then
        SetRainEnabled(true)
    end
    if _G.ESPConfig.SnowEnabled then
        SetSnowEnabled(true)
    end
    if _G.ESPConfig.BlackSky then
        SetBlackSky(true)
    end
    if _G.ESPConfig.RemoveFog then
        SetFogRemoval(true)
    end
    if _G.ESPConfig.RemoveGrass then
        SetGrassRemoval(true)
    end
    if _G.ESPConfig.RemoveTree then
        SetTreeRemoval(true)
    end
    if _G.ESPConfig.RemoveWater then
        SetWaterRemoval(true)
    end
    
    if _G.ESPConfig.AntiGravity then
        SetAntiGravity(true)
    end
    SetGravityScale()
    SetJumpHeight()
    if _G.ESPConfig.SpeedBoost then
        SetSpeedBoost(true)
    end
    SetSpeedPercent()
    if _G.ESPConfig.CharacterRotation then
        SetCharacterRotation(true)
    end
    SetCharacterRotationSpeed()
    SetWallClimb(_G.ESPConfig.WallClimb)
    SetCharScale()
    SetEnemyScale()
    
    if _G.ESPConfig.FPS165 then
        SetFPS165(true)
    else
        SetFPS165(false)
    end
    if _G.ESPConfig.IpadView then
        SetIpadView(true)
    else
        SetIpadView(false)
    end
    SetIpadFov()
    ApplyWallhack()
    
    if _G.ESPConfig.NoRecoil then
        ApplyNoRecoil(true)
    else
        ApplyNoRecoil(false)
    end
    if _G.ESPConfig.QuickScope then
        ApplyQuickScope(true)
    else
        ApplyQuickScope(false)
    end
    if _G.ESPConfig.FastSwitch then
        ApplyFastSwitch(true)
    else
        ApplyFastSwitch(false)
    end
    if _G.ESPConfig.GunWallbang then
        ApplyGunWallbang(true)
    else
        ApplyGunWallbang(false)
    end
    ApplySuperBullet()
    if _G.ESPConfig.SuperFireRate then
        ApplySuperFireRate(true)
    else
        ApplySuperFireRate(false)
    end
    if _G.ESPConfig.InfiniteAmmo then
        ApplyInfiniteAmmo(true)
    else
        ApplyInfiniteAmmo(false)
    end
    if _G.ESPConfig.AutoAim then
        ApplyAutoAim(true)
    else
        ApplyAutoAim(false)
    end
    ApplyHitEffect()
    
    if _G.ESPConfig.WeaponLuffy or _G.ESPConfig.WeaponSoul or _G.ESPConfig.WeaponRainbow then
        if not _G.WeaponOrbitState.active then
            StartWeaponEffects()
        end
    elseif _G.WeaponOrbitState.active then
        StopWeaponEffects()
    end
    SetWeaponScale()
end

function M.OnAdvance(self)
    pcall(function()
        SetupUpdateTimer()
    end)
end

function M.OnBeginPlay(self)
    pcall(function() _G.InitESPMenu() end)
    pcall(function() _G.TryShowLegalCredit() end)
    pcall(function() _G.TryBypassMD5() end)
    pcall(function() _G.BypassCacheMD5() end)
    pcall(function() _G.BypassSecurityUtils() end)
    pcall(function() _G.BypassHiggsComponent() end)
    pcall(function() SetupUpdateTimer() end)
end

return M