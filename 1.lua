-- ===================================================================
-- MERGED SCRIPT: 1.lua + add.lua + ULTIMATE BYPASS UPGRADE
-- 
-- All features fully integrated.
-- Body scale hack (PhysicsAssetOverride) removed.
-- 
-- UPGRADE v2:
--   - Expanded packet blacklist (all known reporting endpoints)
--   - Battle result spoofing (kills, damage, headshots, accuracy,
--     survival time, ranking)
--   - Kill limit bypass (removed caps)
--   - Continuous anti‑detection patrol (every 3s)
--   - Behaviour spoofing (ping, packet loss, input delay)
--   - Extra security overrides (TSS, memory, kernel)
--   - Fake network jitter
--   - Memory cleanup for detection flags
--   - TSS SDK completely neutered
--   - Root/jailbreak detection bypass
--   - Deep‑scan timer (kills new suspicious subsystems)
--   - Additional console commands to disable client‑side checks
-- ===================================================================

-- Per-match guard: allow re-init when the player controller changes (new match)
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

-- Initialize bypass state ASAP
if not _G.BYPASS_STATE then
    _G.BYPASS_STATE = {
        DEADEYE_DISABLED = false,
        HAWKEYE_DISABLED = false,
        VOKLAI_DISABLED = false,
        HIGGSBOSON_DISABLED = false,
        HASH_VERIFY_DISABLED = false,
        IP_MAPPING_DISABLED = false,
        MEMORY_PATCH_DISABLED = false,
        EDU_EYE_DISABLED = false,
        FULL_BYPASS_ACTIVE = false
    }
end

-- Initialize feature toggles with defaults
if not _G.Mod_Aimbot_Enabled then _G.Mod_Aimbot_Enabled = false end
if not _G.Mod_ESP_Enabled then _G.Mod_ESP_Enabled = false end
if not _G.Mod_Wallhack_Enabled then _G.Mod_Wallhack_Enabled = false end
if not _G.Mod_Skin_Enabled then _G.Mod_Skin_Enabled = false end
if _G.Mod_FPS165_Enabled == nil then _G.Mod_FPS165_Enabled = true end
if _G.Mod_NoGrass_Enabled == nil then _G.Mod_NoGrass_Enabled = true end
if _G.Mod_iPadView_Enabled == nil then _G.Mod_iPadView_Enabled = false end

-- Slider values for fine-tuning
if _G.Mod_AimbotStrength == nil then _G.Mod_AimbotStrength = 50 end
if _G.Mod_iPadViewDistance == nil then _G.Mod_iPadViewDistance = 90 end

-- CHAMS color system
if _G.Mod_Chams_GreenEnabled == nil then _G.Mod_Chams_GreenEnabled = false end
if _G.Mod_Chams_YellowEnabled == nil then _G.Mod_Chams_YellowEnabled = false end
if _G.Mod_Chams_GreenRGB == nil then _G.Mod_Chams_GreenRGB = {R=0, G=255, B=0, A=255} end
if _G.Mod_Chams_YellowRGB == nil then _G.Mod_Chams_YellowRGB = {R=255, G=255, B=0, A=255} end

-- ===================================================================
-- Scene & Wallhack Configuration (from add.lua)
-- ===================================================================
_G.ESPConfig = _G.ESPConfig or {}
-- Scene defaults
_G.ESPConfig.RainEnabled    = _G.ESPConfig.RainEnabled or false
_G.ESPConfig.SnowEnabled    = _G.ESPConfig.SnowEnabled or false
_G.ESPConfig.BlackSky       = _G.ESPConfig.BlackSky or false
_G.ESPConfig.RemoveFog      = _G.ESPConfig.RemoveFog or false
_G.ESPConfig.RemoveGrass    = _G.ESPConfig.RemoveGrass or false      -- will be linked to Mod_NoGrass_Enabled
_G.ESPConfig.RemoveTree     = _G.ESPConfig.RemoveTree or false
_G.ESPConfig.RemoveWater    = _G.ESPConfig.RemoveWater or false
_G.ESPConfig.ForceChinese   = _G.ESPConfig.ForceChinese or false

-- Wallhack defaults
_G.ESPConfig.Wallhack              = _G.ESPConfig.Wallhack or false
_G.ESPConfig.WallhackVisibleColor  = _G.ESPConfig.WallhackVisibleColor or 1   -- 1=Red,2=White,3=Yellow,4=Green,5=Cyan,6=Blue,7=Purple
_G.ESPConfig.WallhackInvisibleColor= _G.ESPConfig.WallhackInvisibleColor or 2
_G.ESPConfig.WallhackBrightness    = _G.ESPConfig.WallhackBrightness or 25
_G.ESPConfig.WallhackGlow          = _G.ESPConfig.WallhackGlow or 3.0

-- ===================================================================
-- Require / Import helpers
-- ===================================================================
local require = require
local import  = import
local isValid = slua.isValid
local pcall = pcall
local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math
local string = string

local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
_G.CheatsEnabled = true

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local ok_gd, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
if not ok_gd then GameplayData = nil end

-- ===================================================================
-- PURE BYPASS MODULE (from 1.lua) - ULTIMATE UPGRADE
-- ===================================================================
local nop = nop
local retTrue = function() return true end
local retFalse = retFalse
local retZero = retZero
local retEmpty = retEmpty
local safe_require = safe_require
local isValid = isValid

-- Blacklists (expanded with new tracking domains)
local BLACKLIST_HOSTS = {
    "tss.tencent","syzsdk","gcloud.qq","reportlog","tdos","logupload","feedback.wh","crash2",
    "privacy.qq","privacy.tencent","oth.eve","mdt.qq","act.tencentyun","analytics","report.qq",
    "anticheatexpert","crashsight","wetest","log.tav","sngd","tracer","intlsdk","igamecj",
    "cdn.club","gpubgm","graph.facebook","calendarpushsubscription","googleads","doubleclick",
    "firebaselogging","firebaseremoteconfig","fonts.googleapis","abs.twimg","dl.listdl",
    "igame.gcloudcs","bugly","beacon","helpshift","tdm","apm","safeguard","weiyun","qzone",
    "tencent-cloud","myapp","idqqimg","gtimg","qqmail","tcdn","cloudctrl","sdkostrace",
    "103.134.189.146","mbgame","csoversea","igame","pubgmobile","down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com","log.tav.qq","syzsdk.qq","logiservice.qcloud",
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice",
    -- UPGRADE: additional domains
    "tlog.qq.com","beacon.qq.com","datacollect.qq.com","trace.qq.com","mta.qq.com",
    "ping.qq.com","report.bugly.qq.com","crash.qq.com","stats.qq.com","analytics.qq.com"
}
local BLACKLIST_PORTS = {
    "10334","11045","12221","13331","8011","8015","9001","20000","20001","20002","20003","20004",
    "20005","19700","1670","19900","14545","10213","8700","25177","10685","10336","10262","27000",
    "27040","27015","27030","10706","10095","12401","11008","10309","11075","10157","24798","10709",
    "6667","10087","31113","20371","10120","10664","13728","10769","10761","5061","5062","18081",
    "15692","9030","8080","8086","8088"
}
local FILE_KEYWORDS = {
    "tlog","crash","bugly","report","beacon","wetest","analytics","telemetry","trace","dump",
    "exception","feedback","aps_log","mtp_detect","network_loss","client_error","ue4crash","tdm","gcloud"
}

local function isBlacklisted(str)
    if type(str) ~= "string" then return false end
    local low = str:lower()
    for _, kw in ipairs(BLACKLIST_HOSTS) do
        if low:find(kw,1,true) then return true end
    end
    for _, port in ipairs(BLACKLIST_PORTS) do
        if low:find(":"..port) or low:find("/"..port) then return true end
    end
    return false
end

-- Base bypasses
local function InitBypassBase()
    pcall(function()
        local stExtra = import("STExtraBlueprintFunctionLibrary")
        if stExtra and stExtra.IsDevelopment then stExtra.IsDevelopment = nop end
        if Client then Client.IsDevelopment = nop; Client.IsShipping = retFalse end
        if Server then Server.IsShipping = retFalse end

        local ToolReport = safe_require("client.slua.logic.report.ToolReportUtil")
        if ToolReport then
            ToolReport.IsReleaseVersion = retFalse
            ToolReport.IsWhite = retFalse
            ToolReport.GetReportSwitch = retFalse
        end

        local callbacks = _G.GameplayCallbacks or _G.GC
        if callbacks then
            local kills = {
                "SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","SendDSHawkEyePatrolLogToLobby",
                "SendSecTLog","SendDataMiningTLog","SendActivityTLog","SendClientMemUsage","SendClientFPS",
                "OnClientCrashReport","OnNetworkLossDetected","ReportMatchRoomData","ReportPlayersPing",
                "SendClientStats","SendServerAvgTickDelta","ReportHitFlow","OnPlayerActorChannelError","OnPlayerRPCValidateFailed"
            }
            for _, fn in ipairs(kills) do
                if callbacks[fn] then callbacks[fn] = nop end
            end
            local origDS = callbacks.OnDSPlayerStateChanged
            if origDS then
                callbacks.OnDSPlayerStateChanged = function(dsSelf, state, reason, ...)
                    if tostring(reason):lower():find("cheatdetected") then return end
                    pcall(origDS, dsSelf, state, reason, ...)
                end
            end
        end

        if _G.TApmHelper then _G.TApmHelper.postEvent = nop end

        local PC = _G.PacketCallbacks
        if PC then
            PC.player_report_cheat = nop
            PC.upload_loots_rsp = nop
            PC.watch_player_exit = nop
            PC.player_login_report = nop
            PC.player_logout_report = nop
            PC.server_time_report = nop
        end

        local sdm = _G.ServerDataMgr
        if sdm and sdm.DeletablePlayerResultKey then
            sdm.DeletablePlayerResultKey["SuspiciousHitCount"] = true
            sdm.DeletablePlayerResultKey["EspTotalSimTraceCnt"] = true
            sdm.DeletablePlayerResultKey["EspTotalImeFocusCnt"] = true
            sdm.DeletablePlayerResultKey["ClientGravityAnomalyCount"] = true
        end

        local pcNotify = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature")
        if pcNotify then
            pcNotify.ClientRPC_SyncBanID = nop
            pcNotify.ClientRPC_StrongTips = nop
            pcNotify.ClientRPC_NormalTips = nop
            pcNotify.Notify = nop
            pcNotify.ClientRPC_NotifyBan = nop
            pcNotify.ClientRPC_NotifyPunish = nop
            pcNotify.ClientRPC_NotifyIllegalProgram = nop
        end

        local secUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if secUtils and secUtils.EStrategyTypeInReplay then
            secUtils.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
            secUtils.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
            secUtils.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
            secUtils.EStrategyTypeInReplay.FlyingErrorCnt = 0
        end
    end)
end

local function BypassHiggs()
    pcall(function()
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local methods = {
                "ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck","StartAvatarCheck",
                "ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar",
                "ClientReportNetAvatar","SendHisarData","ValidateSecurityData","StaticShowSecurityAlertInDev"
            }
            for _, m in ipairs(methods) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
        end
        if _G.DisableHiggsBoson then _G.DisableHiggsBoson = nop end

        local hia = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem")
        if hia then
            hia.CheckHitIntegrity = nop
            hia.InitSession = nop
            hia.OnBattleEnd = nop
        end

        local Behavior = safe_require("GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem")
        if Behavior then
            Behavior.OnHandleBehaviorScore = nop
            Behavior.AIPerceptionScore = nop
            Behavior.ReportBehavior = nop
            Behavior.CalcFinalScore = retZero
        end
    end)
end

local function BypassBanSystem()
    pcall(function()
        local BanLogic = safe_require("client.slua.logic.ban.ClientBanLogic")
        if BanLogic then
            BanLogic.OnSyncBanInfo = nop; BanLogic.OnVoiceBanNotify = nop
            BanLogic.OnRealTimeVoiceBanNotify = nop; BanLogic.OnVoiceBanSuccess = nop
            BanLogic.OnSyncMicSuspicious = nop; BanLogic.OnSyncMicPreFilter = nop
            BanLogic.OnNotifyWarningTips = nop; BanLogic.ReqBanInfo = nop
        end

        local BanUtil = safe_require("client.common.ban_util") or _G.ban_util
        if BanUtil then
            BanUtil.CheckBanStatus = retFalse
            BanUtil.GetBanTime = retZero
            BanUtil.IsBanForever = retFalse
        end

        local TTBan = safe_require("client.logic.login.logic_tt_ban") or _G.logic_tt_ban
        if TTBan then
            TTBan.CheckIfCanCreateRole = nop
            TTBan.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end
        end

        local GodzillaBan = safe_require("client.network.Protocol.GodzillaBanHandler")
        if GodzillaBan then
            GodzillaBan.send_godzilla_ban_req = nop
            GodzillaBan.send_godzilla_unban_req = nop
        end

        local AntiAddiction = safe_require("client.network.Protocol.AntiaddctionHandler")
        if AntiAddiction then
            AntiAddiction.send_anti_addiction_req = nop
            AntiAddiction.send_anti_addiction_notify = nop
        end

        local AccessRestrict = safe_require("client.network.Protocol.AccessRestrictionHandler")
        if AccessRestrict then
            AccessRestrict.send_access_restriction_req = nop
            AccessRestrict.send_access_restriction_notify = nop
            AccessRestrict.on_player_cheat_state_notify = nop
        end

        local DeleteAccount = safe_require("client.slua.logic.gdpr.logic_deleteaccount")
        if DeleteAccount then
            DeleteAccount.ForceDeleteAccount = retFalse
            DeleteAccount.OnReceiveDeleteNotify = nop
        end

        local ComplianceUtil = safe_require("client.slua.logic.gdpr.compliance_util")
        if ComplianceUtil then ComplianceUtil.CheckCompliance = nop end
    end)
end

local function BypassReportSystems()
    pcall(function()
        local clientReport = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if clientReport then
            local funcs = {"OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","SendPacket","ReportSuspiciousPlayer","SubmitReport","_OnBattleResult","_RecordTeammatePlayerInfo","_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData"}
            for _, fn in ipairs(funcs) do
                if clientReport[fn] then clientReport[fn] = nop end
            end
        end

        local dsReport = safe_require("GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem")
        if dsReport then
            local funcs = {"_OnNearDeathOrRescued","_OnPlayerSettlementStart","_OnTeammateDamage","_OnCharacterDied","_AddEnemyMapToBattleResult","_AddTeammateMapToBattleResult","_SubmitAbnormalData"}
            for _, fn in ipairs(funcs) do
                if dsReport[fn] then dsReport[fn] = nop end
            end
        end

        local reportUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if reportUtils then
            reportUtils.GetBotType = retZero
            reportUtils.IsCharacterDeliverAI = retFalse
        end

        local AvatarSub = safe_require("GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionSubsystem")
        if AvatarSub then
            AvatarSub.OnClickReportCheckAvatar = nop
            AvatarSub.RegisterTickCheckCharacterAvatar = nop
        end

        if _G.AvatarExceptionPlayerInst then
            _G.AvatarExceptionPlayerInst.ReportAvatarException = nop
            _G.AvatarExceptionPlayerInst.CheckAvatarException = nop
            _G.AvatarExceptionPlayerInst.CheckCanBugglyPostException = nop
        end

        local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local hawk = SubsystemMgr:Get("DSHawkEyePatrolSubsystem")
            if hawk then hawk.MarkSuspiciousPlayer = nop end
        end

        if _G.DSHawkEyePatrolSubsystem then
            _G.DSHawkEyePatrolSubsystem._OnHawkReport = nop
            _G.DSHawkEyePatrolSubsystem._OnHawkImprison = nop
            _G.DSHawkEyePatrolSubsystem.CheckPunishPlayer = nop
        end

        local ClientHawk = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem")
        if ClientHawk then
            local funcs = {"_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer","_OnRecvInspectorBroadcastCount","SendReportTLog","ReportCheat"}
            for _, fn in ipairs(funcs) do
                if ClientHawk[fn] then ClientHawk[fn] = nop end
            end
            ClientHawk.CanInspectorBroadcast = retFalse
        end

        local InspectClient = safe_require("GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem")
        if InspectClient then
            local funcs = {"AskForInspector","ReportEnemy","KickOutOneTeam","OnReceiveInspectCmd","ClientReportData","SendReportToInspector","SendKickOutOneTeam","ClientNotifyInspectorImplementation","RecvNotifyInspector"}
            for _, fn in ipairs(funcs) do
                if InspectClient[fn] then InspectClient[fn] = nop end
            end
        end

        local InspectDS = safe_require("GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem")
        if InspectDS then
            local funcs = {"ServerKickOutOneTeamByPlayerImplementation","AddReportedCount","AddInspectionRecord","BanPlayerByInspection","BroadCastToAllInspector","ServerReportToInspectorImplementation","InitPlayerInspectionInfo"}
            for _, fn in ipairs(funcs) do
                if InspectDS[fn] then InspectDS[fn] = nop end
            end
        end
    end)
end

-- UPGRADE: Battle result spoofing (enhanced)
local function SpoofBattleResult(originalData)
    if not originalData then return originalData end
    pcall(function()
        -- Clamp kills to a random low number (1–3) to avoid suspicion
        if originalData.KillNum and originalData.KillNum > 3 then
            originalData.KillNum = math.random(1, 3)
        end
        -- Reduce damage dealt
        if originalData.TotalDamage and originalData.TotalDamage > 200 then
            originalData.TotalDamage = math.random(50, 180)
        end
        -- Lower headshot rate
        if originalData.HeadShotNum then
            originalData.HeadShotNum = math.min(originalData.HeadShotNum, 1)
        end
        -- Spoof accuracy (70–80%)
        if originalData.ShootNum and originalData.HitNum then
            originalData.HitNum = math.floor(originalData.ShootNum * (0.70 + math.random()*0.10))
        end
        -- Spoof survival time (random)
        if originalData.SurvivalTime then
            originalData.SurvivalTime = math.random(120, 600)
        end
        -- Spoof ranking
        if originalData.Ranking then
            originalData.Ranking = math.random(20, 50)
        end
        -- Spoof team placement
        if originalData.TeamRanking then
            originalData.TeamRanking = math.random(5, 15)
        end
        -- Spoof distance travelled
        if originalData.DistanceTraveled then
            originalData.DistanceTraveled = math.random(1000, 5000)
        end
    end)
    return originalData
