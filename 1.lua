-- ===================================================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._MOD_LOADED and _G._MOD_PC == pc then return end
    _G._MOD_LOADED = true
    _G._MOD_PC = pc
end

local nop = function() end
local retTrue = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end
local isValid = function(obj) return slua.isValid(obj) end

local function safe_require(path)
    local ok, mod = pcall(require, path)
    return ok and mod or nil
end

_G.ModCfg = _G.ModCfg or {
    AimbotEnabled = false, AimbotStrength = 50, AimbotTarget = "Head",
    AimAssistEnabled = false, AimAssistStrength = 50, AimAssistTarget = "Head",
    AimConfigEnabled = false, AimConfigLevel = "MEDIUM",
    WeaponModEnabled = false,
    WeaponMod = { [101001]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101002]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101003]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101004]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101005]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101006]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101007]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101008]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101009]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false},
                  [101010]={FireSpeed=false,InstanHit=false,FastSwitch=false,FastScope=false} },
    NoRecoilEnabled = false, RecoilLevel = "LESS", NoShakeEnabled = false,
    MagicBulletEnabled = false, MagicBulletLevel = "MEDIUM",
    ESPEnabled = false, WallhackEnabled = false,
    ESP_HP_Bar = true, ESP_Box = true, ESP_MiniMap = true,
    ESP_ShowDistance = true, ESP_ShowName = true, ESP_ShowCount = true,
    WH_CoveredColor = {R=255,G=0,B=0,A=255}, WH_VisibleColor = {R=0,G=255,B=0,A=255},
    WH_CoveredGlow = {R=255,G=0,B=128,A=255}, WH_VisibleGlow = {R=0,G=255,B=255,A=255},
    ChamsGreenEnabled = false, ChamsYellowEnabled = false,
    ChamsGreenRGB = {R=0,G=255,B=0,A=255}, ChamsYellowRGB = {R=255,G=255,B=0,A=255},
    FPS165Enabled = true, NoGrassEnabled = true, BlackSkyEnabled = false,
    iPadViewEnabled = true, iPadViewDistance = 6.0,
    SkinEnabled = false,
}

_G._FOV_CachedSub = nil
_G._FOV_LastTarget = 80
_G._FOV_SmoothCurrent = 80

-- ==================== BLACKLISTS & HELPERS ====================
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
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice"
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
    for _, kw in ipairs(BLACKLIST_HOSTS) do if low:find(kw,1,true) then return true end end
    for _, port in ipairs(BLACKLIST_PORTS) do if low:find(":"..port) or low:find("/"..port) then return true end end
    return false
end

-- ==================== BYPASS SYSTEMS ====================
-- (All original bypass functions – kept intact)
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
            for _, fn in ipairs(kills) do if callbacks[fn] then callbacks[fn] = nop end end
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
            for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end
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
        if BanUtil then BanUtil.CheckBanStatus = retFalse; BanUtil.GetBanTime = retZero; BanUtil.IsBanForever = retFalse end
        local TTBan = safe_require("client.logic.login.logic_tt_ban") or _G.logic_tt_ban
        if TTBan then TTBan.CheckIfCanCreateRole = nop; TTBan.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end end
        local GodzillaBan = safe_require("client.network.Protocol.GodzillaBanHandler")
        if GodzillaBan then GodzillaBan.send_godzilla_ban_req = nop; GodzillaBan.send_godzilla_unban_req = nop end
        local AntiAddiction = safe_require("client.network.Protocol.AntiaddctionHandler")
        if AntiAddiction then AntiAddiction.send_anti_addiction_req = nop; AntiAddiction.send_anti_addiction_notify = nop end
        local AccessRestrict = safe_require("client.network.Protocol.AccessRestrictionHandler")
        if AccessRestrict then
            AccessRestrict.send_access_restriction_req = nop
            AccessRestrict.send_access_restriction_notify = nop
            AccessRestrict.on_player_cheat_state_notify = nop
        end
        local DeleteAccount = safe_require("client.slua.logic.gdpr.logic_deleteaccount")
        if DeleteAccount then DeleteAccount.ForceDeleteAccount = retFalse; DeleteAccount.OnReceiveDeleteNotify = nop end
        local ComplianceUtil = safe_require("client.slua.logic.gdpr.compliance_util")
        if ComplianceUtil then ComplianceUtil.CheckCompliance = nop end
    end)
end

local function BypassReportSystems()
    pcall(function()
        local clientReport = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem")
        if clientReport then
            local funcs = {"OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","SendPacket","ReportSuspiciousPlayer","SubmitReport","_OnBattleResult","_RecordTeammatePlayerInfo","_OnDeathReplayDataWhenFatalDamaged","_RecordMurdererFromDeathReplayData"}
            for _, fn in ipairs(funcs) do if clientReport[fn] then clientReport[fn] = nop end end
        end
        local dsReport = safe_require("GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem")
        if dsReport then
            local funcs = {"_OnNearDeathOrRescued","_OnPlayerSettlementStart","_OnTeammateDamage","_OnCharacterDied","_AddEnemyMapToBattleResult","_AddTeammateMapToBattleResult","_SubmitAbnormalData"}
            for _, fn in ipairs(funcs) do if dsReport[fn] then dsReport[fn] = nop end end
        end
        local reportUtils = safe_require("GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils")
        if reportUtils then reportUtils.GetBotType = retZero; reportUtils.IsCharacterDeliverAI = retFalse end
        local AvatarSub = safe_require("GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionSubsystem")
        if AvatarSub then AvatarSub.OnClickReportCheckAvatar = nop; AvatarSub.RegisterTickCheckCharacterAvatar = nop end
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
            _G.DSHawkEyePatrolSubsystem._OnHawkReport = nop; _G.DSHawkEyePatrolSubsystem._OnHawkImprison = nop
            _G.DSHawkEyePatrolSubsystem.CheckPunishPlayer = nop
        end
        local ClientHawk = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem")
        if ClientHawk then
            local funcs = {"_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer","_OnRecvInspectorBroadcastCount","SendReportTLog","ReportCheat"}
            for _, fn in ipairs(funcs) do if ClientHawk[fn] then ClientHawk[fn] = nop end end
            ClientHawk.CanInspectorBroadcast = retFalse
        end
        local InspectClient = safe_require("GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem")
        if InspectClient then
            local funcs = {"AskForInspector","ReportEnemy","KickOutOneTeam","OnReceiveInspectCmd","ClientReportData","SendReportToInspector","SendKickOutOneTeam","ClientNotifyInspectorImplementation","RecvNotifyInspector"}
            for _, fn in ipairs(funcs) do if InspectClient[fn] then InspectClient[fn] = nop end end
        end
        local InspectDS = safe_require("GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem")
        if InspectDS then
            local funcs = {"ServerKickOutOneTeamByPlayerImplementation","AddReportedCount","AddInspectionRecord","BanPlayerByInspection","BroadCastToAllInspector","ServerReportToInspectorImplementation","InitPlayerInspectionInfo"}
            for _, fn in ipairs(funcs) do if InspectDS[fn] then InspectDS[fn] = nop end end
        end
    end)
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
        if AmphibiousBoat then AmphibiousBoat.RecordMovement = nop; AmphibiousBoat.StartRecordMovement = nop end
        local ICTLog = safe_require("GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem")
        if ICTLog then ICTLog.SendICExceptionTLog = nop end
        local DSFight = safe_require("GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem")
        if DSFight then DSFight.GetSimpleFightData = retEmpty; DSFight.ReportFightData = nop; DSFight.ReportPlayerWeapon = nop end
        local DSSec = safe_require("GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem")
        if DSSec then DSSec._OnReportServerJumpFlow = nop; DSSec._OnReportTeleportFlow = nop; DSSec._OnReportSpeedHackFlow = nop end
        local DSCommon = safe_require("GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem")
        if DSCommon then DSCommon.HandleKillTlog = nop end
        local PufferTlog = safe_require("client.slua.logic.download.report.puffer_tlog")
        if PufferTlog then PufferTlog.report_download_tlog = nop end
    end)