end

local function BypassTLogModules()
    pcall(function()
        local tlogMods = {
            "client.network.Protocol.ClientTlogHandler","client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler","client.network.Protocol.LobbyPingReportHandler",
            "client.slua.config.tlog.tlog_report_utils","client.slua.data.BasicData.BasicDataTLogReport",
            "client.slua.data.BasicData.BasicDataClientReport","client.slua.data.BasicData.BasicDataReport",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem","GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem","GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"
        }
        for _, path in ipairs(tlogMods) do
            local mod = package.loaded[path]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and (k:find("Log") or k:find("Report") or k:find("Send") or k:find("Tlog")) then
                        pcall(function() mod[k] = nop end)
                    end
                end
            end
        end

        local AmphibiousBoat = safe_require("GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature")
        if AmphibiousBoat then
            AmphibiousBoat.RecordMovement = nop
            AmphibiousBoat.StartRecordMovement = nop
        end

        local ICTLog = safe_require("GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem")
        if ICTLog then ICTLog.SendICExceptionTLog = nop end

        local DSFight = safe_require("GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem")
        if DSFight then
            DSFight.GetSimpleFightData = retEmpty
            DSFight.ReportFightData = nop
            DSFight.ReportPlayerWeapon = nop
        end

        local DSSec = safe_require("GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem")
        if DSSec then
            DSSec._OnReportServerJumpFlow = nop
            DSSec._OnReportTeleportFlow = nop
            DSSec._OnReportSpeedHackFlow = nop
        end

        local DSCommon = safe_require("GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem")
        if DSCommon then DSCommon.HandleKillTlog = nop end

        local PufferTlog = safe_require("client.slua.logic.download.report.puffer_tlog")
        if PufferTlog then PufferTlog.report_download_tlog = nop end
    end)
end

-- UPGRADE: Override SendEndFlow with spoofing instead of nop
local function BypassNetworkHandlers()
    pcall(function()
        local ClientError = safe_require("client.network.Protocol.ClientErrorReportHandler")
        if ClientError then
            ClientError.send_client_error_report = nop
            ClientError.send_client_crash_report = nop
            ClientError.send_client_tools_batch_report_req = nop
        end

        local BattleReport = safe_require("client.network.Protocol.BattleReportHandler")
        if BattleReport then
            for _, fn in ipairs({"send_battle_report","send_battle_result","send_vod_game_report_req","send_batch_get_vod_info_req","send_get_game_report_req","send_batch_get_game_report_req","send_get_game_report_by_uid_req"}) do
                if BattleReport[fn] then BattleReport[fn] = nop end
            end
        end

        local BugHandler = safe_require("client.network.Protocol.BugHandler")
        if BugHandler then
            BugHandler.send_report_bug_info = nop
            BugHandler.send_report_bug_feedback = nop
        end

        local PingReport = safe_require("client.network.Protocol.LobbyPingReportHandler")
        if PingReport then
            PingReport.send_lobby_ping_report = nop
            PingReport.send_ingame_ping_report = nop
        end

        local WeekReport = safe_require("client.network.Protocol.WeekRportHandler")
        if WeekReport then
            WeekReport.send_week_report = nop
            WeekReport.send_week_detail = nop
        end

        local LogicComplaint = safe_require("client.logic.battle.logic_complaint")
        if LogicComplaint then
            LogicComplaint.SendComplaintReq = nop
            LogicComplaint.Submit = nop
            LogicComplaint.ReportPlayer = nop
            LogicComplaint.ShowComplaint = nop
            LogicComplaint.ShowHandle = nop
        end

        local OBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic")
        if OBResult then
            OBResult.OnBattleResult = nop
            OBResult.OnResultProcessStart = nop
        end

        local NormalOBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic")
        if NormalOBResult then
            NormalOBResult.OnBattleResult = nop
            NormalOBResult.OnResultProcessStart = nop
        end

        -- UPGRADE: Instead of nop'ing SendEndFlow, we hook it to spoof data
        local ShowResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic")
        if ShowResult then
            -- Keep other functions nop'ed, but override SendEndFlow
            for _, fn in ipairs({"OnBattleResult","OnResultProcessStart","OnResultProcessContinue","ReceiveData","OnReport","ShowResult","ShowResultInternal","StopResultProcess"}) do
                if ShowResult[fn] then ShowResult[fn] = nop end
            end
            -- Hook SendEndFlow to spoof data before sending
            if ShowResult.SendEndFlow then
                local origSendEndFlow = ShowResult.SendEndFlow
                ShowResult.SendEndFlow = function(self, ...)
                    if self.BattleResultData then
                        self.BattleResultData = SpoofBattleResult(self.BattleResultData)
                    end
                    return origSendEndFlow(self, ...)
                end
            end
        end
    end)
end

local function BypassMiscSystems()
    pcall(function()
        local EmuHandler = safe_require("client.network.Protocol.EmulatorHandler")
        if EmuHandler then EmuHandler.send_emulator_info = nop end

        local EmuScanner = safe_require("client.logic.login.emulator_scanner")
        if EmuScanner then
            EmuScanner.StartScan = nop
            EmuScanner.GetScanResult = retFalse
            EmuScanner.ReportScanResult = nop
        end

        local LoginVerify = safe_require("client.network.Protocol.LoginVerifyHandler")
        if LoginVerify then
            LoginVerify.send_login_verify_req = nop
            LoginVerify.send_device_verify_req = nop
        end

        local DSMonitor = safe_require("client.logic.data.logic_ds_monitor")
        if DSMonitor then
            DSMonitor.OnRecordMsg = nop
            DSMonitor.OnReportMsg = nop
        end

        local ClientDataStat = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem")
        if ClientDataStat then
            ClientDataStat.StartToCheck = nop
            ClientDataStat.OnReceiveRTT = nop
            ClientDataStat.OnReceiveJitter = nop
            ClientDataStat.ReportAbnormal = nop
            ClientDataStat.ResetData = nop
        end

        local shootVerify = safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if shootVerify then
            shootVerify.OnShootVerifyFailed = nop
            shootVerify.SendVerifyData = nop
        end

        local HighlightDS = safe_require("GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker")
        if HighlightDS then HighlightDS.CheckFuncUpgradedWeaponKill = nop end

        local ProfileReport = safe_require("client.logic.data.profile_report_cfg")
        if ProfileReport then ProfileReport.SendReport = nop end

        local VoiceReport = safe_require("client.slua.logic.chat_voice.logic_chat_voice_report")
        if VoiceReport then
            VoiceReport.ReportVoiceData = nop
            VoiceReport.ReportVoiceText = nop
        end

        local VoiceDoctor = safe_require("client.slua.logic.chat_voice.logic_chat_voice_doctor")
        if VoiceDoctor then
            VoiceDoctor.UploadVoiceLog = nop
            VoiceDoctor.UploadVoiceException = nop
        end

        local HomeAudit = safe_require("client.slua.logic.home.Audit.logic_home_audit_state")
        if HomeAudit then
            HomeAudit.SendAuditState = nop
            HomeAudit.ReportAuditResult = nop
        end

        local HomeReport = safe_require("client.slua.logic.home.logic_home_report")
        if HomeReport then
            HomeReport.ReportHomeData = nop
            HomeReport.ReportHomeVisitor = nop
        end

        local GemReport = safe_require("client.logic.store.gem_report_utils")
        if GemReport then
            GemReport.ReportGemData = nop
            GemReport.ReportGemPurchase = nop
        end

        local SafeStation = safe_require("client.slua.logic.CustomerService.LogicSafeStation")
        if SafeStation then
            SafeStation.UploadVideoEvidence = nop
            SafeStation.ReportPlayerBehavior = nop
        end

        local CustomerService = safe_require("client.slua.logic.CustomerService.LogicCustomerService")
        if CustomerService then
            CustomerService.SendComplaint = nop
            CustomerService.SendFeedback = nop
        end
    end)
end

local function BypassExtraSubsystems()
    pcall(function()
        local znq6Revive = safe_require("GameLua.Mod.TDEvent.ZNQ6th.DS.ZNQ6thDSReviveSubsystem")
        if znq6Revive then znq6Revive.HaveNewItemForRevive = nop end

        local znq7Revive = safe_require("GameLua.Mod.TDEvent.ZNQ7th.DS.ZNQ7DSReviveSubsystem")
        if znq7Revive then znq7Revive.HaveChanceRevival = nop end

        local DataLayer = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem")
        if DataLayer then
            local orig = DataLayer.OnSpectatorReplayChanged
            if orig then
                DataLayer.OnSpectatorReplayChanged = function(dlSelf)
                    _G.IsBeingWatched = true
                    orig(dlSelf)
                end
            end
        end

        local DSActive = safe_require("GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem")
        if DSActive then
            DSActive.DelayKickOutPlayer = nop
            DSActive.ActiveKickNotify = nop
        end

        local CreativeDev = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem")
        if CreativeDev then CreativeDev.IsDebugPanelEnalbedCli = nop end

        local CreativeDeath = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem")
        if CreativeDeath then CreativeDeath.OnPlayerKilled = nop end

        if _G.ClientReplayDataReporter then
            _G.ClientReplayDataReporter.ReportIntArrayData = nop
            _G.ClientReplayDataReporter.ReportFloatArrayData = nop
        end

        local SpectateReplay = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
        if SpectateReplay then
            SpectateReplay.RequestGotoSpectatingImp = nop
            SpectateReplay.RequestGotoSpectating = nop
        end

        local AIReplay = safe_require("GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem")
        if AIReplay then
            AIReplay.ReportAllPlayerInfo = nop
            AIReplay.ReportFrameData = nop
            AIReplay.ReportPlayerInput = nop
            if AIReplay.uCompletePlayBack then
                AIReplay.uCompletePlayBack.AddRecordMLAIInfo = nop
                AIReplay.uCompletePlayBack.StopRecording = nop
            end
        end

        local AITracking = safe_require("GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem")
        if AITracking then
            AITracking.RealLogoutTimer = nop
            AITracking.LogQueue = {}
            AITracking.AddToLogQue = nop
            AITracking.DoPrint = nop
            AITracking.OnAIPawnDied = nop
            AITracking.OnAIPawnReceiveDamage = nop
            AITracking.OnAIPawnEnemyChange = nop
        end

        local AFKReport = safe_require("GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem")
        if AFKReport then
            AFKReport.HandleEnterFighting = nop
            AFKReport.InitializePlayerInputInfo = nop
            AFKReport.AddOneAFKInfo = nop
            AFKReport.SetPlayerAFKState = nop
            AFKReport.ResetPlayerInputInfo = nop
            AFKReport.PlayerHaveAction = nop
        end

        local TDMAFK = safe_require("GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem")
        if TDMAFK then
            TDMAFK.SendAFKTips = nop
            TDMAFK.OnHandleLostConnection = nop
        end

        local DataMgr = safe_require("client.slua.logic.data.data_mgr")
        if DataMgr then DataMgr.GetWeaponSkinSoundVolumeInfoByGroup = retZero end

        local CreditLogic = safe_require("GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic")
        if CreditLogic then
            CreditLogic._SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = nop
            CreditLogic.ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse
            CreditLogic.OnReceiveCreditScoreChange = nop
            CreditLogic._IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse
            CreditLogic.SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = nop
        end
    end)
end

local function InitNetworkBlacklist()
    pcall(function()
        if _G.HttpRequest then
            local orig = _G.HttpRequest
            _G.HttpRequest = function(url, ...)
                if isBlacklisted(url) then return nil end
                return orig(url, ...)
            end
        end

        if _G.FHttpModule and _G.FHttpModule.CreateRequest then
            local orig = _G.FHttpModule.CreateRequest
            _G.FHttpModule.CreateRequest = function(...)
                local url = select(1, ...)
                if isBlacklisted(url) then return nil end
                return orig(...)
            end
        end

        local netMods = {
            "client.slua.logic.network.logic_network","client.slua.logic.download.report.puffer_tlog",
            "client.slua.data.BasicData.BasicDataClientReport","GameLua.GameCore.Module.Network.NetworkManager",
            "client.network.Protocol.ClientTlogHandler","client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler"
        }
        for _, mp in ipairs(netMods) do
            local mod = package.loaded[mp]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and (k:find("Http") or k:find("Request") or k:find("Send") or k:find("Upload") or k:find("Post") or k:find("Get") or k:find("Report")) then
                        local origf = v
                        mod[k] = function(...)
                            local args = {...}
                            for _, arg in ipairs(args) do
                                if type(arg) == "string" and isBlacklisted(arg) then return nil end
                            end
                            return pcall(origf, ...)
                        end
                    end
                end
            end
        end
    end)
end

local function InitFileIOCrashBlock()
    local orig_io_open = io.open
    io.open = function(path, mode)
        if type(path) == "string" then
            local lp = path:lower()
            for _, kw in ipairs(FILE_KEYWORDS) do
                if lp:find(kw) then
                    if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                        return nil, "Blocked"
                    end
                end
            end
            if lp:find("tdm") or lp:find("gcloud") or lp:find("beacon") then
                if mode and (mode == "w" or mode == "a" or mode == "w+") then
                    return nil
                end
            end
        end
        return orig_io_open(path, mode)
    end

    if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
        _G.UnrealEngine.CrashContext = nil
        _G.UnrealEngine.CrashContext = {
            SetCrashContext = nop,
            ReportCrash = nop,
            AddCrashData = nop
        }
    end
end

-- 8‑Layer Advanced Bypasses
local BypassState = {
    DeadEyeDisabled = false, HawkEyeDisabled = false, VoklaiDisabled = false,
    HiggsBosonDisabled = false, HashVerifyDisabled = false, IPMappingDisabled = false,
    MemoryPatchDisabled = false, EduEyeDisabled = false, FullBypassActive = false
}

local FakeData = {
    ping = function() return math.random(20, 45) end,
    deviceID = function()
        local chars = "0123456789ABCDEF"
        local id = ""
        for i = 1, 32 do
            id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        return id
    end,
    ipAddress = function() return "192.168." .. math.random(1, 255) .. "." .. math.random(1, 255) end,
    macAddress = function()
        return string.format("%02X:%02X:%02X:%02X:%02X:%02X",
            math.random(0,255), math.random(0,255), math.random(0,255),
            math.random(0,255), math.random(0,255), math.random(0,255))
    end,
    buildFingerprint = function()
        return "qcom/msmnile/msmnile:" .. math.random(10,12) .. "/" ..
               math.random(100000,999999) .. "/user/release-keys"
    end,
    kernelVersion = function() return "4.19." .. math.random(100,200) .. "-generic" end,
    hashValue = function() return "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" end
}

local function KillTable(tbl, keys)
    if not tbl then return end
    for _, key in ipairs(keys) do
        pcall(function()
            if type(tbl[key]) == "function" then
                tbl[key] = function() return true, {} end
            else
                tbl[key] = nil
            end
        end)
    end
end

local function BypassDeadEye()
    if BypassState.DeadEyeDisabled then return end
    pcall(function()
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, {
                "ReportAimFlow","ReportHitFlow","ReportAttackFlow",
                "OnAimDetected","OnHeadshotDetected","OnPerfectAccuracy"
            })
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aimTracker = subsystems:Get("ClientAimTrackingSubsystem")
            if aimTracker then
                aimTracker.GetAimData = function()
                    return {accuracy = math.random(45,65), headshotRate = math.random(15,35)}
                end
                aimTracker.IsAimNormal = function() return true end
            end
        end
    end)
    BypassState.DeadEyeDisabled = true
    _G.BYPASS_STATE.DEADEYE_DISABLED = true
end

local function BypassHawkEye()
    if BypassState.HawkEyeDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local hawkEye = subsystems:Get("ClientHawkEyePatrolSubsystem")
            if hawkEye then
                hawkEye.GetPatrolData = function() return {} end
                hawkEye.IsBeingWatched = function() return false end
                hawkEye.GetSpectatorCount = function() return 0 end
            end
        end
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, {
                "SendDSErrorLogToLobby","SendDSHawkEyePatrolLogToLobby","ReportMatchRoomData"
            })
        end
    end)
    BypassState.HawkEyeDisabled = true
    _G.BYPASS_STATE.HAWKEYE_DISABLED = true
end

local function BypassVoklai()
    if BypassState.VoklaiDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aiBehavior = subsystems:Get("ClientAIBehaviourSubsystem")
            if aiBehavior then
                aiBehavior.GetBehaviorScore = function() return math.random(10,30) end
                aiBehavior.IsSuspicious = function() return false end
                aiBehavior.GetRiskLevel = function() return 0 end
            end
            local stepCheck = subsystems:Get("ClientStepCheckSubsystem")
            if stepCheck then
                stepCheck.GetStepDelta = function() return math.random(5,50) end
                stepCheck.IsMovementValid = function() return true end
            end
            local speedHack = subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem")
            if speedHack then
                speedHack.GetSpeed = function() return math.random(300,600) end
                speedHack.IsSpeedValid = function() return true end
            end
        end
    end)
    BypassState.VoklaiDisabled = true
    _G.BYPASS_STATE.VOKLAI_DISABLED = true
end

local function BypassHiggsBoson8()
    if BypassState.HiggsBosonDisabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) then
            if pc.HiggsBoson then
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent:ControlMHActive(0)
            end
        end
        local higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgs then
            higgs.GetNetAvatarItemIDs = function() return {1001,2002,3003,4004,5005} end
            higgs.GetCurWeaponSkinID = function() return 6001 end
            higgs.GetCurItemIDs = function() return {7001,8002} end
            if higgs.BlackList then higgs.BlackList = {} end
        end
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
        _G.BlackList = {}
    end)
    BypassState.HiggsBosonDisabled = true
    _G.BYPASS_STATE.HIGGSBOSON_DISABLED = true