end

local function BypassNetworkHandlers()
    pcall(function()
        local ClientError = safe_require("client.network.Protocol.ClientErrorReportHandler")
        if ClientError then ClientError.send_client_error_report = nop; ClientError.send_client_crash_report = nop; ClientError.send_client_tools_batch_report_req = nop end
        local BattleReport = safe_require("client.network.Protocol.BattleReportHandler")
        if BattleReport then
            for _, fn in ipairs({"send_battle_report","send_battle_result","send_vod_game_report_req","send_batch_get_vod_info_req","send_get_game_report_req","send_batch_get_game_report_req","send_get_game_report_by_uid_req"}) do
                if BattleReport[fn] then BattleReport[fn] = nop end
            end
        end
        local BugHandler = safe_require("client.network.Protocol.BugHandler")
        if BugHandler then BugHandler.send_report_bug_info = nop; BugHandler.send_report_bug_feedback = nop end
        local PingReport = safe_require("client.network.Protocol.LobbyPingReportHandler")
        if PingReport then PingReport.send_lobby_ping_report = nop; PingReport.send_ingame_ping_report = nop end
        local WeekReport = safe_require("client.network.Protocol.WeekRportHandler")
        if WeekReport then WeekReport.send_week_report = nop; WeekReport.send_week_detail = nop end
        local LogicComplaint = safe_require("client.logic.battle.logic_complaint")
        if LogicComplaint then LogicComplaint.SendComplaintReq = nop; LogicComplaint.Submit = nop; LogicComplaint.ReportPlayer = nop; LogicComplaint.ShowComplaint = nop; LogicComplaint.ShowHandle = nop end
        local OBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic")
        if OBResult then OBResult.OnBattleResult = nop; OBResult.OnResultProcessStart = nop end
        local NormalOBResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic")
        if NormalOBResult then NormalOBResult.OnBattleResult = nop; NormalOBResult.OnResultProcessStart = nop end
        local ShowResult = safe_require("GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic")
        if ShowResult then
            for _, fn in ipairs({"OnBattleResult","OnResultProcessStart","OnResultProcessContinue","ReceiveData","SendEndFlow","OnReport","ShowResult","ShowResultInternal","StopResultProcess"}) do
                if ShowResult[fn] then ShowResult[fn] = nop end
            end
        end
    end)
end

local function BypassMiscSystems()
    pcall(function()
        local EmuHandler = safe_require("client.network.Protocol.EmulatorHandler")
        if EmuHandler then EmuHandler.send_emulator_info = nop end
        local EmuScanner = safe_require("client.logic.login.emulator_scanner")
        if EmuScanner then EmuScanner.StartScan = nop; EmuScanner.GetScanResult = retFalse; EmuScanner.ReportScanResult = nop end
        local LoginVerify = safe_require("client.network.Protocol.LoginVerifyHandler")
        if LoginVerify then LoginVerify.send_login_verify_req = nop; LoginVerify.send_device_verify_req = nop end
        local DSMonitor = safe_require("client.logic.data.logic_ds_monitor")
        if DSMonitor then DSMonitor.OnRecordMsg = nop; DSMonitor.OnReportMsg = nop end
        local ClientDataStat = safe_require("GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem")
        if ClientDataStat then
            ClientDataStat.StartToCheck = nop; ClientDataStat.OnReceiveRTT = nop; ClientDataStat.OnReceiveJitter = nop
            ClientDataStat.ReportAbnormal = nop; ClientDataStat.ResetData = nop
        end
        local shootVerify = safe_require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if shootVerify then shootVerify.OnShootVerifyFailed = nop; shootVerify.SendVerifyData = nop end
        local HighlightDS = safe_require("GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker")
        if HighlightDS then HighlightDS.CheckFuncUpgradedWeaponKill = nop end
        local ProfileReport = safe_require("client.logic.data.profile_report_cfg")
        if ProfileReport then ProfileReport.SendReport = nop end
        local VoiceReport = safe_require("client.slua.logic.chat_voice.logic_chat_voice_report")
        if VoiceReport then VoiceReport.ReportVoiceData = nop; VoiceReport.ReportVoiceText = nop end
        local VoiceDoctor = safe_require("client.slua.logic.chat_voice.logic_chat_voice_doctor")
        if VoiceDoctor then VoiceDoctor.UploadVoiceLog = nop; VoiceDoctor.UploadVoiceException = nop end
        local HomeAudit = safe_require("client.slua.logic.home.Audit.logic_home_audit_state")
        if HomeAudit then HomeAudit.SendAuditState = nop; HomeAudit.ReportAuditResult = nop end
        local HomeReport = safe_require("client.slua.logic.home.logic_home_report")
        if HomeReport then HomeReport.ReportHomeData = nop; HomeReport.ReportHomeVisitor = nop end
        local GemReport = safe_require("client.logic.store.gem_report_utils")
        if GemReport then GemReport.ReportGemData = nop; GemReport.ReportGemPurchase = nop end
        local SafeStation = safe_require("client.slua.logic.CustomerService.LogicSafeStation")
        if SafeStation then SafeStation.UploadVideoEvidence = nop; SafeStation.ReportPlayerBehavior = nop end
        local CustomerService = safe_require("client.slua.logic.CustomerService.LogicCustomerService")
        if CustomerService then CustomerService.SendComplaint = nop; CustomerService.SendFeedback = nop end
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
            if orig then DataLayer.OnSpectatorReplayChanged = function(dlSelf) _G.IsBeingWatched = true; orig(dlSelf) end end
        end
        local DSActive = safe_require("GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem")
        if DSActive then DSActive.DelayKickOutPlayer = nop; DSActive.ActiveKickNotify = nop end
        local CreativeDev = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem")
        if CreativeDev then CreativeDev.IsDebugPanelEnalbedCli = nop end
        local CreativeDeath = safe_require("GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem")
        if CreativeDeath then CreativeDeath.OnPlayerKilled = nop end
        if _G.ClientReplayDataReporter then _G.ClientReplayDataReporter.ReportIntArrayData = nop; _G.ClientReplayDataReporter.ReportFloatArrayData = nop end
        local SpectateReplay = safe_require("GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem")
        if SpectateReplay then SpectateReplay.RequestGotoSpectatingImp = nop; SpectateReplay.RequestGotoSpectating = nop end
        local AIReplay = safe_require("GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem")
        if AIReplay then
            AIReplay.ReportAllPlayerInfo = nop; AIReplay.ReportFrameData = nop; AIReplay.ReportPlayerInput = nop
            if AIReplay.uCompletePlayBack then AIReplay.uCompletePlayBack.AddRecordMLAIInfo = nop; AIReplay.uCompletePlayBack.StopRecording = nop end
        end
        local AITracking = safe_require("GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem")
        if AITracking then
            AITracking.RealLogoutTimer = nop; AITracking.LogQueue = {}; AITracking.AddToLogQue = nop; AITracking.DoPrint = nop
            AITracking.OnAIPawnDied = nop; AITracking.OnAIPawnReceiveDamage = nop; AITracking.OnAIPawnEnemyChange = nop
        end
        local AFKReport = safe_require("GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem")
        if AFKReport then
            AFKReport.HandleEnterFighting = nop; AFKReport.InitializePlayerInputInfo = nop; AFKReport.AddOneAFKInfo = nop
            AFKReport.SetPlayerAFKState = nop; AFKReport.ResetPlayerInputInfo = nop; AFKReport.PlayerHaveAction = nop
        end
        local TDMAFK = safe_require("GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem")
        if TDMAFK then TDMAFK.SendAFKTips = nop; TDMAFK.OnHandleLostConnection = nop end
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
            _G.HttpRequest = function(url, ...) if isBlacklisted(url) then return nil end return orig(url, ...) end
        end
        if _G.FHttpModule and _G.FHttpModule.CreateRequest then
            local orig = _G.FHttpModule.CreateRequest
            _G.FHttpModule.CreateRequest = function(...) local url = select(1,...); if isBlacklisted(url) then return nil end return orig(...) end
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
                            for _, arg in ipairs(args) do if type(arg)=="string" and isBlacklisted(arg) then return nil end end
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
                    if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then return nil, "Blocked" end
                end
            end
            if lp:find("tdm") or lp:find("gcloud") or lp:find("beacon") then
                if mode and (mode == "w" or mode == "a" or mode == "w+") then return nil end
            end
        end
        return orig_io_open(path, mode)
    end
    if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
        _G.UnrealEngine.CrashContext = nil
        _G.UnrealEngine.CrashContext = { SetCrashContext = nop, ReportCrash = nop, AddCrashData = nop }
    end
end

_G.BypassState = _G.BypassState or {
    DeadEyeDisabled = false, HawkEyeDisabled = false, VoklaiDisabled = false,
    HiggsBosonDisabled = false, HashVerifyDisabled = false, IPMappingDisabled = false,
    MemoryPatchDisabled = false, EduEyeDisabled = false, FullBypassActive = false
}

local FakeData = {
    ping = function() return math.random(20, 45) end,
    deviceID = function()
        local chars = "0123456789ABCDEF"
        local id = ""
        for i = 1, 32 do id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars)) end
        return id
    end,
    ipAddress = function() return "192.168." .. math.random(1, 255) .. "." .. math.random(1, 255) end,
    macAddress = function()
        return string.format("%02X:%02X:%02X:%02X:%02X:%02X", math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255), math.random(0,255))
    end,
    buildFingerprint = function() return "qcom/msmnile/msmnile:" .. math.random(10, 12) .. "/" .. math.random(100000, 999999) .. "/user/release-keys" end,
    kernelVersion = function() return "4.19." .. math.random(100, 200) .. "-generic" end,
    hashValue = function() return "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" end
}

local function KillTable(tbl, keys)
    if not tbl then return end
    for _, key in ipairs(keys) do
        pcall(function()
            if type(tbl[key]) == "function" then tbl[key] = function() return true, {} end else tbl[key] = nil end
        end)
    end
end

local function BypassDeadEye()
    if _G.BypassState.DeadEyeDisabled then return end
    pcall(function()
        if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"ReportAimFlow","ReportHitFlow","ReportAttackFlow","OnAimDetected","OnHeadshotDetected","OnPerfectAccuracy"}) end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aimTracker = subsystems:Get("ClientAimTrackingSubsystem")
            if aimTracker then
                aimTracker.GetAimData = function() return {accuracy = math.random(45, 65), headshotRate = math.random(15, 35)} end
                aimTracker.IsAimNormal = function() return true end
            end
        end
    end)
    _G.BypassState.DeadEyeDisabled = true
end

local function BypassHawkEye()
    if _G.BypassState.HawkEyeDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local hawkEye = subsystems:Get("ClientHawkEyePatrolSubsystem")
            if hawkEye then hawkEye.GetPatrolData = function() return {} end; hawkEye.IsBeingWatched = function() return false end; hawkEye.GetSpectatorCount = function() return 0 end end
        end
        if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"SendDSErrorLogToLobby","SendDSHawkEyePatrolLogToLobby","ReportMatchRoomData"}) end
    end)
    _G.BypassState.HawkEyeDisabled = true
end

local function BypassVoklai()
    if _G.BypassState.VoklaiDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local aiBehavior = subsystems:Get("ClientAIBehaviourSubsystem")
            if aiBehavior then aiBehavior.GetBehaviorScore = function() return math.random(10, 30) end; aiBehavior.IsSuspicious = function() return false end; aiBehavior.GetRiskLevel = function() return 0 end end
            local stepCheck = subsystems:Get("ClientStepCheckSubsystem")
            if stepCheck then stepCheck.GetStepDelta = function() return math.random(5, 50) end; stepCheck.IsMovementValid = function() return true end end
            local speedHack = subsystems:Get("AntiSpeedHackSubsystem") or subsystems:Get("ClientAntiSpeedHackSubsystem")
            if speedHack then speedHack.GetSpeed = function() return math.random(300, 600) end; speedHack.IsSpeedValid = function() return true end end
        end
    end)
    _G.BypassState.VoklaiDisabled = true
end

local function BypassHiggsBoson8()
    if _G.BypassState.HiggsBosonDisabled then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent:ControlMHActive(0) end
        end
        local higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if higgs then
            higgs.GetNetAvatarItemIDs = function() return {1001, 2002, 3003, 4004, 5005} end
            higgs.GetCurWeaponSkinID = function() return 6001 end
            higgs.GetCurItemIDs = function() return {7001, 8002} end
            if higgs.BlackList then higgs.BlackList = {} end
        end
        _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
        local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
        mt.__newindex = function() end
        setmetatable(_G.GlobalPlayerCoronaData, mt)
        _G.BlackList = {}
    end)
    _G.BypassState.HiggsBosonDisabled = true
end

local function BypassHashVerification()
    if _G.BypassState.HashVerifyDisabled then return end
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.ScanMemory = function() return true, {code = 0, msg = "clean"} end
            _G.TssSdk.ScanSo = function() return true, {code = 0, msg = "clean"} end
            _G.TssSdk.ScanFile = function() return true, {code = 0} end
            _G.TssSdk.GetRiskFlag = function() return 0 end
            _G.TssSdk.VerifyFileHash = function() return true end
        end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local integrity = subsystems:Get("ClientIntegrityCheckSubsystem")
            if integrity then KillTable(integrity, {"CheckFileHash","VerifyMemory","ScanModules"}) end
        end
    end)
    _G.BypassState.HashVerifyDisabled = true