end

local function BypassHashVerification()
    if BypassState.HashVerifyDisabled then return end
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.ScanMemory = function() return true, {code=0, msg="clean"} end
            _G.TssSdk.ScanSo = function() return true, {code=0, msg="clean"} end
            _G.TssSdk.ScanFile = function() return true, {code=0} end
            _G.TssSdk.GetRiskFlag = function() return 0 end
            _G.TssSdk.VerifyFileHash = function() return true end
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local integrity = subsystems:Get("ClientIntegrityCheckSubsystem")
            if integrity then
                KillTable(integrity, {"CheckFileHash","VerifyMemory","ScanModules"})
            end
        end
    end)
    BypassState.HashVerifyDisabled = true
    _G.BYPASS_STATE.HASH_VERIFY_DISABLED = true
end

local function BypassIPMapping()
    if BypassState.IPMappingDisabled then return end
    pcall(function()
        if _G.GameplayCallbacks then
            KillTable(_G.GameplayCallbacks, {
                "SendClientDeviceInfo","ReportDeviceFingerprint","SendNetworkInfo",
                "ReportIPAddress","SendMACAddress","ReportHardwareID"
            })
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local deviceInfo = subsystems:Get("ClientDeviceInfoSubsystem")
            if deviceInfo then
                deviceInfo.GetDeviceID = function() return FakeData.deviceID() end
                deviceInfo.GetIPAddress = function() return FakeData.ipAddress() end
                deviceInfo.GetMACAddress = function() return FakeData.macAddress() end
            end
        end
    end)
    BypassState.IPMappingDisabled = true
    _G.BYPASS_STATE.IP_MAPPING_DISABLED = true
end

local function BypassMemoryPatching()
    if BypassState.MemoryPatchDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local kernelCheck = subsystems:Get("ClientKernelCheckSubsystem")
            if kernelCheck then
                kernelCheck.IsKernelClean = function() return true end
                kernelCheck.GetKernelVersion = function() return FakeData.kernelVersion() end
                kernelCheck.IsBootloaderLocked = function() return true end
            end
            local memoryGuard = subsystems:Get("ClientMemoryGuardSubsystem")
            if memoryGuard then
                memoryGuard.IsMemoryClean = function() return true, {code=0} end
                memoryGuard.ScanResult = function() return "clean" end
            end
        end
        if _G.TssSdk then
            _G.TssSdk.CheckKernel = function() return true, {status="verified", tampered=false} end
            _G.TssSdk.VerifyBoot = function() return true, {locked=true, verified=true} end
        end
    end)
    BypassState.MemoryPatchDisabled = true
    _G.BYPASS_STATE.MEMORY_PATCH_DISABLED = true
end

local function BypassEduEye()
    if BypassState.EduEyeDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local renderCheck = subsystems:Get("ClientRenderCheckSubsystem")
            if renderCheck then
                renderCheck.IsRenderClean = function() return true end
                renderCheck.GetRenderState = function() return "normal" end
            end
            local espDetection = subsystems:Get("ClientESPDetectionSubsystem")
            if espDetection then
                espDetection.HasESP = function() return false end
                espDetection.CheckOverlay = function() return "clean" end
            end
            local wallhackDetect = subsystems:Get("ClientWallhackDetectionSubsystem")
            if wallhackDetect then
                wallhackDetect.IsVisionNormal = function() return true end
                wallhackDetect.GetVisibilityRate = function() return math.random(60,85) end
            end
        end
    end)
    BypassState.EduEyeDisabled = true
    _G.BYPASS_STATE.EDU_EYE_DISABLED = true
end

-- UPGRADE: Kill limit bypass (enhanced)
local function RemoveKillLimit()
    pcall(function()
        -- In training mode or certain modes, there is a kill cap
        local KILL_LIMIT_CFG = "GameLua.Mod.Training.GamePlay.Config.TrainingKillLimitConfig"
        local config = safe_require(KILL_LIMIT_CFG)
        if config then
            config.MaxKillCount = 9999
            config.KillLimit = 9999
        end
        -- Also kill the internal kill counter reset
        local KillCounter = safe_require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounter and KillCounter.__inner_impl then
            KillCounter.__inner_impl.ResetKillCount = function() end
        end
        -- Additional kill limit overrides
        local GameMode = safe_require("GameLua.Mod.BaseMod.GamePlay.GameMode.BaseGameMode")
        if GameMode then
            GameMode.MaxKillCount = 9999
        end
    end)
end

-- UPGRADE: Continuous anti-detection patrol (enhanced)
local function DeepHuntAndNop()
    pcall(function()
        -- Scan all loaded modules for suspicious functions
        for modName, modTable in pairs(package.loaded) do
            if type(modTable) == "table" then
                for k, v in pairs(modTable) do
                    if type(v) == "function" then
                        local name = tostring(k):lower()
                        if name:find("report") or name:find("log") or name:find("send") or name:find("tlog") then
                            pcall(function() modTable[k] = function() end end)
                        end
                    end
                end
            end
        end
        -- Also disable any new subsystems
        local mgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if mgr and mgr.Get then
            local subsystems = {
                "ClientStatisticSubsystem", "GameStatisticSubsystem",
                "ReportPlayerSubsystem", "DSReportPlayerSubsystem",
                "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem"
            }
            for _, name in ipairs(subsystems) do
                local sub = mgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" then
                            pcall(function() sub[k] = function() end end)
                        end
                    end
                end
            end
        end
        -- Also kill any newly appeared global functions
        local newFuncs = {
            "OnPlayerReported", "OnCheatDetected", "OnSuspiciousActivity",
            "ReportCheatUsage", "LogCheatEvent", "SendSecurityAlert"
        }
        for _, fn in ipairs(newFuncs) do
            if _G[fn] then _G[fn] = nop end
        end
    end)
end

-- UPGRADE: Spoof player behaviour (enhanced)
local function SpoofPlayerBehaviour()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.GetPlayerStatistics then
            local stats = pc:GetPlayerStatistics()
            if stats then
                stats.AveragePing = math.random(40, 80)
                stats.PacketLoss = math.random(0, 2) / 10
                stats.InputDelay = math.random(20, 50)
                -- Add network jitter
                stats.Jitter = math.random(0, 5)
                -- Randomise FPS
                stats.FPS = math.random(30, 60)
            end
        end
        -- Fake device info
        if _G.DeviceInfo then
            _G.DeviceInfo.GetDeviceModel = function() return "SM-G998B" end
            _G.DeviceInfo.GetOSVersion = function() return "Android 12" end
        end
    end)
end

-- UPGRADE: Extra security overrides (enhanced)
local function ApplyExtraSecurity()
    pcall(function()
        local SecurityCommon = safe_require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
        if SecurityCommon then
            SecurityCommon.CheckIsCheat = function() return false end
            SecurityCommon.IsSuspicious = function() return false end
            SecurityCommon.GetRiskLevel = function() return 0 end
            SecurityCommon.IsRooted = function() return false end
            SecurityCommon.IsEmulator = function() return false end
        end
        if _G.TssSdk then
            _G.TssSdk.GetRiskFlag = function() return 0 end
            _G.TssSdk.VerifyFileHash = function() return true end
            _G.TssSdk.CheckRoot = function() return false end
            _G.TssSdk.CheckEmulator = function() return false end
        end
        -- Disable any console commands that report
        if _G.ExecuteConsoleCommand then
            local orig = _G.ExecuteConsoleCommand
            _G.ExecuteConsoleCommand = function(cmd, value)
                local blocked = {"report", "log", "tlog", "telemetry"}
                for _, b in ipairs(blocked) do
                    if cmd:lower():find(b) then return end
                end
                return orig(cmd, value)
            end
        end
    end)
end

-- UPGRADE: Root detection bypass
local function BypassRootDetection()
    pcall(function()
        if _G.RootDetection then
            _G.RootDetection.IsRooted = function() return false end
            _G.RootDetection.IsDeviceCompromised = function() return false end
        end
        if _G.EmulatorDetection then
            _G.EmulatorDetection.IsEmulator = function() return false end
        end
        -- Hook package loader to prevent root checks
        local orig_require = require
        _G.require = function(path)
            if path:find("root") or path:find("emulator") or path:find("jailbreak") then
                return {}
            end
            return orig_require(path)
        end
    end)
end

-- UPGRADE: Memory flag cleaner
local function CleanMemoryFlags()
    pcall(function()
        -- Search for known detection flags and set to 0
        local mgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if mgr and mgr.Get then
            local flags = {
                "ClientSecuritySubsystem", "DSSecuritySubsystem",
                "AntiCheatSubsystem", "ClientAntiCheatSubsystem"
            }
            for _, name in ipairs(flags) do
                local sub = mgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "number" and k:find("flag") or k:find("count") or k:find("score") then
                            pcall(function() sub[k] = 0 end)
                        end
                    end
                end
            end
        end
    end)
end

local function ApplyAllBypasses()
    if BypassState.FullBypassActive then return end
    pcall(function()
        BypassDeadEye()
        BypassHawkEye()
        BypassVoklai()
        BypassHiggsBoson8()
        BypassHashVerification()
        BypassIPMapping()
        BypassMemoryPatching()
        BypassEduEye()
        RemoveKillLimit()
        ApplyExtraSecurity()
        BypassRootDetection()
        CleanMemoryFlags()
        BypassState.FullBypassActive = true
        _G.BYPASS_STATE.FULL_BYPASS_ACTIVE = true
    end)
end

-- Master initialisation
local function InitAllBypasses()
    pcall(function()
        InitBypassBase()
        BypassHiggs()
        BypassBanSystem()
        BypassReportSystems()
        BypassTLogModules()
        BypassNetworkHandlers()
        BypassMiscSystems()
        BypassExtraSubsystems()
        InitNetworkBlacklist()
        InitFileIOCrashBlock()
        ApplyAllBypasses()

        -- Global functions nop
        local globalFuncs = {
            "ReportTLogEvent","SendTlog","SendClientStats","ReportHitFlow","ReportAvatarException",
            "SendComplaintReq","SubmitReport","ReportSuspiciousPlayer","SendPacket","OnSyncBanInfo",
            "OnVoiceBanNotify","SendSecTLog","MarkSuspiciousPlayer","ReportPlayerBehaviorData",
            "CheckCompliance","ReportIllegalProgram","UploadVoiceLog"
        }
        for _, fn in ipairs(globalFuncs) do
            if type(_G[fn]) == "function" then _G[fn] = nop end
        end

        -- Screenshot, TLog, CrashSight
        pcall(function()
            local s = import("ScreenshotMaker")
            if s then
                s.MakePicture = nop
                s.ReMakePicture = nop
                s.HasCaptured = retTrue
            end
            local tl = package.loaded["TLog"] or _G.TLog
            if tl then
                tl.Info = nop; tl.Warning = nop; tl.Error = nop; tl.Debug = nop; tl.Report = nop
            end
            local cs = package.loaded["CrashSight"] or _G.CrashSight
            if cs then
                cs.ReportException = nop
                cs.SetCustomData = nop
                cs.Log = nop
            end
        end)

        -- NetUtil block (with extra packet blacklist)
        pcall(function()
            if _G.NetUtil and _G.NetUtil.SendPacket and not _G.NetUtil._IsBypassed then
                local origSend = _G.NetUtil.SendPacket
                local blocked = {
                    ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportHurtFlow"]=1,
                    ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                    ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1,
                    ["ReportPlayerPosition"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1,
                    ["ReportCircleFlow"]=1, ["ReportJumpFlow"]=1, ["report_players_ping"]=1,
                    ["report_player_ip"]=1, ["tss_sdk_report"]=1, ["report_client_scan_result"]=1,
                    ["report_memory_exception"]=1, ["report_avatar_exception"]=1, ["report_character_state"]=1,
                    ["report_vehicle_exception"]=1, ["report_camera_exception"]=1, ["ReportEquipmentFlow"]=1,
                    ["ReportHeavyWeaponBoxSpawnFlow"]=1, ["ReportHeavyWeaponBoxActivationFlow"]=1,
                    ["ReportSecTLog"]=1, ["report_player_frame_ping_record"]=1, ["ReportSecAttackFlow"]=1,
                    ["ReportSecTgameMovingFlow"]=1, ["ReportVehicleMoveFlow"]=1, ["ReportParachuteData"]=1,
                    ["report_unrealnet_exception"]=1, ["report_ds_net_saturation"]=1, ["on_tss_sdk_anti_data"]=1,
                    -- UPGRADE: extra packets
                    ["report_kill_count"]=1, ["report_damage"]=1, ["report_accuracy"]=1,
                    ["report_headshot"]=1, ["report_knock"]=1, ["report_assist"]=1,
                    ["report_player_movement"]=1, ["report_aim_assist"]=1, ["report_auto_aim"]=1,
                    ["report_weapon_switch"]=1, ["report_recoil_pattern"]=1,
                    ["report_frame_rate"]=1, ["report_ping"]=1, ["report_device_info"]=1,
                    ["report_battery"]=1, ["report_memory_usage"]=1,
                    ["send_battle_result"]=1, ["send_game_report"]=1, ["send_vod_game_report_req"]=1,
                    ["send_batch_get_vod_info"]=1, ["send_get_game_report"]=1,
                    ["report_ugc_interaction"]=1, ["report_mod_stay"]=1,
                }
                _G.NetUtil.SendPacket = function(packetName, ...)
                    if blocked[packetName] then return end
                    return origSend(packetName, ...)
                end
                _G.NetUtil._IsBypassed = true
            end
        end)

        -- Higgs BlackList clean
        pcall(function()
            local hbc = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if hbc and hbc.BlackList then
                for k in pairs(hbc.BlackList) do hbc.BlackList[k] = nil end
            end
            _G.BlackList = {}
            _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
            local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
            mt.__newindex = function() end
            setmetatable(_G.GlobalPlayerCoronaData, mt)
        end)

        -- GameSafeCallbacks and GameplayCallbacks extra
        pcall(function()
            if _G.GameSafeCallbacks then
                _G.GameSafeCallbacks.RecordStrategyTimestampInReplay = nop
                _G.GameSafeCallbacks.DoAttackFlowStrategy = nop
                _G.GameSafeCallbacks.GetScriptReportContent = function() return "" end
            end
            if not _G.GameplayCallbacks then return end
            local GC = _G.GameplayCallbacks
            local origDS = GC.OnDSPlayerStateChanged
            GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
                local state = InPlayerState and string.lower(tostring(InPlayerState)) or ""
                local block = {
                    ["cheatdetected"]=true,
                    ["connectionlost"]=true,
                    ["connectiontimeout"]=true,
                    ["connectionexception"]=true,
                    ["netdrivererror"]=true
                }
                if block[state] then return end
                if origDS then pcall(origDS, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
            end
            GC.OnPlayerNetConnectionClosed = nop
            GC.OnPlayerActorChannelError = nop
            GC.OnPlayerRPCValidateFailed = nop
            GC.OnPlayerSpectateException = nop
            GC.OnShutdownAfterError = nop
        end)

        -- SubsystemMgr extra patches
        pcall(function()
            local mgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            local rt = mgr and mgr:Get("RescueBtnReplayTraceSubsystem")
            if rt then
                rt.ReportTrace = nop
                rt.StartTickMonitor = nop
                rt.TickMonitorCheck = nop
                rt.ReportTickMonitorHeartbeat = nop
            end
            local gr = mgr and mgr:Get("GameReportSubsystem")
            if gr then
                gr.ReplayReportData = retFalse
                gr.CheckCanBugglyPostException = retFalse
                gr.BugglyPostExceptionFull = retFalse
                gr.GetClientReplayDataReporter = function() return nil end
                if gr.Reporter then
                    gr.Reporter.ReportIntArrayData = nop
                    gr.Reporter.ReportUInt8ArrayData = nop
                    gr.Reporter.ReportFloatArrayData = nop
                end
            end
            local rp = safe_require("client.slua.logic.replay.logic_report_replay")
            if rp then
                rp.ReportReplay = nop
                rp.SendReportReq = nop
            end
        end)
    end)
end

-- Persistent hunt timer (same as original)
local function HuntAndKillAll()
    pcall(function()
        local subNames = {
            "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem","ClientReportPlayerSubsystem",
            "DSReportPlayerSubsystem","ClientGlueHiaSystem","ClientDataStatistcsSubsystem",
            "ICTLogSubsystem","DSFightTLogSubsystem","DSSecurityTLogSubsystem","AFKReportorSubsystem",
            "BehaviorScoreSubsystem"
        }
        local subMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subMgr and subMgr.Get then
            for _, name in ipairs(subNames) do
                local sub = subMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Tick") or k:find("Log")) then
                            pcall(function() sub[k] = nop end)
                        end
                    end
                end
            end
        end
        -- Higgs again
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local methods = {
                "ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck","StartAvatarCheck",
                "ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar",
                "ClientReportNetAvatar","SendHisarData","ValidateSecurityData"
            }
            for _, m in ipairs(methods) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
        end
        -- Clean memory flags periodically
        CleanMemoryFlags()
    end)
end

local function StartPersistentHuntTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        if _G._MergedHuntTimer then
            pcall(function() pc:RemoveGameTimer(_G._MergedHuntTimer) end)
        end
        _G._MergedHuntTimer = pc:AddGameTimer(3.0, true, HuntAndKillAll)
        return true
    end
    return false
end

-- UPGRADE: Start the deep patrol timer (every 5 seconds)
local function StartDeepPatrol()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(5.0, true, DeepHuntAndNop)
    end
end

function EnableFullBypass()
    InitAllBypasses()
    StartPersistentHuntTimer()
    StartDeepPatrol()
end

-- ==================== END OF BYPASS MODULE ====================

-- ==================== PUBLIC API (preserved) ====================
function _G.GetBypassStatus()
    local state = _G.BYPASS_STATE
    return {
        deadEye = state.DEADEYE_DISABLED,
        hawkEye = state.HAWKEYE_DISABLED,
        voklai = state.VOKLAI_DISABLED,
        higgsBoson = state.HIGGSBOSON_DISABLED,
        hashVerify = state.HASH_VERIFY_DISABLED,
        ipMapping = state.IP_MAPPING_DISABLED,
        memoryPatch = state.MEMORY_PATCH_DISABLED,
        eduEye = state.EDU_EYE_DISABLED,
        fullBypass = state.FULL_BYPASS_ACTIVE
    }
end

function _G.ForceReapplyBypass()
    _G.BYPASS_STATE.FULL_BYPASS_ACTIVE = false
    _G.BYPASS_STATE.DEADEYE_DISABLED = false
    _G.BYPASS_STATE.HAWKEYE_DISABLED = false
    _G.BYPASS_STATE.VOKLAI_DISABLED = false
    _G.BYPASS_STATE.HIGGSBOSON_DISABLED = false
    _G.BYPASS_STATE.HASH_VERIFY_DISABLED = false
    _G.BYPASS_STATE.IP_MAPPING_DISABLED = false
    _G.BYPASS_STATE.MEMORY_PATCH_DISABLED = false
    _G.BYPASS_STATE.EDU_EYE_DISABLED = false
    ApplyAllBypasses()
end

-- ==================== WELCOME POP-UP ON BYPASS ACTIVATION ====================
pcall(function()
    local function ShowWelcomeMessage(title, message)
        -- Method 1: Original game message box
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            pcall(function() Msg = require("client.slua.logic.common.logic_common_msg_box") end)
        end
        if Msg and Msg.Show then
            pcall(function() Msg.Show(4, title, message) end)
            return true
        end
        
        -- Method 2: In-game HUD debug text (fallback)
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if pc and pc:GetHUD() then
            local hud = pc:GetHUD()
            if hud and hud.AddDebugText then
                pcall(function()
                    hud:AddDebugText("🟢 " .. title .. " - " .. message, pc:GetCurPawn(), 1.5, 
                        {X=0, Y=0, Z=130}, {X=0, Y=0, Z=130}, 
                        {R=0, G=255, B=0, A=255}, true, false, true, nil, 6.0, true)
                end)
                return true
            end
        end
        
        -- Method 3: Console log (always works)
        print("[BYPASS]  " .. title .. " ADITYA BYPASS " .. message)
        return false
    end
    
    -- Show only once per match, and only after everything is initialized
    if not _G._WELCOME_MSG_SHOWN then
        _G._WELCOME_MSG_SHOWN = true
        -- Small delay to ensure UI/HUD is ready
        Game:SetTimer(0.5, false, function()
            ShowWelcomeMessage(
                " WELCOME", 
                " COMPLETE BYPASS ACTIVE\n" ..
                " 100% Telemetry Killed\n" ..
                " 12-LAYER ANTI-CHEAT BYPASSED\n" ..
                " Play Safe | Enjoy"
            )
        end)
    end
end)

-- ==================== PER-PLAYER HIGGS & CENTER TEXT (preserved) ====================
local higgs_bypass_attempts = 0
local MAX_HIGGS_BYPASS_ATTEMPTS = 60
local function bypass_higgs_boson_perplayer(player)
    if not player or not isValid(player) then return end
    if higgs_bypass_attempts >= MAX_HIGGS_BYPASS_ATTEMPTS then return end
    pcall(function()
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            Higgs.ControlMHActive = nop
            Higgs.TriggerAvatarCheck = nop
            Higgs.StartAvatarCheck = nop
            Higgs.ReportItemID = nop
            Higgs.OnReportItemID = nop
            Higgs.ReceiveAnyDamage = nop
            Higgs.OnWeaponHitRecord = nop
            Higgs.ShowSecurityAlert = nop
            Higgs.ServerReportAvatar = nop
            Higgs.ClientReportNetAvatar = nop
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
        end
        if _G.AvatarCheckCallback then
            _G.AvatarCheckCallback.StartAvatarCheck = nop
            _G.AvatarCheckCallback.OnReportItemID = nop
        end
    end)
    higgs_bypass_attempts = higgs_bypass_attempts + 1
end

local function hookPerPlayerHiggs()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        local pawn = pc:GetCurPawn()
        if isValid(pawn) then bypass_higgs_boson_perplayer(pawn) end
    end
end

-- AUTO-ACTIVATE BYPASS MONITOR (preserved)
pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not _G.BYPASS_STATE.FULL_BYPASS_ACTIVE then
                pcall(function() ApplyAllBypasses() end)
            end
        end)
    end
end)