end

local function BypassIPMapping()
    if _G.BypassState.IPMappingDisabled then return end
    pcall(function()
        if _G.GameplayCallbacks then KillTable(_G.GameplayCallbacks, {"SendClientDeviceInfo","ReportDeviceFingerprint","SendNetworkInfo","ReportIPAddress","SendMACAddress","ReportHardwareID"}) end
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local deviceInfo = subsystems:Get("ClientDeviceInfoSubsystem")
            if deviceInfo then deviceInfo.GetDeviceID = function() return FakeData.deviceID() end; deviceInfo.GetIPAddress = function() return FakeData.ipAddress() end; deviceInfo.GetMACAddress = function() return FakeData.macAddress() end end
        end
    end)
    _G.BypassState.IPMappingDisabled = true
end

local function BypassMemoryPatching()
    if _G.BypassState.MemoryPatchDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local kernelCheck = subsystems:Get("ClientKernelCheckSubsystem")
            if kernelCheck then kernelCheck.IsKernelClean = function() return true end; kernelCheck.GetKernelVersion = function() return FakeData.kernelVersion() end; kernelCheck.IsBootloaderLocked = function() return true end end
            local memoryGuard = subsystems:Get("ClientMemoryGuardSubsystem")
            if memoryGuard then memoryGuard.IsMemoryClean = function() return true, {code = 0} end; memoryGuard.ScanResult = function() return "clean" end end
        end
        if _G.TssSdk then
            _G.TssSdk.CheckKernel = function() return true, {status = "verified", tampered = false} end
            _G.TssSdk.VerifyBoot = function() return true, {locked = true, verified = true} end
        end
    end)
    _G.BypassState.MemoryPatchDisabled = true
end

local function BypassEduEye()
    if _G.BypassState.EduEyeDisabled then return end
    pcall(function()
        local subsystems = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if subsystems then
            local renderCheck = subsystems:Get("ClientRenderCheckSubsystem")
            if renderCheck then renderCheck.IsRenderClean = function() return true end; renderCheck.GetRenderState = function() return "normal" end end
            local espDetection = subsystems:Get("ClientESPDetectionSubsystem")
            if espDetection then espDetection.HasESP = function() return false end; espDetection.CheckOverlay = function() return "clean" end end
            local wallhackDetect = subsystems:Get("ClientWallhackDetectionSubsystem")
            if wallhackDetect then wallhackDetect.IsVisionNormal = function() return true end; wallhackDetect.GetVisibilityRate = function() return math.random(60, 85) end end
        end
    end)
    _G.BypassState.EduEyeDisabled = true
end

local function ApplyAllBypasses()
    if _G.BypassState.FullBypassActive then return end
    pcall(function()
        BypassDeadEye(); BypassHawkEye(); BypassVoklai()
        BypassHiggsBoson8(); BypassHashVerification(); BypassIPMapping()
        BypassMemoryPatching(); BypassEduEye()
        _G.BypassState.FullBypassActive = true
    end)
end

local function InitAllBypasses()
    pcall(function()
        InitBypassBase(); BypassHiggs(); BypassBanSystem(); BypassReportSystems()
        BypassTLogModules(); BypassNetworkHandlers(); BypassMiscSystems(); BypassExtraSubsystems()
        InitNetworkBlacklist(); InitFileIOCrashBlock(); ApplyAllBypasses()
        local globalFuncs = {
            "ReportTLogEvent","SendTlog","SendClientStats","ReportHitFlow","ReportAvatarException",
            "SendComplaintReq","SubmitReport","ReportSuspiciousPlayer","SendPacket","OnSyncBanInfo",
            "OnVoiceBanNotify","SendSecTLog","MarkSuspiciousPlayer","ReportPlayerBehaviorData",
            "CheckCompliance","ReportIllegalProgram","UploadVoiceLog"
        }
        for _, fn in ipairs(globalFuncs) do if type(_G[fn]) == "function" then _G[fn] = nop end end
        pcall(function()
            local s = import("ScreenshotMaker"); if s then s.MakePicture = nop; s.ReMakePicture = nop; s.HasCaptured = retTrue end
            local tl = package.loaded["TLog"] or _G.TLog; if tl then tl.Info = nop; tl.Warning = nop; tl.Error = nop; tl.Debug = nop; tl.Report = nop end
            local cs = package.loaded["CrashSight"] or _G.CrashSight; if cs then cs.ReportException = nop; cs.SetCustomData = nop; cs.Log = nop end
        end)
        pcall(function()
            if _G.NetUtil and _G.NetUtil.SendPacket and not _G.NetUtil._IsBypassed then
                local origSend = _G.NetUtil.SendPacket
                local blocked = {
                    "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms",
                    "ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt",
                    "ReportPlayerMoveRoute","ReportPlayerPosition","ReportAimFlow","ReportHitFlow",
                    "ReportCircleFlow","ReportJumpFlow","report_players_ping","report_player_ip",
                    "tss_sdk_report","report_client_scan_result","report_memory_exception",
                    "report_avatar_exception","report_character_state","report_vehicle_exception",
                    "report_camera_exception","ReportEquipmentFlow","ReportHeavyWeaponBoxSpawnFlow",
                    "ReportHeavyWeaponBoxActivationFlow","ReportSecTLog","report_player_frame_ping_record",
                    "ReportSecAttackFlow","ReportSecTgameMovingFlow","ReportVehicleMoveFlow",
                    "ReportParachuteData","report_unrealnet_exception","report_ds_net_saturation",
                    "on_tss_sdk_anti_data"
                }
                _G.NetUtil.SendPacket = function(packetName, ...)
                    if blocked[packetName] then return end
                    return origSend(packetName, ...)
                end
                _G.NetUtil._IsBypassed = true
            end
        end)
        pcall(function()
            local hbc = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if hbc and hbc.BlackList then for k in pairs(hbc.BlackList) do hbc.BlackList[k] = nil end end
            _G.BlackList = {}
            _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
            local mt = getmetatable(_G.GlobalPlayerCoronaData) or {}
            mt.__newindex = function(t, k, v) end
            setmetatable(_G.GlobalPlayerCoronaData, mt)
        end)
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
                local block = {["cheatdetected"]=true,["connectionlost"]=true,["connectiontimeout"]=true,["connectionexception"]=true,["netdrivererror"]=true}
                if block[state] then return end
                if origDS then pcall(origDS, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
            end
            GC.OnPlayerNetConnectionClosed = nop; GC.OnPlayerActorChannelError = nop
            GC.OnPlayerRPCValidateFailed = nop; GC.OnPlayerSpectateException = nop; GC.OnShutdownAfterError = nop
        end)
        pcall(function()
            local mgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
            local rt = mgr and mgr:Get("RescueBtnReplayTraceSubsystem")
            if rt then rt.ReportTrace = nop; rt.StartTickMonitor = nop; rt.TickMonitorCheck = nop; rt.ReportTickMonitorHeartbeat = nop end
            local gr = mgr and mgr:Get("GameReportSubsystem")
            if gr then
                gr.ReplayReportData = retFalse; gr.CheckCanBugglyPostException = retFalse; gr.BugglyPostExceptionFull = retFalse
                gr.GetClientReplayDataReporter = function() return nil end
                if gr.Reporter then gr.Reporter.ReportIntArrayData = nop; gr.Reporter.ReportUInt8ArrayData = nop; gr.Reporter.ReportFloatArrayData = nop end
            end
            local rp = safe_require("client.slua.logic.replay.logic_report_replay")
            if rp then rp.ReportReplay = nop; rp.SendReportReq = nop end
        end)
    end)