-- Center text display (preserved)
if _G._centerTextTimer then
    pcall(function() if _G._centerTextPC and isValid(_G._centerTextPC) then _G._centerTextPC:RemoveGameTimer(_G._centerTextTimer) end end)
    _G._centerTextTimer = nil; _G._centerTextPC = nil
end
local function showCenter()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        local pawn = pc:GetCurPawn()
        if not isValid(pawn) then return end
        local hud = pc:GetHUD()
        if not isValid(hud) then return end
        -- Add custom center text here if desired
    end)
end
local function startCenter()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) then
        _G._centerTextTimer = pc:AddGameTimer(0.5, true, showCenter)
        _G._centerTextPC = pc
    else
        local fb = slua_GameFrontendHUD or Game
        if fb and isValid(fb) then fb:AddGameTimer(1.5, false, startCenter) end
    end
end

local function finalStart()
    if StartPersistentHuntTimer() then
        startCenter()
        hookPerPlayerHiggs()
        StartDeepPatrol()
    else
        local fb = slua_GameFrontendHUD or Game
        if fb and isValid(fb) then fb:AddGameTimer(2.0, false, finalStart) end
    end
end
finalStart()

-- ==================== SKINS ====================
local function sk_safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

local BASE_PATH       = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local CONFIG_PATH     = BASE_PATH .. "config.ini"
local SAVE_KILL_PATH  = BASE_PATH .. "kill_counts.txt"
local ATTACH_PATH     = BASE_PATH .. "attachments.txt"

_G.WeaponSkinMap        = _G.WeaponSkinMap        or {}
_G.VehicleSkinMap       = _G.VehicleSkinMap        or {}
_G.OutfitMap            = _G.OutfitMap             or {}
_G.AttachmentOverrideMap= _G.AttachmentOverrideMap  or {}
_G.SkinAttachments      = _G.SkinAttachments        or {}
_G.SkinLoadedCache      = _G.SkinLoadedCache        or {}
_G.FakeKillCounts       = _G.FakeKillCounts         or {}
_G.LastEquippedOutfits  = _G.LastEquippedOutfits    or {}
_G.g_parts              = _G.g_parts               or {}
_G.skinAttachCache      = _G.skinAttachCache        or {}
_G.KillData             = _G.KillData              or { kills = {} }
_G.DeadBoxSkins         = _G.DeadBoxSkins          or {}
_G.AlreadyChangedSet    = _G.AlreadyChangedSet      or {}
_G.CurrentEquipVehicleID= _G.CurrentEquipVehicleID  or 0

local function SaveKillsToFile()
    pcall(function()
        local file = io.open(SAVE_KILL_PATH, "w")
        if file then
            for id, count in pairs(_G.KillData.kills) do
                file:write(string.format("%d:%d\n", id, count))
            end
            file:close()
        end
    end)
end

local function LoadKillsFromFile()
    pcall(function()
        local file = io.open(SAVE_KILL_PATH, "r")
        if file then
            for line in file:lines() do
                local id, count = line:match("(%d+):(%d+)")
                if id and count then
                    _G.KillData.kills[tonumber(id)] = tonumber(count)
                end
            end
            file:close()
        end
    end)
end

_G.getKills = function(weaponID) return _G.KillData.kills[weaponID] or 0 end

_G.AddKill = function(weaponID)
    if not weaponID then return end
    _G.KillData.kills[weaponID] = (_G.KillData.kills[weaponID] or 0) + 1
    -- UPGRADE: cap displayed kills to avoid suspicion
    if _G.KillData.kills[weaponID] > 3 then
        _G.KillData.kills[weaponID] = math.random(1, 3)
    end
    _G._KillSaveDirty = (_G._KillSaveDirty or 0) + 1
    if _G._KillSaveDirty >= 3 then
        SaveKillsToFile()
        _G._KillSaveDirty = 0
    end
    pcall(function()
        local UIM = require("client.slua_ui_framework.manager")
        local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
        if MKC then
            if MKC.OnRefreshData then
                MKC:OnRefreshData()
            end
            if MKC.KillCounterItem and MKC.KillCounterItem.SetKillCounterItemShowWithNum then
                local sid = _G.get_skin_id(weaponID) or weaponID
                MKC.KillCounterItem:SetKillCounterItemShowWithNum(sid, _G.KillData.kills[weaponID], sid)
            end
        end
    end)
end

LoadKillsFromFile()

_G.get_skin_id = function(weaponID)
    if not weaponID or weaponID == 0 then return nil end
    local mapped = _G.WeaponSkinMap[weaponID]
    if mapped and mapped > 0 then return mapped end
    return nil
end

_G.download_item = function(i)
    if not i then return end
    pcall(function()
        local PM = require("client.slua.logic.download.puffer.puffer_manager")
        local PC = require("client.slua.logic.download.puffer_const")
        if PM.GetState(PC.ENUM_DownloadType.ODPAK, {i}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPAK, {i})
        end
    end)
end

local ATTACH_NAME_MAP = {
    ["Red Dot Sight"]          = "RedDot",
    ["Holographic Sight"]      = "Holo",
    ["2x Scope"]               = "Scope2x",
    ["3x Scope"]               = "Scope3x",
    ["4x Scope"]               = "Scope4x",
    ["6x Scope"]               = "Scope6x",
    ["8x Scope"]               = "Scope8x",
    ["Canted Sight"]           = "CantedSight",
    ["Flash Hider"]            = "FlashHider",
    ["Compensator"]            = "Compensator",
    ["Suppressor"]             = "Suppressor",
    ["Extended Mag"]           = "ExtMag",
    ["Quickdraw Mag"]          = "QuickMag",
    ["Extended Quickdraw Mag"] = "ExtQuickMag",
    ["Angled Foregrip"]        = "AngledGrip",
    ["Vertical Foregrip"]      = "VerticalGrip",
    ["Thumb Grip"]             = "ThumbGrip",
    ["Half Grip"]              = "HalfGrip",
    ["Light Grip"]             = "LightGrip",
    ["Laser Sight"]            = "LaserSight",
    ["Tactical Stock"]         = "TactStock",
    ["Stock"]                  = "MicroStock",
    ["Cheek Pad"]              = "CheekPad",
}

local _attachFileCache = nil

local function _parseAttachmentsFile()
    local result = {}
    pcall(function()
        local f = io.open(ATTACH_PATH, "r")
        if not f then return end
        local content = f:read("*all")
        f:close()
        local curSkin = nil
        for line in content:gmatch("[^\r\n]+") do
            local firstNum = line:match("^(%d+)%s*|")
            if firstNum then
                local num = tonumber(firstNum)
                if num and num > 1100000000 then
                    curSkin = num
                    result[curSkin] = result[curSkin] or {}
                elseif num and curSkin then
                    local attachName = line:match("^%d+%s*|%s*%x+%s*|%s*(.-)%s*$")
                    if not attachName then attachName = line:match("^%d+%s*|%s*(.-)%s*$") end
                    if attachName and attachName ~= "" then
                        local key = ATTACH_NAME_MAP[attachName]
                        if key then result[curSkin][key] = num end
                    end
                end
            elseif line:find("^#%-%-%-%-") and line:find("skin") then
                curSkin = nil
            end
        end
    end)
    return result
end

_G.GetAttachForSkin = function(skinId, key)
    if not skinId or skinId == 0 or not key then return nil end
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    local t = _attachFileCache[skinId]
    if not t then return nil end
    local v = t[key]
    return (v and v > 0) and v or nil
end

_G.GetAttachFileCache = function()
    if not _attachFileCache then _attachFileCache = _parseAttachmentsFile() end
    return _attachFileCache
end

local function ReadLiveConfig()
    pcall(function()
        local f = io.open(CONFIG_PATH, "r")
        if not f then return end
        local content = f:read("*all")
        f:close()
        for line in content:gmatch("[^\r\n]+") do
            local k, v = line:match("^([^#=]+)=(.+)$")
            if k and v then
                k = k:gsub("^%s+", ""):gsub("%s+$", "")
                if k == "cheats" then
                    _G.CheatsEnabled = (v == "1" or v:lower() == "on" or v:lower() == "true")
                end
                local val = tonumber(v)
                if val then
                    if     k == "Suit"      then _G.OutfitMap.Suit      = val
                    elseif k == "Hat"       then _G.OutfitMap.Hat       = val
                    elseif k == "Mask"      then _G.OutfitMap.Mask      = val
                    elseif k == "Glasses"   then _G.OutfitMap.Glasses   = val
                    elseif k == "Pants"     then _G.OutfitMap.Pants     = val
                    elseif k == "Shoes"     then _G.OutfitMap.Shoes     = val
                    elseif k == "Bag"       then _G.OutfitMap.Bag       = val
                    elseif k == "Helmet"    then _G.OutfitMap.Helmet    = val
                    elseif k == "Armor"     then _G.OutfitMap.Armor     = val
                    elseif k == "Parachute" then _G.OutfitMap.Parachute = val
                    elseif k == "Pet"       then _G.OutfitMap.Pet       = val
                    elseif k == "M416"    then _G.WeaponSkinMap[101004] = val
                    elseif k == "AKM"     then _G.WeaponSkinMap[101001] = val
                    elseif k == "SCAR"    then _G.WeaponSkinMap[101003] = val
                    elseif k == "UMP"     then _G.WeaponSkinMap[102002] = val
                    elseif k == "M762"    then _G.WeaponSkinMap[101008] = val
                    elseif k == "AUG"     then _G.WeaponSkinMap[101006] = val
                    elseif k == "ASM"     then _G.WeaponSkinMap[101101] = val
                    elseif k == "ACE32"   then _G.WeaponSkinMap[101102] = val
                    elseif k == "HoneyBadger" then _G.WeaponSkinMap[101012] = val
                    elseif k == "M24"     then _G.WeaponSkinMap[103002] = val
                    elseif k == "AWM"     then _G.WeaponSkinMap[103003] = val
                    elseif k == "Kar98"   then _G.WeaponSkinMap[103001] = val
                    elseif k == "M16A4"   then _G.WeaponSkinMap[101002] = val
                    elseif k == "GROZA"   then _G.WeaponSkinMap[101005] = val
                    elseif k == "QBZ"     then _G.WeaponSkinMap[101007] = val
                    elseif k == "MK47"    then _G.WeaponSkinMap[101009] = val
                    elseif k == "G36C"    then _G.WeaponSkinMap[101010] = val
                    elseif k == "FAMAS"   then _G.WeaponSkinMap[101100] = val
                    elseif k == "VSS"     then _G.WeaponSkinMap[103005] = val
                    elseif k == "Mini14"  then _G.WeaponSkinMap[103006] = val
                    elseif k == "MK14"    then _G.WeaponSkinMap[103007] = val
                    elseif k == "SLR"     then _G.WeaponSkinMap[103009] = val
                    elseif k == "QBU"     then _G.WeaponSkinMap[103010] = val
                    elseif k == "MK12"    then _G.WeaponSkinMap[103100] = val
                    elseif k == "AMR"     then _G.WeaponSkinMap[103012] = val
                    elseif k == "DSR"     then _G.WeaponSkinMap[103102] = val
                    elseif k == "Mosin"   then _G.WeaponSkinMap[103013] = val
                    elseif k == "SKS"     then _G.WeaponSkinMap[103004] = val
                    elseif k == "UZI"     then _G.WeaponSkinMap[102001] = val
                    elseif k == "Vector"  then _G.WeaponSkinMap[102003] = val
                    elseif k == "Thompson"then _G.WeaponSkinMap[102004] = val
                    elseif k == "Bizon"   then _G.WeaponSkinMap[102005] = val
                    elseif k == "MP5K"    then _G.WeaponSkinMap[102007] = val
                    elseif k == "P90"     then _G.WeaponSkinMap[102105] = val
                    elseif k == "S12K"    then _G.WeaponSkinMap[104003] = val
                    elseif k == "DBS"     then _G.WeaponSkinMap[104004] = val
                    elseif k == "S1897"   then _G.WeaponSkinMap[104001] = val
                    elseif k == "S686"    then _G.WeaponSkinMap[104002] = val
                    elseif k == "M249"    then _G.WeaponSkinMap[105001] = val
                    elseif k == "DP28"    then _G.WeaponSkinMap[105002] = val
                    elseif k == "MG3"     then _G.WeaponSkinMap[105010] = val
                    elseif k == "Pan"     then _G.WeaponSkinMap[108004] = val
                    elseif k == "Machete" then _G.WeaponSkinMap[108001] = val
                    elseif k == "Crowbar" then _G.WeaponSkinMap[108002] = val
                    elseif k == "Sickle"  then _G.WeaponSkinMap[108003] = val
                    -- Vehicle skins (kept from original)
                    elseif k == "Motorcycle_1901001"              then _G.VehicleSkinMap[1901001] = val
                    elseif k == "Vehicle_1901002"                 then _G.VehicleSkinMap[1901002] = val
                    elseif k == "Sidecar_Motorcycle_1902001"      then _G.VehicleSkinMap[1902001] = val
                    elseif k == "Dacia_1903001"                   then _G.VehicleSkinMap[1903001] = val
                    elseif k == "Dacia_1903002"                   then _G.VehicleSkinMap[1903002] = val
                    elseif k == "Dacia_1903003"                   then _G.VehicleSkinMap[1903003] = val
                    elseif k == "dacia_1903004"                   then _G.VehicleSkinMap[1903004] = val
                    elseif k == "Mini_Bus_1904001"                then _G.VehicleSkinMap[1904001] = val
                    elseif k == "MiniBus_1904002"                 then _G.VehicleSkinMap[1904002] = val
                    elseif k == "MiniBus_1904003"                 then _G.VehicleSkinMap[1904003] = val
                    elseif k == "Pickup_(Open_Top)_1905001"       then _G.VehicleSkinMap[1905001] = val
                    elseif k == "Pickup_(Closed_Top)_1906001"     then _G.VehicleSkinMap[1906001] = val
                    elseif k == "PickUp_1906005"                  then _G.VehicleSkinMap[1906005] = val
                    elseif k == "Buggy_1907001"                   then _G.VehicleSkinMap[1907001] = val
                    elseif k == "buggy_1907002"                   then _G.VehicleSkinMap[1907002] = val
                    elseif k == "buggy_1907003"                   then _G.VehicleSkinMap[1907003] = val
                    elseif k == "UAZ_1908001"                     then _G.VehicleSkinMap[1908001] = val
                    elseif k == "UAZ_(Closed_Top)_1909001"        then _G.VehicleSkinMap[1909001] = val
                    elseif k == "UAZ_(Open_Top)_1910001"          then _G.VehicleSkinMap[1910001] = val
                    elseif k == "PG-117_1911001"                  then _G.VehicleSkinMap[1911001] = val
                    elseif k == "Jet_Ski_1912001"                 then _G.VehicleSkinMap[1912001] = val
                    elseif k == "Mirado_(Closed_Top)_1914001"     then _G.VehicleSkinMap[1914001] = val
                    elseif k == "Mirado_(Open_Top)_1915001"       then _G.VehicleSkinMap[1915001] = val
                    elseif k == "Mirado_(Open_Top)_1915004"       then _G.VehicleSkinMap[1915004] = val
                    elseif k == "Rony_1916001"                    then _G.VehicleSkinMap[1916001] = val
                    elseif k == "Rony_1916002"                    then _G.VehicleSkinMap[1916002] = val
                    elseif k == "Rony_1916003"                    then _G.VehicleSkinMap[1916003] = val
                    elseif k == "Scooter_1917001"                 then _G.VehicleSkinMap[1917001] = val
                    elseif k == "Scooter_1917002"                 then _G.VehicleSkinMap[1917002] = val
                    elseif k == "Snowmobile_1918001"              then _G.VehicleSkinMap[1918001] = val
                    elseif k == "Tukshai_1919001"                 then _G.VehicleSkinMap[1919001] = val
                    elseif k == "Monster_Truck_1953001"           then _G.VehicleSkinMap[1953001] = val
                    elseif k == "Monster_Truck_1953002"           then _G.VehicleSkinMap[1953002] = val
                    elseif k == "Motor_Glider_1960001"            then _G.VehicleSkinMap[1960001] = val
                    elseif k == "Coupe_RB_1961001"                then _G.VehicleSkinMap[1961001] = val
                    elseif k == "Tank_1963001"                    then _G.VehicleSkinMap[1963001] = val
                    elseif k == "Mountain_Bike_1965001"           then _G.VehicleSkinMap[1965001] = val
                    elseif k == "UTV_(Utility_Task_Vehicle)_1966001" then _G.VehicleSkinMap[1966001] = val
                    elseif k == "2-Seat_Bike_1967001"             then _G.VehicleSkinMap[1967001] = val
                    elseif k == "Horse_1987001"                   then _G.VehicleSkinMap[1987001] = val
                    elseif k == "Hovercraft_1988001"              then _G.VehicleSkinMap[1988001] = val
                    elseif k == "Infected_Grizzly_Dacia_1903024"  then _G.VehicleSkinMap[1903024] = val
                    elseif k == "Anniversary_Celebration_Dacia_1903040" then _G.VehicleSkinMap[1903040] = val
                    end
                end
            end
        end
    end)
end
_G.ReadLiveConfig = ReadLiveConfig

local rawGetTableData     = CDataTable and CDataTable.GetTableData     or function() return nil end
local rawGetTableByFilter = CDataTable and CDataTable.GetTableByFilter or function() return nil end

_G.InjectWeaponLogicHooks = function(pawn)
    if not isValid(pawn) then return end
    if _G.__WeaponLogicHookInjected then return end
    _G.__WeaponLogicHookInjected = true
    pcall(function()
        local wm = pawn:GetWeaponManager()
        if not isValid(wm) then return end
        local old_GetEquipID = wm.GetEquipWeaponAvatarID
        if old_GetEquipID then
            wm.GetEquipWeaponAvatarID = function(self, weaponID)
                local forced = _G.get_skin_id(weaponID)
                if forced then return forced end
                return old_GetEquipID(self, weaponID)
            end
        end
        local old_GetWeaponAvatarID = wm.GetWeaponAvatarID
        if old_GetWeaponAvatarID then
            wm.GetWeaponAvatarID = function(self, weapon)
                if isValid(weapon) then
                    local forced = _G.get_skin_id(weapon:GetWeaponID())
                    if forced then return forced end
                end
                return old_GetWeaponAvatarID(self, weapon)
            end
        end
    end)
end

_G.ForceSyncWeaponSkins = function(pawn)
    local wm = pawn:GetWeaponManager()
    if not isValid(wm) then return end
    for i = 1, 3 do
        local wpn = wm:GetInventoryWeaponByPropSlot(i)
        if isValid(wpn) then
            local targetID = _G.get_skin_id(wpn:GetWeaponID())
            if targetID and targetID > 0 then
                pcall(function()
                    if wpn.synData then
                        local data = wpn.synData:Get(7)
                        if data and data.defineID and data.defineID.TypeSpecificID ~= targetID then
                            data.defineID.TypeSpecificID = targetID
                            wpn.synData:Set(7, data)
                            if wpn.OnWeaponSkinUpdate then wpn:OnWeaponSkinUpdate() end
                        end
                    end
                    if wpn.SetWeaponAvatarID then wpn:SetWeaponAvatarID(targetID) end
                end)
            end
        end
    end
end

_G.ApplyWeaponSkins = function(pawn)
    if not isValid(pawn) then return end
    _G.InjectWeaponLogicHooks(pawn)
    _G.ForceSyncWeaponSkins(pawn)
end

if not _G.AKTableHacked and CDataTable then
    local _old = CDataTable.GetTableData
    CDataTable.GetTableData = function(tableName, id)
        local numId = tonumber(id)
        if numId then
            local upgradeID = _G.get_skin_id(numId)
            if upgradeID and upgradeID ~= numId then
                if tableName == "WeaponAvatarBattleEffect"
                or tableName == "GoldClothBattleEffect"
                or tableName == "WeaponSkinVoiceCfg"
                or tableName == "AvatarWeaponHitFXData" then
                    return _old(tableName, upgradeID)
                end
            end
        end
        return _old(tableName, id)
    end
    _G.AKTableHacked = true
end

_G.muzzles = {
    id_flash_hider = { 201010, 201005, 201004 },
    id_compensator = { 201009, 201003, 201002 },
    id_suppressor  = { 201011, 201006, 201007 }
}
_G.foregrips = {
    id_Angledforegrip = 202001,
    id_thumb_grip     = 202006,
    id_vertical_grip  = 202002,
    id_light_grip     = 202004,
    id_half_grip      = 202005,
    id_ergonomic_grip = 202051,
    id_laser_sight    = 202007
}
_G.magazines = {
    id_expanded_mag       = { 204011, 204007, 204004 },
    id_quick_mag          = { 204012, 204008, 204005 },
    id_expanded_quick_mag = { 204013, 204009, 204006 }
}
_G.scopes = {
    id_reddot = 203001,
    id_holo   = 203002,
    id_2x     = 203003,
    id_3x     = 203014,
    id_4x     = 203004,
    id_6x     = 203015,
    id_8x     = 203005
}
_G.stock = {
    id_microStock = 205001,
    id_tactical   = 205002,
    id_bulletloop = 204014,
    id_CheekPad   = 205003
}

_G.ItemUpgradeSystem = nil
pcall(function()
    local MM  = require("client.module_framework.ModuleManager")
    local IUS = MM.GetModule(MM.CommonModuleConfig.ItemUpgradeManager)
    if IUS then
        IUS:DefineAndResetData()
        IUS:OnInitialize()
        _G.ItemUpgradeSystem = IUS
    end
end)

_G.get_group_id = function(itemId)
    if not _G.ItemUpgradeSystem or not itemId then return nil end
    local cfg = _G.ItemUpgradeSystem:GetUpgradeCfg(itemId)
    return cfg and cfg.GroupID or nil
end

_G.InitParts = function(groupId, itemId)
    if not itemId then return _G.g_parts end
    if _G.g_parts[itemId] and next(_G.g_parts[itemId]) then return _G.g_parts end
    _G.g_parts[itemId] = {}
    if not _G.ItemUpgradeSystem then return _G.g_parts end
    if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
        groupId = _G.ItemUpgradeSystem:GetNormalGroupID(groupId or _G.get_group_id(itemId))
    else
        groupId = groupId or _G.get_group_id(itemId)
    end
    if not groupId then return _G.g_parts end
    local cfg = rawGetTableByFilter("ItemUpgradeUnLockConfig", "GroupID", groupId)
    if cfg then
        for _, info in pairs(cfg) do
            local partId = info.PartId
            if _G.ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                local switched = _G.ItemUpgradeSystem:PartIDSwitch(partId, true)
                if switched and switched ~= partId then partId = switched end
            end
            local item = rawGetTableData("Item", partId)
            if item and item.ItemName then
                _G.g_parts[itemId][item.ItemName] = partId
            end
        end
    end
    return _G.g_parts
end

_G.GetRawAttachMap = function(skinid)
    if not skinid or skinid <= 0 then return {} end
    if _G.skinAttachCache[skinid] then return _G.skinAttachCache[skinid] end
    local UAvatarUtils = import("AvatarUtils")
    if not UAvatarUtils then return {} end
    local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(skinid, {}, false) or {}
    _G.skinAttachCache[skinid] = list
    return list
end

_G.GetSlotFromSkinID = function(skinid, slot)
    if not skinid or not slot then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local attachmentTypeMap = {
        [1] = {291004,291102,291001,291006,291005,291002,293003,293004,293009,293007,293005,293006,295001,295002,291007,291003,292002,292003,291011,291008},
        [2] = {205005,205102,205007,205009,205006},
        [3] = {203008,203009,203006,203022,203010}
    }
    local targetIDs = attachmentTypeMap[slot]
    if not targetIDs then return 0 end
    for _, targetID in ipairs(targetIDs) do
        for attachID, attachSkinID in pairs(list) do
            if attachID == targetID then return attachSkinID end
        end
    end
    return 0
end

_G.AutoDetectAttach = function(skinid, base_id)
    if not skinid or not base_id then return 0 end
    local list = _G.GetRawAttachMap(skinid)
    local v = list[base_id]
    return (v and v > 0) and v or 0
end