end

-- ==================== FEATURE IMPLEMENTATIONS ====================
-- (All original feature functions – ApplyZNAimbot, ApplyAimAssist, ApplyWeaponMod, ApplyAimConfig, ApplyNoRecoil, ApplyMagicBullet, etc.)
-- They are the same as in the long script, kept intact for brevity.
-- For space, I'm not pasting them again here; they are in the full code.

-- ==================== ESP / WALLHACK ====================
-- (Same as original, not re-pasted for brevity)

-- ==================== SKIN SYSTEM ====================
-- (Same as original)

-- ==================== MOD MENU INJECTION (FIXED) ====================
-- This is the KEY FIX – using the working method from 1.lua

local function InitModMenu()
    -- Localize LocUtil
    local LocUtil = _G.LocUtil
    if not LocUtil then LocUtil = safe_require("client.common.LocUtil") end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = safe_require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = safe_require("client.logic.NewSetting.SettingCatalog")
    if not SettingPageDefine or not SettingCatalog then return false end
    if SettingPageDefine.ModMenu then return true end

    local AliasMap = safe_require("client.slua.umg.NewSetting.Item.AliasMap")
    if not AliasMap then return false end

    local cfg = _G.ModCfg

    -- Build the full menu stack (exactly as in the original long script)
    local aimbotStack = {}
    table.insert(aimbotStack, { UI = AliasMap.Title, Text = "=== AIMBOT ===" })
    table.insert(aimbotStack, {
        Key = "MM_Aimbot", UI = AliasMap.Switcher, Text = "ZN AIMBOT",
        GetFunc = function() return cfg.AimbotEnabled end,
        SetFunc = function(_, v) cfg.AimbotEnabled = v; return true end
    })
    table.insert(aimbotStack, {
        Key = "MM_AimbotStr", UI = AliasMap.Slider, Text = "Aimbot Strength (0-100)", min=0, max=100,
        GetFunc = function() return (cfg.AimbotStrength or 50) / 100 end,
        SetFunc = function(_, v) cfg.AimbotStrength = math.floor(v * 100); return true end
    })
    table.insert(aimbotStack, { UI = AliasMap.Title, Text = "Target Bone:" })
    for _, t in ipairs({"Head", "neck_01", "pelvis"}) do
        table.insert(aimbotStack, {
            Key = "MM_AimbotT_"..t, UI = AliasMap.Switcher, Text = "   " .. t,
            ExpandHandle = "MM_Aimbot",
            GetFunc = function() return cfg.AimbotTarget == t end,
            SetFunc = function(_, v) if v then cfg.AimbotTarget = t end; return true end
        })
    end
    table.insert(aimbotStack, { UI = AliasMap.Title, Text = "=== AIM ASSIST ===" })
    table.insert(aimbotStack, {
        Key = "MM_AimAssist", UI = AliasMap.Switcher, Text = "AIM ASSIST",
        GetFunc = function() return cfg.AimAssistEnabled end,
        SetFunc = function(_, v) cfg.AimAssistEnabled = v; return true end
    })
    table.insert(aimbotStack, {
        Key = "MM_AimAssistStr", UI = AliasMap.Slider, Text = "Assist Strength (0-100)", min=0, max=100,
        GetFunc = function() return (cfg.AimAssistStrength or 50) / 100 end,
        SetFunc = function(_, v) cfg.AimAssistStrength = math.floor(v * 100); return true end
    })
    table.insert(aimbotStack, { UI = AliasMap.Title, Text = "=== AIM CONFIG ===" })
    table.insert(aimbotStack, {
        Key = "MM_AimCfg", UI = AliasMap.Switcher, Text = "AIM CONFIG (4-LEVEL)",
        GetFunc = function() return cfg.AimConfigEnabled end,
        SetFunc = function(_, v) cfg.AimConfigEnabled = v; return true end
    })
    for _, lv in ipairs({"LOW", "MEDIUM", "HARD", "EXTREME"}) do
        table.insert(aimbotStack, {
            Key = "MM_AimCfg_"..lv, UI = AliasMap.Switcher, Text = "   " .. lv,
            ExpandHandle = "MM_AimCfg",
            GetFunc = function() return cfg.AimConfigLevel == lv end,
            SetFunc = function(_, v) if v then cfg.AimConfigLevel = lv end; return true end
        })
    end

    local weaponStack = {}
    table.insert(weaponStack, { UI = AliasMap.Title, Text = "=== WEAPON MOD ===" })
    table.insert(weaponStack, {
        Key = "MM_WpnMod", UI = AliasMap.Switcher, Text = "WEAPON MOD",
        GetFunc = function() return cfg.WeaponModEnabled end,
        SetFunc = function(_, v) cfg.WeaponModEnabled = v; return true end
    })
    table.insert(weaponStack, { UI = AliasMap.Title, Text = "=== NO RECOIL ===" })
    table.insert(weaponStack, {
        Key = "MM_NoRecoil", UI = AliasMap.Switcher, Text = "NO RECOIL",
        GetFunc = function() return cfg.NoRecoilEnabled end,
        SetFunc = function(_, v) cfg.NoRecoilEnabled = v; return true end
    })
    for _, rl in ipairs({"LESS", "NO", "DEFAULT"}) do
        table.insert(weaponStack, {
            Key = "MM_Recoil_"..rl, UI = AliasMap.Switcher, Text = "   " .. rl,
            ExpandHandle = "MM_NoRecoil",
            GetFunc = function() return cfg.RecoilLevel == rl end,
            SetFunc = function(_, v) if v then cfg.RecoilLevel = rl end; return true end
        })
    end
    table.insert(weaponStack, {
        Key = "MM_NoShake", UI = AliasMap.Switcher, Text = "NO SHAKE",
        ExpandHandle = "MM_NoRecoil",
        GetFunc = function() return cfg.NoShakeEnabled end,
        SetFunc = function(_, v) cfg.NoShakeEnabled = v; return true end
    })
    local weaponNames = {[101001]="AKM",[101002]="M16A4",[101003]="SCAR",[101004]="M416",
                         [101005]="GROZA",[101006]="AUG",[101007]="QBZ",[101008]="M762",
                         [101009]="MK47",[101010]="G36C"}
    table.insert(weaponStack, { UI = AliasMap.Title, Text = "=== WEAPON PERKS ===" })
    for wid, wname in pairs(weaponNames) do
        table.insert(weaponStack, { UI = AliasMap.Title, Text = wname, ExpandHandle = "MM_WpnMod" })
        table.insert(weaponStack, { Key = "MM_W_"..wid.."_F", UI = AliasMap.Switcher, Text = "   FIRESPEED", ExpandHandle = "MM_WpnMod",
            GetFunc = function() return cfg.WeaponMod[wid].FireSpeed end,
            SetFunc = function(_, v) cfg.WeaponMod[wid].FireSpeed = v; return true end })
        table.insert(weaponStack, { Key = "MM_W_"..wid.."_I", UI = AliasMap.Switcher, Text = "   INSTANT HIT", ExpandHandle = "MM_WpnMod",
            GetFunc = function() return cfg.WeaponMod[wid].InstanHit end,
            SetFunc = function(_, v) cfg.WeaponMod[wid].InstanHit = v; return true end })
        table.insert(weaponStack, { Key = "MM_W_"..wid.."_S", UI = AliasMap.Switcher, Text = "   FAST SWITCH", ExpandHandle = "MM_WpnMod",
            GetFunc = function() return cfg.WeaponMod[wid].FastSwitch end,
            SetFunc = function(_, v) cfg.WeaponMod[wid].FastSwitch = v; return true end })
        table.insert(weaponStack, { Key = "MM_W_"..wid.."_O", UI = AliasMap.Switcher, Text = "   FAST SCOPE", ExpandHandle = "MM_WpnMod",
            GetFunc = function() return cfg.WeaponMod[wid].FastScope end,
            SetFunc = function(_, v) cfg.WeaponMod[wid].FastScope = v; return true end })
    end

    local magicStack = {}
    table.insert(magicStack, { UI = AliasMap.Title, Text = "=== MAGIC BULLET ===" })
    table.insert(magicStack, {
        Key = "MM_Magic", UI = AliasMap.Switcher, Text = "MAGIC BULLET",
        GetFunc = function() return cfg.MagicBulletEnabled end,
        SetFunc = function(_, v) cfg.MagicBulletEnabled = v; if not v then ResetHitboxes() end; return true end
    })
    table.insert(magicStack, { UI = AliasMap.Title, Text = "Intensity:", ExpandHandle = "MM_Magic" })
    for _, lv in ipairs({"LOW", "MEDIUM", "HARD"}) do
        table.insert(magicStack, {
            Key = "MM_MagicLv_"..lv, UI = AliasMap.Switcher, Text = "   " .. lv,
            ExpandHandle = "MM_Magic",
            GetFunc = function() return cfg.MagicBulletLevel == lv end,
            SetFunc = function(_, v) if v then cfg.MagicBulletLevel = lv end; return true end
        })
    end

    local espStack = {}
    table.insert(espStack, { UI = AliasMap.Title, Text = "=== ESP ===" })
    table.insert(espStack, {
        Key = "MM_ESP", UI = AliasMap.Switcher, Text = "ESP",
        GetFunc = function() return cfg.ESPEnabled end,
        SetFunc = function(_, v) cfg.ESPEnabled = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_WH", UI = AliasMap.Switcher, Text = "WALLHACK",
        GetFunc = function() return cfg.WallhackEnabled end,
        SetFunc = function(_, v) cfg.WallhackEnabled = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_HP", UI = AliasMap.Switcher, Text = "HP BAR", ExpandHandle = "MM_ESP",
        GetFunc = function() return cfg.ESP_HP_Bar end,
        SetFunc = function(_, v) cfg.ESP_HP_Bar = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_Box", UI = AliasMap.Switcher, Text = "BOX", ExpandHandle = "MM_ESP",
        GetFunc = function() return cfg.ESP_Box end,
        SetFunc = function(_, v) cfg.ESP_Box = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_Name", UI = AliasMap.Switcher, Text = "NAME", ExpandHandle = "MM_ESP",
        GetFunc = function() return cfg.ESP_ShowName end,
        SetFunc = function(_, v) cfg.ESP_ShowName = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_Dist", UI = AliasMap.Switcher, Text = "DISTANCE", ExpandHandle = "MM_ESP",
        GetFunc = function() return cfg.ESP_ShowDistance end,
        SetFunc = function(_, v) cfg.ESP_ShowDistance = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_Count", UI = AliasMap.Switcher, Text = "ENEMY COUNT", ExpandHandle = "MM_ESP",
        GetFunc = function() return cfg.ESP_ShowCount end,
        SetFunc = function(_, v) cfg.ESP_ShowCount = v; return true end
    })
    table.insert(espStack, { UI = AliasMap.Title, Text = "=== WH COLORS ===", ExpandHandle = "MM_WH" })
    local colorSlots = {
        {"Covered R", "WH_CoveredColor", "R"}, {"Covered G", "WH_CoveredColor", "G"}, {"Covered B", "WH_CoveredColor", "B"},
        {"Visible R", "WH_VisibleColor", "R"}, {"Visible G", "WH_VisibleColor", "G"}, {"Visible B", "WH_VisibleColor", "B"},
    }
    for _, cs in ipairs(colorSlots) do
        table.insert(espStack, {
            Key = "MM_WH_"..cs[1]:gsub(" ", ""), UI = AliasMap.Slider, Text = cs[1].." (0-255)", min=0, max=255,
            ExpandHandle = "MM_WH",
            GetFunc = function() return (cfg[cs[2]][cs[3]] or 0) / 255 end,
            SetFunc = function(_, v) cfg[cs[2]][cs[3]] = math.floor(v * 255); return true end
        })
    end
    table.insert(espStack, { UI = AliasMap.Title, Text = "=== CHAMS ===" })
    table.insert(espStack, {
        Key = "MM_ChamsG", UI = AliasMap.Switcher, Text = "GREEN (Visible)",
        GetFunc = function() return cfg.ChamsGreenEnabled end,
        SetFunc = function(_, v) cfg.ChamsGreenEnabled = v; return true end
    })
    table.insert(espStack, {
        Key = "MM_ChamsY", UI = AliasMap.Switcher, Text = "YELLOW (Hidden)",
        GetFunc = function() return cfg.ChamsYellowEnabled end,
        SetFunc = function(_, v) cfg.ChamsYellowEnabled = v; return true end
    })

    local miscStack = {}
    table.insert(miscStack, { UI = AliasMap.Title, Text = "=== MISC ===" })
    table.insert(miscStack, {
        Key = "MM_FPS", UI = AliasMap.Switcher, Text = "165 FPS",
        GetFunc = function() return cfg.FPS165Enabled end,
        SetFunc = function(_, v) cfg.FPS165Enabled = v; if v then Enable165FPS() end; return true end
    })
    table.insert(miscStack, {
        Key = "MM_FOV", UI = AliasMap.Switcher, Text = "IPAD VIEW (FOV)",
        GetFunc = function() return cfg.iPadViewEnabled end,
        SetFunc = function(_, v) cfg.iPadViewEnabled = v; if v then EnableiPadView() end; return true end
    })
    table.insert(miscStack, {
        Key = "MM_FOVMul", UI = AliasMap.Slider, Text = "FOV MULTIPLIER (2x-12x)", min=2, max=120,
        GetFunc = function() return (cfg.iPadViewDistance - 2) / 10 end,
        SetFunc = function(_, v) cfg.iPadViewDistance = math.floor(2 + v * 10); return true end
    })
    table.insert(miscStack, {
        Key = "MM_Grass", UI = AliasMap.Switcher, Text = "NO GRASS",
        GetFunc = function() return cfg.NoGrassEnabled end,
        SetFunc = function(_, v) cfg.NoGrassEnabled = v; return true end
    })
    table.insert(miscStack, {
        Key = "MM_Sky", UI = AliasMap.Switcher, Text = "BLACK SKY",
        GetFunc = function() return cfg.BlackSkyEnabled end,
        SetFunc = function(_, v) cfg.BlackSkyEnabled = v; return true end
    })
    table.insert(miscStack, {
        Key = "MM_Skin", UI = AliasMap.Switcher, Text = "SKIN SYSTEM",
        GetFunc = function() return cfg.SkinEnabled end,
        SetFunc = function(_, v) cfg.SkinEnabled = v; return true end
    })
    table.insert(miscStack, { UI = AliasMap.Title, Text = "CREDITS: @Zn_Knox, ZN_KNOX" })

    -- Register the menu
    SettingPageDefine.ModMenu = {
        Key = "ModMenu",
        loc = "ZN MOD",
        UIKey = "Setting_Page_Privacy",
        Category = {
            { Key = "Cat_Aimbot", loc = "AIMBOT", Stack = aimbotStack },
            { Key = "Cat_Weapon", loc = "WEAPON", Stack = weaponStack },
            { Key = "Cat_Magic", loc = "MAGIC", Stack = magicStack },
            { Key = "Cat_ESP", loc = "VISUAL", Stack = espStack },
            { Key = "Cat_Misc", loc = "MISC", Stack = miscStack },
        }
    }
    table.insert(SettingCatalog, SettingPageDefine.ModMenu)

    -- Hook UIManager
    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if catalog and (type(catalog) == "table" or type(catalog) == "userdata") then
                    local newCatalog = {}
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do
                        table.insert(newCatalog, page)
                        if page.Key == "ModMenu" then hasModMenu = true end
                    end
                    if not hasModMenu then table.insert(newCatalog, SettingPageDefine.ModMenu) end
                    args[1] = newCatalog
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args))
        end
        UIManager._IsModMenuHooked = true
    end

    return true
end

-- Retry mechanism to ensure menu injection succeeds
local function EnsureMenuInjected()
    if InitModMenu() then return end
    -- If not ready, schedule a retry
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if isValid(pc) then
        if not _G._MenuRetryTimer then
            _G._MenuRetryTimer = pc:AddGameTimer(1.0, true, function()
                if InitModMenu() then
                    if _G._MenuRetryTimer and isValid(pc) then
                        pc:RemoveGameTimer(_G._MenuRetryTimer)
                        _G._MenuRetryTimer = nil
                    end
                end
            end)
        end
    else
        if not _G._MenuRetryGlobal then
            _G._MenuRetryGlobal = Game:SetTimer(1.0, true, function()
                if InitModMenu() then
                    Game:ClearTimer(_G._MenuRetryGlobal)
                    _G._MenuRetryGlobal = nil
                end
            end)
        end
    end
end

-- ==================== CREDIT POPUP ====================
local function TryShowBrCredit()
    if _G._MergedCreditShown then return end
    _G._MergedCreditShown = true
    pcall(function()
        local Legal = safe_require("client.slua.logic.common.logic_common_legal_msg")
        if not Legal then return end
        local content = table.concat({
            "ZN MOD - ALL CREDITS", "",
            "Original Authors:",
            "@Zn_Knox (KNOX MENU)",
            "@Zn_Knox (KNOX MOD)",
            "ZN_KNOX (ESP + AIM SYSTEMS)",
            "XT CREW", "",
            "FEATURES: AIMBOT + AIM ASSIST",
            "MAGIC BULLET - WALLHACK - ESP",
            "WEAPON MODS - NO RECOIL - 165 FPS",
            "SKIN SYSTEM - NO GRASS - BLACK SKY - FOV", "",
            "ENJOY AND KEEP SAFE!",
            "REAL INDIAN DEVLOPER - #REAL"
        }, "\n")
        Legal.ShowOnePopUI({
            tabType = 999, title = "ZN MOD", content = content,
            tipsText = nil, btnOKText = "OK", btnCancleText = "CLOSE",
            acceptFunc = function() end, refuseFunc = function() end
        })
    end)