_G.get_muzzleid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.muzzles[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_flash_hider") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "FlashHider")
                  or (p and p["Flash Hider"])
                  or (auto > 0 and auto)
                  or current_id
    elseif is_in("id_compensator") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Compensator")
                  or (p and p["Compensator"])
                  or (auto > 0 and auto)
                  or current_id
    elseif is_in("id_suppressor") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Suppressor")
                  or (p and p["Suppressor"])
                  or (auto > 0 and auto)
                  or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_forgripid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.foregrips.id_Angledforegrip then
        current_id = _G.GetAttachForSkin(avatarid, "AngledGrip") or (p and p["Angled Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_thumb_grip then
        current_id = _G.GetAttachForSkin(avatarid, "ThumbGrip") or (p and p["Thumb Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_vertical_grip then
        current_id = _G.GetAttachForSkin(avatarid, "VerticalGrip") or (p and p["Vertical Foregrip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_light_grip then
        current_id = _G.GetAttachForSkin(avatarid, "LightGrip") or (p and p["Light Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_half_grip then
        current_id = _G.GetAttachForSkin(avatarid, "HalfGrip") or (p and p["Half Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_ergonomic_grip then
        current_id = (p and p["Ergonomic Grip"]) or (auto > 0 and auto) or current_id
    elseif current_id == _G.foregrips.id_laser_sight then
        current_id = _G.GetAttachForSkin(avatarid, "LaserSight") or (p and p["Laser Sight"]) or (auto > 0 and auto) or current_id
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_magazinesid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local function is_in(t)
        for _, id in ipairs(_G.magazines[t]) do if current_id == id then return true end end
        return false
    end
    if is_in("id_expanded_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtMag") or (p and p["Extended Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "QuickMag") or (p and p["Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    elseif is_in("id_expanded_quick_mag") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "ExtQuickMag") or (p and p["Extended Quickdraw Mag"]) or _G.GetSlotFromSkinID(avatarid, 1) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 1)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_scopeid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.scopes.id_reddot then
        current_id = _G.GetAttachForSkin(avatarid, "RedDot") or (p and p["Red Dot Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_holo then
        current_id = _G.GetAttachForSkin(avatarid, "Holo") or (p and p["Holographic Sight"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_2x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope2x") or (p and p["2x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_3x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope3x") or (p and p["3x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_4x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope4x") or (p and p["4x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_6x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope6x") or (p and p["6x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    elseif current_id == _G.scopes.id_8x then
        current_id = _G.GetAttachForSkin(avatarid, "Scope8x") or (p and p["8x Scope"]) or _G.GetSlotFromSkinID(avatarid, 3) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 3)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.get_stockid = function(current_id, avatarid)
    local initial_id = current_id
    _G.InitParts(_G.get_group_id(avatarid), avatarid)
    local p = _G.g_parts[avatarid]
    local auto = _G.AutoDetectAttach(avatarid, current_id)
    if current_id == _G.stock.id_microStock then
        current_id = _G.GetAttachForSkin(avatarid, "MicroStock") or (p and p["Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_tactical then
        current_id = _G.GetAttachForSkin(avatarid, "TactStock") or (p and p["Tactical Stock"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_bulletloop then
        current_id = (p and p["Bullet Loop"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    elseif current_id == _G.stock.id_CheekPad then
        current_id = _G.GetAttachForSkin(avatarid, "CheekPad") or (p and p["Cheek Pad"]) or _G.GetSlotFromSkinID(avatarid, 2) or (auto > 0 and auto) or current_id
    else
        local fb = _G.GetSlotFromSkinID(avatarid, 2)
        if fb and fb > 0 then current_id = fb end
    end
    return current_id, (initial_id ~= current_id)
end

_G.apply_attachment = function(CurWeapon, avatarid)
    local array = CurWeapon.synData
    for AttachIdx = 0, 4 do
        local Data = array:Get(AttachIdx)
        local itemid = slua.IndexReference(Data, "defineID").TypeSpecificID
        if itemid and itemid > 0 and itemid < 10000000 then
            local isrefresh = false
            if AttachIdx == 0 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_muzzleid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 1 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_forgripid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 2 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_magazinesid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 3 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_stockid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            elseif AttachIdx == 4 then
                Data.defineID.TypeSpecificID, isrefresh = _G.get_scopeid(slua.IndexReference(Data, "defineID").TypeSpecificID, avatarid)
                array:Set(AttachIdx, Data)
            else
                break
            end
            if isrefresh then
                _G.download_item(slua.IndexReference(Data, "defineID").TypeSpecificID)
                CurWeapon:DelayHandleAvatarMeshChanged()
            end
        end
    end
end

local WEAPON_NAMES = {
    "AKM","M16A4","SCAR","M416","GROZA","AUG","QBZ","M762",
    "MK47","G36C","HoneyBadger","ASM","FAMAS","ACE32",
    "UZI","UMP","Vector","Bizon","Thompson","MP5K","P90",
    "Kar98","M24","AWM","SKS","Mini14","MK14","SLR","QBU","MK12","AMR","DSR","VSS","Mosin",
    "S12K","DBS","S1897","S686",
    "M249","DP28","MG3",
    "Pan","Machete","Crowbar","Sickle",
}
local WEAPON_NAME_TO_ID = {
    AKM=101001,M16A4=101002,SCAR=101003,M416=101004,
    GROZA=101006,AUG=101006,QBZ=101007,M762=101008,
    MK47=101009,G36C=101010,HoneyBadger=101012,ASM=101101,FAMAS=101100,ACE32=101102,
    UZI=102001,UMP=102002,Vector=102003,Bizon=102005,MP5K=102007,P90=102105,
    Kar98=103001,M24=103002,AWM=103003,SKS=103004,VSS=103005,
    Mini14=103006,MK14=103007,SLR=103009,QBU=103010,MK12=103100,AMR=103012,DSR=103102,Mosin=103013,
    S12K=104003,DBS=104004,S1897=104001,S686=104002,
    M249=105001,DP28=105002,MG3=105010,
    Pan=108004,Machete=108001,Crowbar=108002,Sickle=108003,
}

_G.SyncAttachmentsToConfig = function()
    local cache = _G.GetAttachFileCache and _G.GetAttachFileCache()
    if not cache or not next(cache) then return end
    local hasSkin = false
    for _, w in ipairs(WEAPON_NAMES) do
        local baseId = WEAPON_NAME_TO_ID[w]
        if baseId and (_G.WeaponSkinMap[baseId] or 0) > 0 then hasSkin = true; break end
    end
    if not hasSkin then return end
    pcall(function()
        local f = io.open(CONFIG_PATH, "r")
        if not f then return end
        local content = f:read("*all"); f:close()
        local lines = {}
        for line in content:gmatch("[^\r\n]+") do table.insert(lines, line) end
        local filtered = {}
        for _, line in ipairs(lines) do
            local isAuto = false
            for _, w in ipairs(WEAPON_NAMES) do
                if line:find("^" .. w .. "_[%w%-]+=") then isAuto = true; break end
            end
            if not isAuto then table.insert(filtered, line) end
        end
        local ATTACH_TO_CONFIG_KEY = {
            Scope2x = "2x", Scope3x = "3x", Scope4x = "4x", Scope6x = "6x", Scope8x = "8x",
            RedDot = "RedDot", Holo = "Holo", CantedSight = "CantedSight",
            FlashHider = "FlashHider", Compensator = "Compensator", Suppressor = "Suppressor",
            ExtMag = "ExtMag", QuickMag = "QuickMag", ExtQuickMag = "ExtQuickMag",
            AngledGrip = "AngledGrip", ThumbGrip = "ThumbGrip", VerticalGrip = "VerticalGrip",
            LightGrip = "LightGrip", HalfGrip = "HalfGrip", LaserSight = "LaserSight",
            TactStock = "TactStock", MicroStock = "MicroStock", CheekPad = "CheekPad",
        }
        local KEY_ORDER = {
            "RedDot","Holo","CantedSight",
            "Scope2x","Scope3x","Scope4x","Scope6x","Scope8x",
            "FlashHider","Compensator","Suppressor",
            "ExtMag","QuickMag","ExtQuickMag",
            "AngledGrip","ThumbGrip","VerticalGrip","LightGrip","HalfGrip","LaserSight",
            "TactStock","MicroStock","CheekPad",
        }
        local outLines = {}
        table.insert(outLines, "; SyncAttachmentsToConfig ran")
        local foundCount = 0
        for _, line in ipairs(filtered) do
            table.insert(outLines, line)
            local wname, skinStr = line:match("^(%w+)=(%d+)$")
            if wname then
                local baseId = WEAPON_NAME_TO_ID[wname]
                if baseId then
                    local skinId = tonumber(skinStr)
                    if skinId and skinId > 0 then
                        local attaches = cache[skinId]
                        if attaches then
                            for _, key in ipairs(KEY_ORDER) do
                                local id = attaches[key]
                                local ck = ATTACH_TO_CONFIG_KEY[key]
                                if id and ck then
                                    table.insert(outLines, wname .. "_" .. ck .. "=" .. id)
                                    foundCount = foundCount + 1
                                end
                            end
                        else
                            table.insert(outLines, "; No cache entry for skin " .. skinId)
                        end
                    end
                    table.insert(outLines, "")
                end
            end
        end
        outLines[1] = "; SyncAttachmentsToConfig OK - matched " .. foundCount .. " attachments"
        local out = io.open(CONFIG_PATH, "w")
        if out then out:write(table.concat(outLines, "\n"), "\n"); out:close() end
    end)
end

_G.ApplyLocalPlayerSkins = function(p)
    if _G.Mod_Skin_Enabled == false then return end
    if not isValid(p) then return end

    pcall(function()
        local BackpackUtils = import("BackpackUtils")
        local ac = p:getAvatarComponent2()
        if isValid(ac) and ac.NetAvatarData then
            local applyData = ac.NetAvatarData.SlotSyncData
            if isValid(applyData) then
                local ref = false
                for i = 0, applyData:Num() - 1 do
                    local eq = applyData:Get(i)
                    if eq and eq.ItemId ~= 0 then
                        local target = 0
                        if eq.SlotID == 5 and _G.OutfitMap.Suit then
                            target = _G.OutfitMap.Suit
                        elseif eq.SlotID == 8 and _G.OutfitMap.Bag and _G.OutfitMap.Bag ~= 501001 then
                            local bagBase = _G.OutfitMap.Bag
                            local level = 1
                            if BackpackUtils then level = BackpackUtils.GetEquipmentBagLevel(eq.AdditionalItemID) or 1 end
                            target = bagBase + (level - 1) * 1000
                        elseif eq.SlotID == 9 and _G.OutfitMap.Helmet and _G.OutfitMap.Helmet ~= 502001 then
                            local helBase = _G.OutfitMap.Helmet
                            local level = 1
                            if BackpackUtils then level = BackpackUtils.GetEquipmentHelmetLevel(eq.AdditionalItemID) or 1 end
                            target = helBase + (level - 1) * 1000
                        end
                        if target and target ~= 0 and eq.ItemId ~= target then
                            if _G.download_item and not _G.SkinLoadedCache[target] then
                                pcall(_G.download_item, target)
                                _G.SkinLoadedCache[target] = true
                            end
                            eq.ItemId = target
                            applyData:Set(i, eq)
                            ref = true
                        end
                    end
                end
                if ref and ac.OnRep_BodySlotStateChanged then ac:OnRep_BodySlotStateChanged() end
            end
            local extra_keys = {"Hat","Mask","Glasses","Pants","Shoes","Armor","Parachute"}
            for _, key in ipairs(extra_keys) do
                local id = _G.OutfitMap[key]
                if id and id > 0 and _G.LastEquippedOutfits[key] ~= id then
                    if _G.download_item and not _G.SkinLoadedCache[id] then
                        pcall(_G.download_item, id)
                        _G.SkinLoadedCache[id] = true
                    end
                    ac:PutOnCustomEquipmentByID(id, {})
                    _G.LastEquippedOutfits[key] = id
                end
            end
        end
    end)

    _G.ApplyWeaponSkins(p)
    for i = 1, 3 do
        local wpn = p:GetWeaponManager() and p:GetWeaponManager():GetInventoryWeaponByPropSlot(i)
        if isValid(wpn) then
            local target = _G.get_skin_id(wpn:GetWeaponID())
            if target and target > 0 then
                if not _G.SkinLoadedCache[target] then
                    pcall(_G.download_item, target)
                    _G.SkinLoadedCache[target] = true
                end
                if _G.apply_attachment then pcall(_G.apply_attachment, wpn, target) end
            end
        end
    end

    if _G.OutfitMap.Pet and _G.OutfitMap.Pet ~= 0 then
        pcall(function()
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if pc and pc.PetComponent and pc.PetComponent.PetId ~= _G.OutfitMap.Pet then
                pc.PetComponent.PetId = _G.OutfitMap.Pet
                pc.PetComponent:OnRep_PetId()
            end
        end)
    end

    pcall(function()
        local CV = p.CurrentVehicle
        if isValid(CV) then
            local VA = CV.VehicleAvatar
            if isValid(VA) then
                local defId = tostring(VA:GetDefaultAvatarID() or "")
                local currentId = tostring(CV:GetAvatarId() or "")
                local vehTarget = 0
                for baseId, targetSkin in pairs(_G.VehicleSkinMap) do
                    if defId:find(tostring(baseId)) then vehTarget = targetSkin; break end
                end
                if vehTarget and vehTarget > 0 and currentId ~= tostring(vehTarget) then
                    if _G.download_item and not _G.SkinLoadedCache[vehTarget] then
                        pcall(_G.download_item, vehTarget)
                        _G.SkinLoadedCache[vehTarget] = true
                    end
                    VA.curSwitchEffectId = 7303001
                    VA:ChangeItemAvatar(vehTarget, true)
                    _G.CurrentEquipVehicleID = vehTarget
                end
            end
        end
    end)
end

if not table.contains then
    function table.contains(t, el)
        for _, v in ipairs(t) do if v == el then return true end end
        return false
    end
end

local function locationsClose(loc1, loc2, tolerance)
    local dx = loc1.X - loc2.X
    local dy = loc1.Y - loc2.Y
    local dz = loc1.Z - loc2.Z
    return dx*dx + dy*dy + dz*dz < tolerance*tolerance
end

_G.ApplyDeadBoxSkin = function()
    if _G.Mod_Skin_Enabled == false then return end
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if not pc then return end
    local uCharacter = pc:GetPlayerCharacterSafety()
    if not isValid(uCharacter) then return end
    local UGameplayStatics = import("GameplayStatics")
    if not UGameplayStatics then return end
    local uActor = import("Actor")
    if not uActor then return end
    local ok, UIUtil = pcall(require, "client.common.ui_util")
    if not ok or not UIUtil then return end
    local uGameInstance = UIUtil.GetGameInstance()
    if not uGameInstance then return end
    local APlayerTombBox = import("PlayerTombBox")
    if not APlayerTombBox then return end
    local uActorArray = UGameplayStatics.GetAllActorsOfClass(
        uGameInstance, APlayerTombBox,
        slua.Array(UEnums.EPropertyClass.Object, uActor))
    if not uActorArray then return end
    for _, actor in pairs(uActorArray) do
        if isValid(actor) then
            local DamageCauser = actor.DamageCauser
            if DamageCauser and DamageCauser.PlayerKey == pc.PlayerKey then
                local Deadboxavatar = actor.DeadBoxAvatarComponent_BP
                if Deadboxavatar and not table.contains(_G.AlreadyChangedSet, actor) then
                    local actorLocation = actor:K2_GetActorLocation()
                    local found = false
                    for _, entry in pairs(_G.DeadBoxSkins) do
                        if locationsClose(entry.location, actorLocation, 1.0) then
                            Deadboxavatar:ResetItemAvatar()
                            Deadboxavatar:PreChangeItemAvatar(entry.SkinID)
                            Deadboxavatar:SyncChangeItemAvatar(entry.SkinID)
                            table.insert(_G.AlreadyChangedSet, actor)
                            found = true
                            break
                        end
                    end
                    if not found then
                        local ApplySkinID = 0
                        local CV = uCharacter.CurrentVehicle
                        if CV then
                            local carSkinID = _G.CurrentEquipVehicleID
                            if carSkinID ~= 0 then ApplySkinID = tostring(carSkinID) .. "1" end
                        else
                            local cw = uCharacter:GetCurrentWeapon()
                            if cw and cw.synData then
                                ApplySkinID = slua.IndexReference(cw.synData:Get(7), "defineID").TypeSpecificID
                            end
                        end
                        Deadboxavatar:ResetItemAvatar()
                        Deadboxavatar:PreChangeItemAvatar(ApplySkinID)
                        Deadboxavatar:SyncChangeItemAvatar(ApplySkinID)
                        table.insert(_G.DeadBoxSkins, { location = actorLocation, SkinID = ApplySkinID })
                        table.insert(_G.AlreadyChangedSet, actor)
                    end
                end
            end
        end
    end
end

_G.RefreshKillCounterUI = function()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not pc then return end
        local lp = pc:GetPlayerCharacterSafety()
        if not isValid(lp) then return end
        local cw = lp:GetCurrentWeapon()
        if not isValid(cw) then return end
        local wID = cw:GetWeaponID()
        if not wID or wID == 0 then return end
        local sid = _G.get_skin_id(wID)
        if not sid then return end
        local KillCounterUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
        if KillCounterUI and KillCounterUI.__inner_impl then
            KillCounterUI.__inner_impl:CheckNeedMainKillCounterUI(cw, pc.PlayerKey)
        end
        local UIM = require("client.slua_ui_framework.manager")
        local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
        if MKC and MKC.KillCounterItem then
            local kills = _G.getKills(wID)
            -- UPGRADE: cap displayed kills to avoid suspicion
            if kills > 3 then kills = math.random(1, 3) end
            MKC:SetKillCounterItemShowWithNum(sid, kills, sid)
        end
    end)
end

_G.ForceEnableKillCounterUI = function()
    if _G.KCUISystemHacked2 then return end
    pcall(function()
        local KillCounterUI = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"]
                           or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUI and KillCounterUI.__inner_impl then
            local ui = KillCounterUI.__inner_impl
            ui.CheckSupportKCUI = function() return true end
            ui.CheckNeedMainKillCounterUI = function(self, Weapon, PlayerID)
                local pc = slua_GameFrontendHUD:GetPlayerController()
                local cw = isValid(Weapon) and Weapon
                        or (pc and pc:GetPlayerCharacterSafety() and pc:GetPlayerCharacterSafety():GetCurrentWeapon())
                if not isValid(cw) then self:UpdateMainKillCounterUI(false); return end
                local wID = cw:GetWeaponID()
                if not wID or wID == 0 then self:UpdateMainKillCounterUI(false); return end
                self:UpdateMainKillCounterUI(true, wID, _G.get_skin_id(wID) or wID)
            end
            local old_Update = ui.UpdateMainKillCounterUI
            ui.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if not bShow then return old_Update(self, bShow, WeaponID, AvatarID) end
                return old_Update(self, bShow, WeaponID, AvatarID or _G.get_skin_id(WeaponID))
            end
            _G.KCUISystemHacked2 = true
        end
        local MM = require("client.module_framework.ModuleManager")
        if MM then
            local LogicKC = MM.GetModule(MM.CommonModuleConfig.LogicKillCounter)
            if LogicKC and not _G.KCLogicHacked2 then
                LogicKC.CheckSupportKC                = function() return true end
                LogicKC.CheckSupportKillCounterAvatar = function() return true end
                LogicKC.CheckHasWeaponKillCounter     = function() return true end
                LogicKC.GetBaseKillCounterIdByWeaponId= function() return 2100004 end
                LogicKC.GetEquipedKillCounterId        = function() return 2100004 end
                LogicKC.GetMyEquipedKillCounterId      = function() return 2100004 end
                LogicKC.GetOneWeaponKillCountInBattle  = function(_, _, wid) 
                    local kills = _G.getKills(wid)
                    if kills > 3 then kills = math.random(1, 3) end
                    return kills
                end
                LogicKC.GetWeaponKillCountByUid        = function(_, _, wid) 
                    local kills = _G.getKills(wid)
                    if kills > 3 then kills = math.random(1, 3) end
                    return kills
                end
                _G.KCLogicHacked2 = true
            end
        end
        local KillInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[KillInfoPath] or require(KillInfoPath)
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local old_FileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DRD)
                pcall(function()
                    local GD = require("GameLua.GameCore.Data.GameplayData")
                    local lp = GD.GetPlayerCharacter()
                    if isValid(lp) and DRD.Causer == lp:GetPlayerNameSafety() then
                        local cw = lp:GetCurrentWeapon()
                        if isValid(cw) then
                            local wid = cw:GetWeaponID()
                            local sid = _G.get_skin_id(wid)
                            if sid then DRD.CauserWeaponAvatarID = sid end
                            if _G.OutfitMap.Suit then DRD.CauserClothAvatarID = _G.OutfitMap.Suit end
                            DRD.IsUseColor = true
                            DRD.UseColor = import("LinearColor")(1.0, 0.8, 0.0, 1.0)
                            local expand_data = DRD.ExpandDataContent
                            if expand_data then
                                expand_data.KillCounterItemId = sid or wid
                                local kills = _G.getKills(wid)
                                if kills > 3 then kills = math.random(1, 3) end
                                expand_data.KillCounterNum = kills
                            end
                            if DRD.ResultHealthStatus == 2 then
                                _G.AddKill(wid)
                                local UIM = require("client.slua_ui_framework.manager")
                                local MKC = UIM.GetUI(UIM.UI_Config_InGame.MainKillCounter)
                                if MKC and MKC.KillCounterItem then
                                    local kills = _G.getKills(wid)
                                    if kills > 3 then kills = math.random(1, 3) end
                                    MKC:SetKillCounterItemShowWithNum(sid or wid, kills, sid or wid)
                                end
                            end
                        end
                    end
                end)
                if old_FileItem then old_FileItem(self, DRD) end
            end
            _G.KillInfoCounterHacked = true
        end
        local ok2, WIIB = pcall(require, "GameLua.Mod.BaseMod.Client.Backpack.WeaponInfoItemBase")
        if ok2 and WIIB and WIIB.__inner_impl and not _G.WeaponInfoBackpackHacked then
            local o_UWA = WIIB.__inner_impl.UpdateWeaponAppearanceInfo
            if o_UWA then
                WIIB.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
                    local ItemData = rawGetTableData("Item", TypeSpecificID)
                    if not ItemData then return o_UWA(self, TypeSpecificID, BattleData, DragOrigin) end
                    local skin_id = _G.get_skin_id(TypeSpecificID)
                    if not skin_id or not _G.SkinLoadedCache[skin_id] then
                        return o_UWA(self, TypeSpecificID, BattleData, DragOrigin)
                    end
                    o_UWA(self, skin_id, BattleData, DragOrigin)
                    pcall(function()
                        self.TypeSpecificIDTemp = TypeSpecificID
                        self.ItemID             = TypeSpecificID
                        if self.UIRoot then
                            self.UIRoot.ItemID = TypeSpecificID
                            if self.UIRoot.TextBlock_WeaponName and ItemData.ItemName then
                                self.UIRoot.TextBlock_WeaponName:SetText(ItemData.ItemName)
                            end
                        end
                        if self.BindWeaponChangeEvent  then self:BindWeaponChangeEvent()  end
                        if self.UpdateBullet           then self:UpdateBullet()           end
                        if self.UpdateWeaponDurability then self:UpdateWeaponDurability() end
                        if self.UpdateWeaponAttachment then self:UpdateWeaponAttachment() end
                    end)
                end
                _G.WeaponInfoBackpackHacked = true
            end
        end
    end)
end

if not _G.BattleKillBroadcastSkinHacked then
    pcall(function()
        local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
        if not (BattleKillBroadcastSubSystem and BattleKillBroadcastSubSystem.__inner_impl) then return end
        local o_Copy = BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable
        BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
            local msgData = o_Copy(self, messageData)
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local character = pc and pc:GetPlayerCharacterSafety()
                if character and isValid(character) and msgData.bIamCauser and _G.LuaStateWrapper then
                    msgData.bShowBottomBothSidesKillInfo = true
                    local weapon = character:GetCurrentWeapon()
                    if weapon and isValid(weapon) then
                        local weapon_id = weapon:GetItemDefineID() and weapon:GetItemDefineID().TypeSpecificID or 0
                        if weapon_id ~= 0 then
                            local expand_data = slua.LuaArchiverDecode(_G.LuaStateWrapper, msgData.ExpandDataContent) or {}
                            local isClassic = false
                            local uGameState = slua_GameFrontendHUD:GetGameState()
                            if uGameState and isValid(uGameState) then
                                local EGameModeType = import("EGameModeType")
                                if uGameState.GameModeType == EGameModeType.ETypicalGameMode then isClassic = true end
                            end
                            local syn_data = weapon.synData
                            if syn_data and isValid(syn_data) then
                                local define_id = slua.IndexReference(syn_data:Get(7), "defineID")
                                if define_id and isValid(define_id) then
                                    expand_data.CauserWeaponAvatarID = define_id.TypeSpecificID
                                end
                            end
                            if isClassic then
                                expand_data.KillCounterItemId = weapon_id
                                local kills = _G.getKills and _G.getKills(weapon_id) or 0
                                if kills > 3 then kills = math.random(1, 3) end
                                expand_data.KillCounterNum = kills
                            end
                            msgData.bShowKillNum = true
                            msgData.ExpandDataContent = slua.LuaArchiverEncode(_G.LuaStateWrapper, expand_data)
                        end
                    end
                end
            end)
            return msgData
        end
        _G.BattleKillBroadcastSkinHacked = true
    end)
end

ReadLiveConfig()
_G.ForceEnableKillCounterUI()

_G._SetupSkinTimer = function()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not (pc and slua.isValid(pc)) then return end
        if _G.SkinTimerPC == pc then return end
        _G.SkinTimerPC = pc
        _G._SkinTimerInstalled = true
        _G._SkinTickCount = 0
        pc:AddGameTimer(0.5, true, function()
            pcall(function()
                local lpc = slua_GameFrontendHUD:GetPlayerController()
                if not (lpc and slua.isValid(lpc)) then return end
                local pawn = lpc:GetPlayerCharacterSafety()
                if not (pawn and slua.isValid(pawn)) then return end
                _G._SkinTickCount = (_G._SkinTickCount or 0) + 1
                local tick = _G._SkinTickCount
                if tick % 4 == 1 then
                    _G.ReadLiveConfig()
                    _G.SyncAttachmentsToConfig()
                end
                if tick % 10 == 1 then
                    _G.ApplyLocalPlayerSkins(pawn)
                    _G.ApplyDeadBoxSkin()
                end
                _G.RefreshKillCounterUI()
            end)
        end)
    end)
end

_G._SetupSkinTimer()

-- ===================================================================
-- WALLHACK (Enhanced – merged from add.lua)
-- ===================================================================
-- Color mapping for wallhack
local function GetColorByIndex(idx, brightness)
    local b = brightness or 25
    local colors = {
        [1] = {R=b, G=0,   B=0},   -- Red
        [2] = {R=b, G=b,   B=b},   -- White
        [3] = {R=b, G=b,   B=0},   -- Yellow
        [4] = {R=0, G=b,   B=0},   -- Green
        [5] = {R=0, G=b,   B=b},   -- Cyan
        [6] = {R=0, G=0,   B=b},   -- Blue
        [7] = {R=b, G=0,   B=b}    -- Purple
    }
    return colors[idx] or colors[1]
end

-- Enhanced ApplyWallHack (uses ESPConfig)
local function ApplyWallHack(localPlayer, enemy, pc)
    if not _G.Mod_Wallhack_Enabled then return end
    if not slua.isValid(enemy) then return end

    local meshes = {}
    pcall(function()
        if slua.isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if slua.isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)

    pcall(function()
        for _, comp in ipairs(meshes) do
            if slua.isValid(comp) then
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and slua.isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and slua.isValid(base) then
                        base.bDisableDepthTest = true
                        base.BlendMode = 2
                    end
                end
                comp.UseScopeDistanceCulling = false
                comp.PrimitiveShadingStrategy = 1
                comp.ShadingRate = 6
            end
        end

        local isVisible = false
        if slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
            pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
        end

        local brightness = _G.ESPConfig.WallhackBrightness or 25
        local colorIdx = isVisible and _G.ESPConfig.WallhackVisibleColor or _G.ESPConfig.WallhackInvisibleColor
        colorIdx = colorIdx or 1
        local finalColor = GetColorByIndex(colorIdx, brightness)
        local glow = _G.ESPConfig.WallhackGlow or 3.0
        local scale = {R=glow, G=glow, B=0, A=0}

        enemy._WH_MIDs = enemy._WH_MIDs or {}
        for _, comp in ipairs(meshes) do
            if slua.isValid(comp) then
                local ck = tostring(comp)
                enemy._WH_MIDs[ck] = enemy._WH_MIDs[ck] or {}
                for i = 0, 10 do
                    local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                    if not ok3 or not slua.isValid(mi) then break end
                    local mid = enemy._WH_MIDs[ck][i]
                    if not slua.isValid(mid) then
                        local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                        if ok4 and slua.isValid(nm) then enemy._WH_MIDs[ck][i] = nm; mid = nm end
                    end
                    if slua.isValid(mid) then
                        pcall(function()
                            mid:SetVectorParameterValue("颜色", finalColor)
                            mid:SetVectorParameterValue("Color", finalColor)
                            mid:SetVectorParameterValue("BaseColor", finalColor)
                            mid:SetVectorParameterValue("BodyColor", finalColor)
                            mid:SetVectorParameterValue("DiffuseColor", finalColor)
                            mid:SetVectorParameterValue("EmissiveColor", finalColor)
                            mid:SetVectorParameterValue("ParaScaleOffset", scale)
                            mid:SetVectorParameterValue("Para_Color", finalColor)
                            mid:SetVectorParameterValue("Para_ColorTint", finalColor)
                            mid:SetVectorParameterValue("Tint", finalColor)
                            mid:SetVectorParameterValue("MainColor", finalColor)
                            mid:SetVectorParameterValue("Extra Light Color", finalColor)
                            mid:SetVectorParameterValue("颜色_1", finalColor)
                        end)
                    end
                end
            end
        end
    end)
end

-- ===================================================================
-- SCENE CONTROLS (from add.lua)
-- ===================================================================
local function GetGameInstance()
    if slua_GameFrontendHUD then
        return slua_GameFrontendHUD:GetGameInstance()
    end
    local SettingUtil = safe_require("client.slua.logic.setting.setting_util")
    if SettingUtil and SettingUtil.GetGameInstance then
        return SettingUtil:GetGameInstance()
    end
    return nil
end

local function ExecuteConsoleCommand(cmd, value)
    local instance = GetGameInstance()
    if instance then
        pcall(function() instance:ExecuteCMD(cmd, value) end)
    end
end

function SetRainEnabled(enabled)
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if slua.isValid(char) then
            local EScreenParticleEffectType = import("EScreenParticleEffectType")
            if EScreenParticleEffectType then
                if char.SetRainyEffectEnable then
                    char:SetRainyEffectEnable(
                        EScreenParticleEffectType.ESPET_Rainy,
                        enabled,
                        enabled and 500 or 0
                    )
                end
            end
        end
        local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local weather = SubsystemMgr:Get("CreativeModeWeatherSubsystem")
            if slua.isValid(weather) then
                if enabled then
                    if weather.StartRainScreenEffect then weather:StartRainScreenEffect() end
                else
                    if weather.StopRainScreenEffect then weather:StopRainScreenEffect() end
                end
            end
        end
    end)
end

function SetSnowEnabled(enabled)
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if slua.isValid(char) then
            local EScreenParticleEffectType = import("EScreenParticleEffectType")
            if EScreenParticleEffectType then
                if char.SetRainyEffectEnable then
                    char:SetRainyEffectEnable(
                        EScreenParticleEffectType.ESPET_Snowy,
                        enabled,
                        enabled and 500 or 0
                    )
                end
            end
        end
        local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local weather = SubsystemMgr:Get("CreativeModeWeatherSubsystem")
            if slua.isValid(weather) then
                if enabled then
                    if weather.StartSnowScreenEffect then weather:StartSnowScreenEffect()
                    elseif weather.StartRainScreenEffect then weather:StartRainScreenEffect() end
                else
                    if weather.StopSnowScreenEffect then weather:StopSnowScreenEffect()
                    elseif weather.StopRainScreenEffect then weather:StopRainScreenEffect() end
                end
            end
        end
    end)
end

function SetBlackSky(enabled)
    ExecuteConsoleCommand("r.CylinderMaxDrawHeight", enabled and "9999" or "0")
end

function SetFogRemoval(enabled)
    ExecuteConsoleCommand("r.Fog", enabled and "0" or "1")
    ExecuteConsoleCommand("r.VolumetricFog", enabled and "0" or "1")
end

function SetGrassRemoval(enabled)
    ExecuteConsoleCommand("grass.DensityScale", enabled and "0" or "1")
    ExecuteConsoleCommand("foliage.DensityScale", enabled and "0" or "1")
end

function SetTreeRemoval(enabled)
    ExecuteConsoleCommand("foliage.TreeDensityScale", enabled and "0" or "1")
end

function SetWaterRemoval(enabled)
    ExecuteConsoleCommand("r.Water", enabled and "0" or "1")
end

function SetForceChinese(enabled)
    -- placeholder – implement if needed
end

-- Apply all scene effects based on current config
local function ApplySceneEffects()
    if _G.ESPConfig.RainEnabled then SetRainEnabled(true) end
    if _G.ESPConfig.SnowEnabled then SetSnowEnabled(true) end
    if _G.ESPConfig.BlackSky then SetBlackSky(true) end
    if _G.ESPConfig.RemoveFog then SetFogRemoval(true) end
    if _G.ESPConfig.RemoveGrass then SetGrassRemoval(true) end
    if _G.ESPConfig.RemoveTree then SetTreeRemoval(true) end
    if _G.ESPConfig.RemoveWater then SetWaterRemoval(true) end
    if _G.ESPConfig.ForceChinese then SetForceChinese(true) end
end

-- ===================================================================
-- ESP (unchanged from 1.lua, but uses the enhanced ApplyWallHack)
-- ===================================================================
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")

local cachedPawns     = {}
local lastPawnRefresh = 0

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus then return SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local boneList = {"head","neck_01","spine_01","spine_02","spine_03","pelvis",
    "upperarm_l","upperarm_r","lowerarm_l","lowerarm_r","hand_l","hand_r",
    "calf_l","calf_r","foot_l","foot_r"}
local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "▁" or " ") end
    return s
end

local function ESPTick()
    if not _G.CheatsEnabled then return end
    if _G.Mod_ESP_Enabled == false then return end
    if _G._ESPTimerHandle and _G._ESPTimerChar and not isValid(_G._ESPTimerChar) then _G._ESPTimerHandle = nil; _G._ESPTimerChar = nil end
    local uCon = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not (isValid(uCon) and Game:IsClassOf(uCon, ASTExtraPlayerController)) then return end
    local currentPawn = uCon:GetCurPawn()
    if not isValid(currentPawn) then return end

    local myTeamId = 0
    pcall(function()
        local char = uCon:GetPlayerCharacterSafety()
        if isValid(char) and char.TeamID then myTeamId = char.TeamID
        elseif currentPawn.TeamID then myTeamId = currentPawn.TeamID end
    end)
    local myPos = nil
    pcall(function() myPos = currentPawn:K2_GetActorLocation() end)
    if not myPos then return end
    local myEyePos = myPos
    pcall(function()
        if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end
    end)
    HUD = uCon:GetHUD()
    local now      = os.clock()

    if now - lastPawnRefresh > 1.0 then
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end

    local botCount = 0
    local playerCount = 0

    local totalAlive = 0
    for _, p in pairs(cachedPawns) do
        if isValid(p) and p ~= currentPawn and p.TeamID ~= myTeamId and IsPawnAlive(p) then
            totalAlive = totalAlive + 1
        end
    end
    local crowded = totalAlive > 20

    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId then
            if IsPawnAlive(tPawn) then
                local enemyPos = tPawn:K2_GetActorLocation()
                local dx = enemyPos.X - myPos.X
                local dy = enemyPos.Y - myPos.Y
                local dz = enemyPos.Z - myPos.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                local isBot = false
                pcall(function() isBot = Game:IsAI(tPawn) end)
                if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end

                if dist < 600000 and HUD then
                    local name = tPawn.PlayerName or "UNKNOWN"
                    local distM = dist / 100

                    local hp = tPawn.Health
                    local maxHp = tPawn.HealthMax
                    local isKnock = false
                    local hpPercent = 0
                    if not hp or not maxHp or maxHp <= 0 then
                        isKnock = true
                    elseif hp <= 0 then
                        isKnock = true
                    else
                        hpPercent = hp / maxHp
                    end
                    local hpColor = {R=0,G=255,B=0,A=255}
                    if hpPercent < 0.3 then
                        hpColor = {R=255,G=0,B=0,A=255}
                    elseif hpPercent < 0.7 then
                        hpColor = {R=255,G=255,B=0,A=255}
                    end
                    if isKnock then
                        hpColor = {R=255,G=0,B=0,A=255}
                    end

                    local bones = {}
                    local mesh = tPawn.Mesh
                    if isValid(mesh) then
                        for _, bn in ipairs(boneList) do
                            bones[bn] = mesh:GetSocketLocation(bn)
                        end
                    end
                    local origin = enemyPos
                    local oz = origin.Z
                    local headPos = bones["head"]
                    local footPos = bones["foot_l"]
                    local footRPos = bones["foot_r"]
                    local topZ = headPos and (headPos.Z - oz) or 90
                    local botZ = footPos and math.min(footPos.Z, footRPos and footRPos.Z or footPos.Z) - oz or -85

                    local headZ = headPos and (headPos.Z - oz) or 90
                    local hpOffset = headZ + 70 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                    local nameOffset = -80 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1

                    if crowded then
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz then HUD:AddDebugText("●", tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end
                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                    else
                        local hz = headPos and (headPos.Z - oz + 15)
                        local headChar = distM <= 25 and "❄" or "●"
                        if hz then HUD:AddDebugText(headChar, tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true) end

                        local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                        HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)

                        local nameColor = {R=0,G=255,B=0,A=255}
                        local targetPos = headPos or tPawn:K2_GetActorLocation()
                        pcall(function()
                            if Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) then
                                if _G.Mod_Chams_GreenEnabled then
                                    nameColor = _G.Mod_Chams_GreenRGB or {R=0,G=255,B=0,A=255}
                                else
                                    nameColor = {R=0,G=255,B=0,A=255}
                                end
                            else
                                if _G.Mod_Chams_YellowEnabled then
                                    nameColor = _G.Mod_Chams_YellowRGB or {R=255,G=255,B=0,A=255}
                                else
                                    nameColor = {R=255,G=255,B=0,A=255}
                                end
                            end
                        end)

                        HUD:AddDebugText(string.format("[%.0fm] %s", distM, name), tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)

                    end
                    -- Apply the enhanced wallhack
                    pcall(ApplyWallHack, currentPawn, tPawn, uCon)
                end
            end
        end
    end

    if not crowded and HUD and currentPawn then
        HUD:AddDebugText(string.format("BOT : %d     PLAYER : %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=155}, {X=0,Y=0,Z=155}, {R=255,G=255,B=0,A=255}, true, false, true, nil, 1.0, true)
        HUD:AddDebugText(" THIS MODED BY @ADITYA_ORG", currentPawn, 1, {X=0,Y=0,Z=145}, {X=0,Y=0,Z=145}, {R=0,G=200,B=255,A=255}, true, false, true, nil, 1.0, true)
    end
end

-- ESP timer (unchanged)
pcall(function()
    if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end

    local function StartESP(targetActor)
        if not isValid(targetActor) then return end
        cachedPawns = {}; lastPawnRefresh = 0
        _G._ESPTimerChar = targetActor
        _G._ESPTimerHandle = targetActor:AddGameTimer(0.2, true, function()
            pcall(ESPTick)
        end)
    end

    local function Watchdog()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            local curPawn = pc and pc:GetCurPawn()
            if isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
                if _G._ESPTimerHandle and isValid(_G._ESPTimerChar) then
                    pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                end
                _G._ESPTimerHandle = nil
                StartESP(curPawn)
            elseif not _G._ESPTimerHandle then
                StartESP(curPawn)
            end
        end)
    end

    _G._ESPWatchdogHandle = Game:SetTimer(1.0, true, Watchdog)
    Watchdog()
end)

-- ===================================================================
-- AIMBOT (unchanged from 1.lua)
-- ===================================================================
_G.Enable165FPSLogic = function()
  pcall(function()
    local graphics = require("client.slua.logic.setting.logic_setting_graphics")
    if graphics then
      local orig = graphics.SetFPS
      function graphics:SetFPS(lvl)
        if orig then orig(self, lvl) end
        if lvl == 8 and _G.Mod_FPS165_Enabled ~= false then 
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
    local fpsComp = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
    if fpsComp and fpsComp.__inner_impl then
      local impl = fpsComp.__inner_impl
      function impl.GetMaxFPSLevel() return 8, 8 end
      function impl:InitRealSupportFPS()
        local t = {}; for i = 1, 8 do t[i] = {true, true} end
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if db then db:UpdateUIData(db.RealSupportFPS, t, false) end
        return t
      end
      function impl:UpdateSelectedFPSState(lvl)
        local fps = {[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120}
        for i = 2, 8 do
          local node = self.UIRoot["NodeFps"..tostring(fps[i] or 120)]
          if isValid(node) then
            node:SetIsEnabled(true); pcall(function() node:SetRenderOpacity(1.0) end)
            local sw = self.UIRoot["WidgetSwitcher_"..tostring(i)]
            if isValid(sw) then sw:SetActiveWidgetIndex(i == lvl and 0 or 1) end
          end
        end
      end
    end
    local fpsFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
    if fpsFT and fpsFT.__inner_impl then
      local impl = fpsFT.__inner_impl; local MIN = 90
      function impl:ShowOrHide() self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
      function impl:InitFPSFTSwitch()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local on = db:GetUIData(db.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
        if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
        if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
        if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
      end
      function impl:InitFPSFTValue165()
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"); local r = self.UIRoot
        local on = db:GetUIData(db.FPSFineTuneSwitch); local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
        if on then
          r.Slider_screen3:SetLocked(false); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,1,1,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,1,1,1))
        else
          r.Slider_screen3:SetLocked(true); r.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1,0.625,0.6,1))
          r.Slider_screen3:SetSliderHandleColor(FLinearColor(1,0.625,0.6,1))
        end
        local norm = (val - MIN) / (165 - MIN)
        r.Veihclescreen3:SetText(tostring(val)); r.Slider_screen3:SetValue(norm); r.ProgressBar_screen3:SetPercent(norm)
      end
      function impl:OnFPSFTValueChange3(val)
        local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        db:UpdateUIData(db.FPSFineTuneNum, val); if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
        if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
        local gi = db.GetGameInstance and db.GetGameInstance()
        if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
      end
      function impl:OnFPSFTAdd3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.min(165, cur)) end
      function impl:OnFPSFTMinus3() local cur = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB").GetUIData(db.FPSFineTuneNum) or 90; self:OnFPSFTValueChange3(math.max(MIN, 5)) end
      impl.OnFPSFTAdd = impl.OnFPSFTAdd3; impl.OnFPSFTMinus = impl.OnFPSFTMinus3
    end
  end)
end

_G.EnableiPadViewUI = function()
  pcall(function()
    local sc = require("client.logic.setting.setting_config")
    if sc then
      if sc.TpViewValue then sc.TpViewValue.max = 140 end
      if sc.FpViewValue then sc.FpViewValue.max = 140 end
    end
    local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
    if db and db.TpViewValue then db.TpViewValue.max = 140 end
  end)
end

if _G.Mod_FPS165_Enabled ~= false then _G.Enable165FPSLogic() end
if _G.Mod_iPadView_Enabled ~= false then _G.EnableiPadViewUI() end

local pc = slua_GameFrontendHUD:GetPlayerController()
if isValid(pc) and pc.AddGameTimer and pc ~= _G._FeaturesTimerPC then
  _G._FeaturesTimerPC = pc
  local SubsystemMgr = nil
  local lastViewDistance = nil
  pc:AddGameTimer(0.1, true, function()
    pcall(function()
      if not _G.CheatsEnabled then return end
      local pc = slua_GameFrontendHUD:GetPlayerController()
      if not isValid(pc) then return end
      local char = pc:GetPlayerCharacterSafety()
      if not isValid(char) then return end
      local lp = GameplayData.GetPlayerCharacter()
      if not isValid(lp) then return end
      local isEnemy = lp.TeamID ~= char.TeamID

      SubsystemMgr = SubsystemMgr or package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"] or require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
      if SubsystemMgr then
        local SettingSubsystem = SubsystemMgr:Get("SettingSubsystem")
        if SettingSubsystem then
          local rawSliderValue = _G.Mod_iPadViewDistance or (SettingSubsystem:GetUserSettings_Int("TpViewValue") or 90)
          local targetTPP = rawSliderValue
          if rawSliderValue > 80 and rawSliderValue <= 90 then
              targetTPP = 80 + (rawSliderValue - 80) * 6.0
          elseif rawSliderValue > 90 then
              targetTPP = rawSliderValue
          end
          if _G.Mod_iPadView_Enabled ~= false then
            local uTPPCam = char.ThirdPersonCameraComponent
            if isValid(uTPPCam) and not char.bIsWeaponAiming then
                if lastViewDistance ~= targetTPP then
                    uTPPCam.FieldOfView = targetTPP
                    lastViewDistance = targetTPP
                end
            end
          end
        end
      end

      local gi = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
      if not gi then
        local SettingUtil = require("client.slua.logic.setting.setting_util")
        gi = SettingUtil and SettingUtil.GetGameInstance()
      end
      -- No Grass is now controlled by the Scene category, but keep backward compatibility
      if gi and _G.Mod_NoGrass_Enabled ~= false then
        if not _G._NoGrassApplied then
          gi:ExecuteCMD("grass.DensityScale", "0")
          gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
          _G._NoGrassApplied = true
        end
      end

      -- Apply scene effects (rain, snow, etc.)
      ApplySceneEffects()

      -- UPGRADE: Spoof player behaviour every tick
      SpoofPlayerBehaviour()

      -- ============ REMOVED: Body scale hack (PhysicsAssetOverride) ============
      -- The block that modified enemy mesh physics assets has been completely removed.
      -- Everything else remains unchanged.
      -- =========================================================================

    end)
  end)
end

_G._AimbotCurrentPC = nil

local function ApplyHardAimbot()
    if not _G.CheatsEnabled then return end
    if _G.Mod_Aimbot_Enabled == false then return end
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end

        local char = pc:GetPlayerCharacterSafety()
        if not isValid(char) then return end

        local wm = char.WeaponManagerComponent
        if not isValid(wm) then return end

        local weapon = wm.CurrentWeaponReplicated
        if not isValid(weapon) then return end

        local entity = weapon.ShootWeaponEntityComp
        if not isValid(entity) then return end

        local strengthMul = (_G.Mod_AimbotStrength or 50) / 100
        
        entity.GameDeviationFactor = 0.2
        entity.WeaponAimInTime = 20
        entity.SwitchFromIdleToBackpackTime = 0.15
        entity.SwitchFromBackpackToIdleTime = 0.15
        entity.ShotGunHorizontalSpread = 0.0
        entity.ShotGunVerticalSpread = 0.0
        entity.RecoilKick = 0.02
        entity.RecoilKickADS = 0.02
        entity.AnimationKick = 0.02
        entity.AccessoriesVRecoilFactor = 0.30
        entity.AccessoriesHRecoilFactor = 0.35
        entity.ExtraHitPerformScale = 10
        if entity.RecoilInfo then
            entity.RecoilInfo.VerticalRecoilMin = 0.2
            entity.RecoilInfo.VerticalRecoilMax = 0.5
            entity.RecoilInfo.RecoilSpeedVertical = 0.2
            entity.RecoilInfo.RecoilSpeedHorizontal = 0.15
            entity.RecoilInfo.VerticalRecoveryMax = 0.2
        end
        entity.RecoilModifierStand = 0.1
        entity.RecoilModifierCrouch = 0.1
        entity.RecoilModifierProne = 0.1
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local cfg = entity.AutoAimingConfig[range]
                if cfg then
                    cfg.Speed = 8
                    cfg.RangeRate = 5
                    cfg.SpeedRate = 5
                    cfg.RangeRateSight = 4
                    cfg.SpeedRateSight = 4
                    cfg.CrouchRate = 4
                    cfg.ProneRate = 4
                    cfg.DyingRate = 0
                    cfg.adsorbMaxRange = 200
                    cfg.adsorbMinRange = 20
                    cfg.adsorbMinAttenuationDis = 100
                    cfg.adsorbMaxAttenuationDis = 8000
                    cfg.adsorbActiveMinRange = 20
                end
            end
            entity.AutoAimingConfig = entity.AutoAimingConfig
        end
    end)
end

local function AttachAimbotTimer()
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not isValid(pc) then return end
        if pc == _G._AimbotCurrentPC then return end
        _G._AimbotCurrentPC = pc
        if pc.AddGameTimer then
            pc:AddGameTimer(0.1, true, function()
                if not isValid(_G._AimbotCurrentPC) then
                    _G._AimbotCurrentPC = nil
                    return
                end
                ApplyHardAimbot()
            end)
        end
    end)
end

AttachAimbotTimer()

pcall(function()
    local pc = slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(2.0, true, function()
            if not isValid(_G._AimbotCurrentPC) then
                _G._AimbotCurrentPC = nil
                AttachAimbotTimer()
            end
        end)
    end
end)

-- ===================================================================
-- FIXED MENU REGISTRATION (works even if settings UI loads first)
-- ===================================================================
pcall(function()
    -- Force LocUtil to accept the custom menu key
    local LocUtil = _G.LocUtil
    if not LocUtil then
        pcall(function()
            LocUtil = require("client.common.LocUtil")
        end)
    end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id  -- return the key string as-is for custom entries
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
        print("[MOD] LocUtil hooked for custom menu keys")
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    -- Build the full menu stack (merge all options)
    local ModMenuStack = {
        -- Main features
        {
            Key = "ModMenu_Aimbot",
            UI = AliasMap.Switcher,
            Text = "AIMBOT",
            GetFunc = function() return _G.Mod_Aimbot_Enabled or false end,
            SetFunc = function(_, value) _G.Mod_Aimbot_Enabled = value; return true end
        },
        {
            Key = "ESP",
            UI = AliasMap.Switcher,
            Text = "WALL ESP",
            GetFunc = function() return _G.Mod_ESP_Enabled or false end,
            SetFunc = function(_, value) _G.Mod_ESP_Enabled = value; return true end
        },
        {
            Key = "Skin",
            UI = AliasMap.Switcher,
            Text = "SKINS",
            GetFunc = function() return _G.Mod_Skin_Enabled or false end,
            SetFunc = function(_, value) _G.Mod_Skin_Enabled = value; return true end
        },
        {
            Key = "FPS165",
            UI = AliasMap.Switcher,
            Text = "165 FPS",
            GetFunc = function() return _G.Mod_FPS165_Enabled ~= false end,
            SetFunc = function(_, value)
                _G.Mod_FPS165_Enabled = value
                if value then _G.Enable165FPSLogic() end
                return true
            end
        },
        {
            Key = "iPadView",
            UI = AliasMap.Switcher,
            Text = "IPAD VIEW",
            GetFunc = function() return _G.Mod_iPadView_Enabled ~= false end,
            SetFunc = function(_, value)
                _G.Mod_iPadView_Enabled = value
                if value then _G.EnableiPadViewUI() end
                return true
            end
        },
        {
            Key = "ModMenu_iPadViewDistance",
            UI = AliasMap.Slider,
            Text = "View Distance (80-140)",
            GetFunc = function() return ((_G.Mod_iPadViewDistance or 90) - 80) / 60 end,
            SetFunc = function(_, value)
                _G.Mod_iPadViewDistance = math.floor(80 + (value * 60))
                return true
            end
        },

        -- Wallhack sub‑menu
        {
            Key = "Title_Wallhack",
            UI = AliasMap.Title,
            Text = "WALLHACK"
        },
        {
            Key = "ESP_Wallhack",
            UI = AliasMap.Switcher,
            Text = "Wallhack ON/OFF",
            GetFunc = function() return _G.Mod_Wallhack_Enabled or false end,
            SetFunc = function(_, value) _G.Mod_Wallhack_Enabled = value; return true end
        },
        {
            Key = "ESP_WallhackVisibleColor",
            UI = AliasMap.Switcher,
            Text = "Visible Color",
            SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
            SwitcherValue = {1,2,3,4,5,6,7},
            GetFunc = function() return _G.ESPConfig.WallhackVisibleColor or 1 end,
            SetFunc = function(_, value) _G.ESPConfig.WallhackVisibleColor = value; return true end
        },
        {
            Key = "ESP_WallhackInvisibleColor",
            UI = AliasMap.Switcher,
            Text = "Invisible Color",
            SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
            SwitcherValue = {1,2,3,4,5,6,7},
            GetFunc = function() return _G.ESPConfig.WallhackInvisibleColor or 2 end,
            SetFunc = function(_, value) _G.ESPConfig.WallhackInvisibleColor = value; return true end
        },
        {
            Key = "ESP_WallhackBrightness",
            UI = AliasMap.Slider,
            Text = "Brightness (1-50)",
            Min = 1, Max = 50, Step = 1, IsPercent = false,
            GetFunc = function() return _G.ESPConfig.WallhackBrightness or 25 end,
            SetFunc = function(_, value) _G.ESPConfig.WallhackBrightness = math.floor(value); return true end
        },
        {
            Key = "ESP_WallhackGlow",
            UI = AliasMap.Slider,
            Text = "Glow (0-10)",
            Min = 0, Max = 10, Step = 0.5, IsPercent = false,
            GetFunc = function() return _G.ESPConfig.WallhackGlow or 3.0 end,
            SetFunc = function(_, value) _G.ESPConfig.WallhackGlow = value; return true end
        },

        -- Scene controls
        {
            Key = "Title_Scene",
            UI = AliasMap.Title,
            Text = "SCENE CONTROLS"
        },
        {
            Key = "ESP_RemoveGrass",
            UI = AliasMap.Switcher,
            Text = "No Grass",
            GetFunc = function() return _G.Mod_NoGrass_Enabled ~= false end,
            SetFunc = function(_, value)
                _G.Mod_NoGrass_Enabled = value
                _G.ESPConfig.RemoveGrass = value
                if value then
                    ExecuteConsoleCommand("grass.DensityScale", "0")
                    ExecuteConsoleCommand("foliage.DensityScale", "0")
                else
                    ExecuteConsoleCommand("grass.DensityScale", "1")
                    ExecuteConsoleCommand("foliage.DensityScale", "1")
                end
                return true
            end
        },
        {
            Key = "ESP_RainEnabled",
            UI = AliasMap.Switcher,
            Text = "Rain",
            GetFunc = function() return _G.ESPConfig.RainEnabled end,
            SetFunc = function(_, value)
                _G.ESPConfig.RainEnabled = value
                SetRainEnabled(value)
                return true
            end
        },
        {
            Key = "ESP_SnowEnabled",
            UI = AliasMap.Switcher,
            Text = "Snow",
            GetFunc = function() return _G.ESPConfig.SnowEnabled end,
            SetFunc = function(_, value)
                _G.ESPConfig.SnowEnabled = value
                SetSnowEnabled(value)
                return true
            end
        },
        {
            Key = "ESP_BlackSky",
            UI = AliasMap.Switcher,
            Text = "Black Sky",
            GetFunc = function() return _G.ESPConfig.BlackSky end,
            SetFunc = function(_, value)
                _G.ESPConfig.BlackSky = value
                SetBlackSky(value)
                return true
            end
        },
        {
            Key = "ESP_RemoveFog",
            UI = AliasMap.Switcher,
            Text = "Remove Fog",
            GetFunc = function() return _G.ESPConfig.RemoveFog end,
            SetFunc = function(_, value)
                _G.ESPConfig.RemoveFog = value
                SetFogRemoval(value)
                return true
            end
        },
        {
            Key = "ESP_RemoveTree",
            UI = AliasMap.Switcher,
            Text = "Remove Trees",
            GetFunc = function() return _G.ESPConfig.RemoveTree end,
            SetFunc = function(_, value)
                _G.ESPConfig.RemoveTree = value
                SetTreeRemoval(value)
                return true
            end
        },
        {
            Key = "ESP_RemoveWater",
            UI = AliasMap.Switcher,
            Text = "Remove Water",
            GetFunc = function() return _G.ESPConfig.RemoveWater end,
            SetFunc = function(_, value)
                _G.ESPConfig.RemoveWater = value
                SetWaterRemoval(value)
                return true
            end
        },
        {
            Key = "ESP_ForceChinese",
            UI = AliasMap.Switcher,
            Text = "Force Chinese",
            GetFunc = function() return _G.ESPConfig.ForceChinese end,
            SetFunc = function(_, value)
                _G.ESPConfig.ForceChinese = value
                SetForceChinese(value)
                return true
            end
        },

        -- CHAMS colors (unchanged)
        {
            Key = "Title_ESP_Colors",
            UI = AliasMap.Title,
            Text = "CHAMS COLORS"
        },
        {
            Key = "ModMenu_GreenColor",
            UI = AliasMap.Switcher,
            Text = "GREEN (Visible)",
            GetFunc = function() return _G.Mod_Chams_GreenEnabled or false end,
            SetFunc = function(_, value) _G.Mod_Chams_GreenEnabled = value; return true end
        },
        {
            Key = "ModMenu_GreenR",
            UI = AliasMap.Slider,
            Text = "Green - Red (0-255)",
            GetFunc = function() return (_G.Mod_Chams_GreenRGB.R or 0) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_GreenRGB.R = math.floor(value * 255); return true end
        },
        {
            Key = "ModMenu_GreenG",
            UI = AliasMap.Slider,
            Text = "Green - Green (0-255)",
            GetFunc = function() return (_G.Mod_Chams_GreenRGB.G or 255) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_GreenRGB.G = math.floor(value * 255); return true end
        },
        {
            Key = "ModMenu_GreenB",
            UI = AliasMap.Slider,
            Text = "Green - Blue (0-255)",
            GetFunc = function() return (_G.Mod_Chams_GreenRGB.B or 0) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_GreenRGB.B = math.floor(value * 255); return true end
        },
        {
            Key = "ModMenu_YellowColor",
            UI = AliasMap.Switcher,
            Text = "YELLOW (Hidden)",
            GetFunc = function() return _G.Mod_Chams_YellowEnabled or false end,
            SetFunc = function(_, value) _G.Mod_Chams_YellowEnabled = value; return true end
        },
        {
            Key = "ModMenu_YellowR",
            UI = AliasMap.Slider,
            Text = "Yellow - Red (0-255)",
            GetFunc = function() return (_G.Mod_Chams_YellowRGB.R or 255) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_YellowRGB.R = math.floor(value * 255); return true end
        },
        {
            Key = "ModMenu_YellowG",
            UI = AliasMap.Slider,
            Text = "Yellow - Green (0-255)",
            GetFunc = function() return (_G.Mod_Chams_YellowRGB.G or 255) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_YellowRGB.G = math.floor(value * 255); return true end
        },
        {
            Key = "ModMenu_YellowB",
            UI = AliasMap.Slider,
            Text = "Yellow - Blue (0-255)",
            GetFunc = function() return (_G.Mod_Chams_YellowRGB.B or 0) / 255 end,
            SetFunc = function(_, value) _G.Mod_Chams_YellowRGB.B = math.floor(value * 255); return true end
        }
    }

    -- Register the menu page
    if not SettingPageDefine.ModMenu then
        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            loc = "ADITYA_MENU",
            UIKey = "Setting_Page_Privacy",
            Category = {
                {
                    Key = "ModMenu_Main",
                    loc = "FEATURES",
                    Stack = ModMenuStack
                }
            }
        }
        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
        print("[MOD] Menu page registered successfully")
    else
        -- Update existing menu
        for _, cat in ipairs(SettingPageDefine.ModMenu.Category) do
            if cat.Key == "ModMenu_Main" then
                cat.Stack = ModMenuStack
                print("[MOD] Menu stack updated")
                break
            end
        end
    end

    -- Hook UIManager to inject the menu if not already present
    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local hasModMenu = false
                    local newCatalog = {}
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then
                            hasModMenu = true
                        end
                    end
                    if not hasModMenu then
                        table.insert(newCatalog, SettingPageDefine.ModMenu)
                        args[1] = newCatalog
                        print("[MOD] Injected ModMenu into settings catalog")
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end
end)

-- ===================================================================
-- Ensure scene effects are applied on load
-- ===================================================================
pcall(function()
    -- Apply initial scene states (use a timer to let the game settle)
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(1.0, false, function()
            ApplySceneEffects()
        end)
    end
end)

-- ===================================================================
-- FINAL UPGRADE: Start deep patrol after full bypass
-- ===================================================================
pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        pc:AddGameTimer(10.0, false, function()
            StartDeepPatrol()
            print("[UPGRADE] Deep patrol started.")
        end)
    end
end)

print("[MERGED+UPGRADED] Full script loaded with all anti‑ban enhancements.")