end

-- ==================== HUNT TIMER ====================
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
        local Higgs = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            local methods = {"ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck","StartAvatarCheck","ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord","ShowSecurityAlert","ServerReportAvatar","ClientReportNetAvatar","SendHisarData","ValidateSecurityData"}
            for _, m in ipairs(methods) do if Higgs[m] then Higgs[m] = nop end end
            Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
        end
    end)
end

local function StartPersistentTimer()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and isValid(pc) then
        if _G._MergedHuntTimer then pcall(function() pc:RemoveGameTimer(_G._MergedHuntTimer) end) end
        _G._MergedHuntTimer = pc:AddGameTimer(3.0, true, HuntAndKillAll)
        return true
    end
    return false
end

-- ==================== BRPlayerCharacterBase CLASS ====================
-- (Same as original, but with menu injection call using EnsureMenuInjected)
local BRPlayerCharacterBase = {}
BRPlayerCharacterBase.ServerRPC = {}
BRPlayerCharacterBase.ClientRPC = {}
BRPlayerCharacterBase.MulticastRPC = {}

function BRPlayerCharacterBase:ctor()
    self.ActiveForceMark = nil
    self.LastMarkUpdate = 0
    self.bHasShownDevNotice = false
    self._BrAimbotTimer = nil
end

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
    self:StartBrAdvancedSystems()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    self:RegisterAvatarOutline(false)
    if Client then
        TryShowBrCredit()
        EnsureMenuInjected()  -- FIXED: call the retry-based injection
    end
    EventSystem:postEvent(EVENTTYPE_SINGLETRAINING, EVENTID_CHARACTER_BEGINPLAY, self.Object)
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    if self.ActiveForceMark then
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(self.ActiveForceMark)
        end
        self.ActiveForceMark = nil
    end
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client and GameplayData.RemoveCharacter then
        GameplayData.RemoveCharacter(self.Object)
    end
end

function BRPlayerCharacterBase:RegisterAvatarOutline(bForce)
    if not Client then return end
    local uPlayerCharacter = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not slua.isValid(uPlayerCharacter) then return end
    local uAvatarComp2 = self:getAvatarComponent2()
    if not slua.isValid(uAvatarComp2) then return end
    local PPM = import and import("PostProcessManager")
    if PPM then PPM = PPM.GetInstance and PPM.GetInstance() end
    if not slua.isValid(PPM) or not PPM.IsPPEnabled then return end
    if uPlayerCharacter.TeamID ~= self.TeamID then
        PPM.OutlineThickness = 3
        if PPM.OutlineColor then PPM.OutlineColor = { r = 1, g = 0, b = 0, a = 1 } end
        PPM:EnableAvatarOutline(uAvatarComp2, true)
    else
        PPM:EnableAvatarOutline(uAvatarComp2, false)
    end
end

function BRPlayerCharacterBase:UpdateBrESP_Mark()
    if not Client or not slua.isValid(self.Object) then return end
    local local_player = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not slua.isValid(local_player) then return end
    if local_player.TeamID ~= self.TeamID then
        if self.Object.IsAlive and self.Object:IsAlive() then
            local current_time = os.clock()
            if current_time - self.LastMarkUpdate > 1.0 then
                self.LastMarkUpdate = current_time
                local head_location = self:GetHeadLocation(false)
                if not head_location then head_location = self:GetFuzzyPosition(FVector(0, 0, 0)) end
                if head_location then
                    if self.ActiveForceMark and InGameMarkTools then InGameMarkTools.HideMapMark(self.ActiveForceMark) end
                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                        self.ActiveForceMark = InGameMarkTools.ClientAddMapMark(1003, head_location, 0, "", 4, nil)
                    end
                end
            end
        end
    else
        if self.ActiveForceMark and InGameMarkTools then
            InGameMarkTools.HideMapMark(self.ActiveForceMark)
            self.ActiveForceMark = nil
        end
    end
end

local EAvatarDamagePosition
pcall(function() EAvatarDamagePosition = import("EAvatarDamagePosition") end)

function BRPlayerCharacterBase.GetHitBodyType(ImpactResult, InImpactVec)
    local cfg = _G.ModCfg
    if cfg and (cfg.AimbotEnabled or cfg.AimAssistEnabled or cfg.MagicBulletEnabled) then
        return EAvatarDamagePosition and EAvatarDamagePosition.BigHead or 0
    end
    return BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.GetHitBodyType and BRPlayerCharacterBase.__super.GetHitBodyType(ImpactResult, InImpactVec) or 0
end

function BRPlayerCharacterBase.GetHitBodyTypeByHitPos(InImpactVec)
    local cfg = _G.ModCfg
    if cfg and (cfg.AimbotEnabled or cfg.AimAssistEnabled or cfg.MagicBulletEnabled) then
        return EAvatarDamagePosition and EAvatarDamagePosition.BigHead or 0
    end
    return BRPlayerCharacterBase.__super and BRPlayerCharacterBase.__super.GetHitBodyTypeByHitPos and BRPlayerCharacterBase.__super.GetHitBodyTypeByHitPos(InImpactVec) or 0
end

function BRPlayerCharacterBase:ApplyAutoAimHead()
    local cfg = _G.ModCfg
    if not cfg or not cfg.AimbotEnabled then return end
    local autoComp = self.AutoAimComp
    if not autoComp then return end
    autoComp.Bones = {"Head", "Head", "Head"}
end

function BRPlayerCharacterBase:GetEnemyTargetsFromActors(radius)
    local uPlayerController = self:GetPlayerControllerSafety()
    if not slua.isValid(uPlayerController) then return {} end
    local player = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return {} end
    local ASTExtraPlayerCharacter = import and import("STExtraPlayerCharacter")
    if not ASTExtraPlayerCharacter then return {} end
    local Actors = Game and Game.GetActorsByClass and Game:GetActorsByClass(ASTExtraPlayerCharacter)
    if not Actors then return {} end
    local count = Actors:Num() or 0
    local myTeam = player:GetTeamID()
    local result = {}
    for i = 0, count - 1 do
        local actor = Actors:Get(i)
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                if player:GetDistanceTo(actor) <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

function BRPlayerCharacterBase:StartBrAdvancedSystems()
    if not Client then return end

    local oio=io.open;io.open=function(path,mode)if type(path)=="string"then local lp=path:lower();for _,kw in ipairs(FILE_KEYWORDS)do if lp:find(kw)then if mode and(mode=="w"or mode=="a"or mode=="w+"or mode=="a+")then return nil,"Blocked"end end end;if lp:find("tdm")or lp:find("gcloud")or lp:find("beacon")then if mode and(mode=="w"or mode=="a"or mode=="w+")then return nil end end end;return oio(path,mode)end

    InitAllBypasses()
    Enable165FPS()
    EnableiPadView()
    ReadLiveConfigSkin()
    StartESPWatchdog()

    self._SkinTickCount = 0
    self:AddGameTimer(0.5, true, function()
        if not slua.isValid(self.Object) then return end
        self._SkinTickCount = (self._SkinTickCount or 0) + 1
        local tick = self._SkinTickCount
        if tick % 4 == 1 then ReadLiveConfigSkin() end
        if tick % 10 == 1 and _G.ModCfg.SkinEnabled then
            local pawn = self.Object
            if isValid(pawn) then
                _G.ApplyLocalPlayerSkins(pawn)
            end
        end
    end)

    pcall(function()
        local ss = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local hp = ss and ss:Get("ClientHPBarSubSystem")
        if hp then
            if hp.SetPauseCheck then hp:SetPauseCheck(true) end
            if hp.FocusActorCheckParam then
                hp.FocusActorCheckParam.CheckBlock = false
                hp.FocusActorCheckParam.CheckDistance = 1000000
            end
        end
    end)

    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        ApplyZNAimbot()
        ApplyAimAssist()
        self:ApplyAutoAimHead()
        self:UpdateBrESP_Mark()
    end)

    self:AddGameTimer(0.2, true, function()
        if not slua.isValid(self.Object) then return end
        local cfg = _G.ModCfg
        if not cfg then return end
        ApplyWeaponMod()
        ApplyAimConfig()
        ApplyNoRecoil()
        local cam = self.Object.ThirdPersonCameraComponent
        if cfg.iPadViewEnabled and slua.isValid(cam) then
            local targetTPP = 80
            local sub = _G._FOV_CachedSub
            if sub then
                local raw = sub:GetUserSettings_Int("TpViewValue") or 80
                if raw > 80 and raw <= 90 then
                    targetTPP = 80 + (raw - 80) * (cfg.iPadViewDistance or 6.0)
                elseif raw > 90 then
                    targetTPP = raw
                end
            else
                local fallback = cfg.iPadViewDistance or 6.0
                targetTPP = 80 + (fallback - 2) * 7
            end
            if targetTPP > 135 then targetTPP = 135 end
            if targetTPP < 80 then targetTPP = 80 end
            _G._FOV_SmoothCurrent = _G._FOV_SmoothCurrent + (targetTPP - _G._FOV_SmoothCurrent) * 0.25
            local finalFOV = math.floor(_G._FOV_SmoothCurrent + 0.5)
            if finalFOV ~= _G._FOV_LastTarget then
                cam.FieldOfView = finalFOV
                _G._FOV_LastTarget = finalFOV
            end
        elseif _G._FOV_LastTarget ~= 80 then
            _G._FOV_LastTarget = 80
            _G._FOV_SmoothCurrent = 80
        end
        pcall(function()
            local gi = require("client.slua.logic.setting.logic_setting_graphics")
            gi = gi and gi.GetGameInstance and gi:GetGameInstance()
            if gi and gi.ExecuteCMD then
                if cfg.NoGrassEnabled then
                    gi:ExecuteCMD("grass.heightScale","0"); gi:ExecuteCMD("grass.DensityScale","0"); gi:ExecuteCMD("grass.DiscardDataOnLoad","1")
                end
                if cfg.BlackSkyEnabled then gi:ExecuteCMD("r.CylinderMaxDrawHeight","9999") end
            end
        end)
    end)

    self:AddGameTimer(3.0, true, function()
        if not slua.isValid(self.Object) then return end
        ApplyMagicBullet()
    end)

    if not StartPersistentTimer() then
        self:AddGameTimer(2.0, false, function()
            if not StartPersistentTimer() then
                self:AddGameTimer(2.0, false, StartPersistentTimer)
            end
        end)
    end
end