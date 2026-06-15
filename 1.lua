-- ===================================================
do
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if _G._BR_MOD_LOADED and _G._BR_MOD_PC == pc then return end
    _G._BR_MOD_LOADED = true
    _G._BR_MOD_PC = pc
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

local function ApplyZNAimbot()
    local cfg = _G.ModCfg
    if not cfg.AimbotEnabled then return end
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
        local strength = (cfg.AimbotStrength or 50) / 100
        entity.RecoilKickADS = 0.01 * (1 - strength * 0.9)
        entity.GameDeviationFactor = 0.01 * (1 - strength * 0.9)
        entity.GameDeviationAccuracy = 0.01 * (1 - strength * 0.9)
        entity.ExtraHitPerformScale = 2 + strength * 4
        if entity.AutoAimingConfig then
            for _, range in ipairs({"OuterRange", "InnerRange"}) do
                local acfg = entity.AutoAimingConfig[range]
                if acfg then
                    acfg.Speed = 1 + strength * 0.9
                    acfg.RangeRate = 1 + strength * 0.8
                    acfg.SpeedRate = 1 + strength * 0.7
                    acfg.RangeRateSight = 1 + strength * 0.6
                    acfg.SpeedRateSight = 1 + strength * 0.5
                    acfg.CrouchRate = 1 + strength * 0.4
                    acfg.ProneRate = 1 + strength * 0.3
                    acfg.DyingRate = 0
                    acfg.adsorbMaxRange = 50 + strength * 150
                    acfg.adsorbMinRange = 20
                    acfg.adsorbMinAttenuationDis = 50 + strength * 50
                    acfg.adsorbMaxAttenuationDis = 8000
                    acfg.adsorbActiveMinRange = 20
                end
            end
        end
        local target = cfg.AimbotTarget or "Head"
        pcall(function()
            local aimComp = char.BP_AutoAimingComponent_C or char.BP_AutoAimingComponent or char.AutoAimingComponent
            if isValid(aimComp) and aimComp.Bones then
                pcall(function() aimComp.Bones[0] = target end)
                pcall(function() aimComp.Bones[1] = target end)
                pcall(function() aimComp.Bones[2] = target end)
                pcall(function() aimComp.Bones:Set(0, target) end)
                pcall(function() aimComp.Bones:Set(1, target) end)
                pcall(function() aimComp.Bones:Set(2, target) end)
            end
        end)
    end)
end

local function ApplyAimAssist()
    local cfg = _G.ModCfg
    if not cfg.AimAssistEnabled then return end
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
        local aa = entity.AutoAimingConfig
        if not aa then return end
        local strength = (cfg.AimAssistStrength or 50) / 100
        local multiplier = 0.3 + strength * 0.7
        for _, range in ipairs({"OuterRange", "InnerRange"}) do
            local acfg = aa[range]
            if acfg then
                acfg.Speed = 1.5 * multiplier
                acfg.RangeRate = 1.2 * multiplier
                acfg.SpeedRate = 1.3 * multiplier
                acfg.RangeRateSight = 1.2 * multiplier
                acfg.SpeedRateSight = 1.3 * multiplier
                acfg.CenterSpeedRate = 1.5 * multiplier
                acfg.CrouchRate = 1.0
                acfg.ProneRate = 1.0
                acfg.DyingRate = 0.5
                acfg.adsorbMaxRange = 80 * multiplier
                acfg.adsorbMinRange = 30
                acfg.adsorbMinAttenuationDis = 100 * multiplier
                acfg.adsorbMaxAttenuationDis = 6000
                acfg.adsorbActiveMinRange = 20
            end
        end
    end)
end

local function ApplyWeaponMod()
    local cfg = _G.ModCfg
    if not cfg.WeaponModEnabled then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not isValid(player) then return end
        local weaponManager = player.WeaponManagerComponent
        if not isValid(weaponManager) then return end
        local currentWeapon = weaponManager.CurrentWeaponReplicated
        if not isValid(currentWeapon) then return end
        local shootComp = currentWeapon.ShootWeaponEntityComp
        if not isValid(shootComp) then return end
        local wid = shootComp.WeaponID
        if type(wid) ~= "number" then return end
        local wcfg = cfg.WeaponMod[wid]
        if not wcfg then return end
        if wcfg.FireSpeed then shootComp.ShootInterval = 0.07 end
        if wcfg.InstanHit then
            local bulletSpeeds = {
                [101001]=120000,[101002]=110000,[101003]=130000,[101004]=130000,
                [101005]=130000,[101006]=130000,[101007]=130000,[101008]=130000,
                [101009]=130000,[101010]=130000
            }
            shootComp.BulletFireSpeed = bulletSpeeds[wid] or 130000
        end
        if wcfg.FastSwitch then shootComp.SwitchFromIdleToBackpackTime = 0; shootComp.SwitchFromBackpackToIdleTime = 0 end
        if wcfg.FastScope then shootComp.WeaponAimInTime = 7 end
    end)
end

local function ApplyAimConfig()
    local cfg = _G.ModCfg
    if not cfg.AimConfigEnabled then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not isValid(player) then return end
        local wm = player.WeaponManagerComponent
        if not isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not isValid(weapon) then return end
        local sc = weapon.ShootWeaponEntityComp
        if not sc then return end
        local aa = sc.AutoAimingConfig
        if not aa then return end
        if not cfg.AimConfigEnabled then
            if aa.OuterRange.Speed == 3.5 then return end
            local d = {S=3.5,SR=1,RR=1,RRS=1,SRS=1,CSR=1,CR=0.5,PR=0.10,DR=1,GDF=0}
            aa.OuterRange.Speed=d.S; aa.InnerRange.Speed=d.S
            aa.OuterRange.SpeedRate=d.SR; aa.InnerRange.SpeedRate=d.SR
            aa.OuterRange.RangeRate=d.RR; aa.InnerRange.RangeRate=d.RR
            aa.OuterRange.RangeRateSight=d.RRS; aa.InnerRange.RangeRateSight=d.RRS
            aa.OuterRange.SpeedRateSight=d.SRS; aa.InnerRange.SpeedRateSight=d.SRS
            aa.OuterRange.CenterSpeedRate=d.CSR; aa.InnerRange.CenterSpeedRate=d.CSR
            aa.OuterRange.CrouchRate=d.CR; aa.InnerRange.CrouchRate=d.CR
            aa.OuterRange.ProneRate=d.PR; aa.InnerRange.ProneRate=d.PR
            aa.OuterRange.DyingRate=d.DR; aa.InnerRange.DyingRate=d.DR
            sc.GameDeviationFactor = d.GDF
            return
        end
        local level = cfg.AimConfigLevel or "MEDIUM"
        local configs = {
            LOW     = {S=5,SR=5,RR=1,RRS=1,SRS=5,CSR=3,CR=1,PR=1,DR=0,GDF=0},
            MEDIUM  = {S=7,SR=7,RR=2,RRS=2,SRS=7,CSR=5,CR=2,PR=2,DR=0,GDF=0},
            HARD    = {S=10,SR=10,RR=10,RRS=10,SRS=10,CSR=7,CR=2,PR=2,DR=0,GDF=0},
            EXTREME = {S=50,SR=20,RR=20,RRS=20,SRS=20,CSR=15,CR=5,PR=5,DR=0,GDF=0}
        }
        local c = configs[level] or configs.MEDIUM
        aa.OuterRange.Speed=c.S; aa.InnerRange.Speed=c.S
        aa.OuterRange.SpeedRate=c.SR; aa.InnerRange.SpeedRate=c.SR
        aa.OuterRange.RangeRate=c.RR; aa.InnerRange.RangeRate=c.RR
        aa.OuterRange.RangeRateSight=c.RRS; aa.InnerRange.RangeRateSight=c.RRS
        aa.OuterRange.SpeedRateSight=c.SRS; aa.InnerRange.SpeedRateSight=c.SRS
        aa.OuterRange.CenterSpeedRate=c.CSR; aa.InnerRange.CenterSpeedRate=c.CSR
        aa.OuterRange.CrouchRate=c.CR; aa.InnerRange.CrouchRate=c.CR
        aa.OuterRange.ProneRate=c.PR; aa.InnerRange.ProneRate=c.PR
        aa.OuterRange.DyingRate=c.DR; aa.InnerRange.DyingRate=c.DR
        sc.GameDeviationFactor = c.GDF
    end)
end

local function ApplyNoRecoil()
    local cfg = _G.ModCfg
    if not cfg.NoRecoilEnabled then return end
    pcall(function()
        local player = GameplayData.GetPlayerCharacter()
        if not isValid(player) then return end
        local wm = player.WeaponManagerComponent
        if not isValid(wm) then return end
        local weapon = wm.CurrentWeaponReplicated
        if not isValid(weapon) then return end
        local sc = weapon.ShootWeaponEntityComp
        if not sc then return end
        local level = cfg.RecoilLevel or "LESS"
        local r = sc.RecoilInfo
        if level == "DEFAULT" then
            sc.RecoilKickADS = 0.2
            sc.AccessoriesHRecoilFactor = 0.5; sc.AccessoriesRecoveryFactor = 0.6; sc.AccessoriesVRecoilFactor = 0.5
            if r then
                r.VerticalRecoilMin=0; r.VerticalRecoilMax=7; r.VerticalRecoveryMax=5
                r.RecoilValueClimb=0.75; r.RecoilValueFail=2.2; r.VerticalRecoveryModifier=0.5
                r.RecovertySpeedVertical=9; r.VerticalRecoveryClamp=10
                r.LeftMax=-0.8; r.RightMax=0.8; r.HorizontalTendency=0.1
                r.RecoilHorizontalMinScalar=0.1; r.RecoilSpeedHorizontal=11; r.RecoilSpeedVertical=11
            end
        elseif level == "LESS" then
            sc.RecoilKickADS = 0
            sc.AccessoriesHRecoilFactor = 0.2; sc.AccessoriesRecoveryFactor = 0.2; sc.AccessoriesVRecoilFactor = 0.2
            if r then
                r.VerticalRecoilMin=0; r.VerticalRecoilMax=2; r.VerticalRecoveryMax=2
                r.RecoilValueClimb=0.2; r.RecoilValueFail=2; r.VerticalRecoveryModifier=0.2
                r.RecovertySpeedVertical=2; r.VerticalRecoveryClamp=2
                r.LeftMax=-0.2; r.RightMax=0.2; r.HorizontalTendency=0.1
                r.RecoilHorizontalMinScalar=0.1; r.RecoilSpeedHorizontal=2; r.RecoilSpeedVertical=2
            end
        elseif level == "NO" then
            sc.RecoilKickADS = 0
            sc.AccessoriesHRecoilFactor = 0; sc.AccessoriesRecoveryFactor = 0; sc.AccessoriesVRecoilFactor = 0
            if r then
                r.VerticalRecoilMin=0; r.VerticalRecoilMax=0; r.VerticalRecoveryMax=0
                r.RecoilValueClimb=0; r.RecoilValueFail=0; r.VerticalRecoveryModifier=0
                r.RecovertySpeedVertical=0; r.VerticalRecoveryClamp=0
                r.LeftMax=0; r.RightMax=0; r.HorizontalTendency=0
                r.RecoilHorizontalMinScalar=0; r.RecoilSpeedHorizontal=0; r.RecoilSpeedVertical=0
            end
        end
        if cfg.NoShakeEnabled then sc.AnimationKick = 0 end
    end)
end

local function ResetHitboxes()
    pcall(function()
        local allChars = Game:GetAllPlayerPawns()
        if allChars then
            for _, enemy in pairs(allChars) do
                if isValid(enemy) and isValid(enemy.Mesh) then
                    enemy.Mesh:RecreatePhysicsState()
                    enemy.Mesh:UpdateBounds()
                end
            end
        end
        _G._MBones = {}
    end)
end

local function ApplyMagicBullet()
    local cfg = _G.ModCfg
    if not cfg.MagicBulletEnabled then
        if _G._MBones and next(_G._MBones) ~= nil then ResetHitboxes() end
        return
    end
    pcall(function()
        local allChars = Game:GetAllPlayerPawns()
        if not allChars then return end
        _G._MBones = _G._MBones or {}
        _G._MagicTick = (_G._MagicTick or 0) + 1
        if _G._MagicTick >= 60 then _G._MBones = {}; _G._MagicTick = 0 end
        local levelStr = cfg.MagicBulletLevel or "MEDIUM"
        local lvMap = { LOW = 0.75, MEDIUM = 1.0, HARD = 1.5 }
        local lvMult = lvMap[levelStr] or 1.0
        local char = GameplayData.GetPlayerCharacter()
        for _, c in pairs(allChars) do
            pcall(function()
                if c == char or (c.TeamID and char and c.TeamID == char.TeamID) then return end
                local mesh = c.Mesh
                if not slua.isValid(mesh) then return end
                local physAsset = mesh.PhysicsAssetOverride
                if not slua.isValid(physAsset) and slua.isValid(mesh.SkeletalMesh) then
                    physAsset = mesh.SkeletalMesh.PhysicsAsset
                end
                if not slua.isValid(physAsset) or not physAsset.SkeletalBodySetups then return end
                local assetName = (physAsset.GetName and physAsset:GetName()) or tostring(physAsset)
                if _G._MBones[assetName] then return end
                local baseMap = {
                    ["head"] = 0, ["neck_01"] = 150, ["pelvis"] = 150,
                    ["spine_01"] = 150, ["spine_02"] = 150, ["spine_03"] = 150,
                    ["upperarm_l"] = 150, ["upperarm_r"] = 150,
                    ["lowerarm_l"] = 130, ["lowerarm_r"] = 130,
                    ["hand_l"] = 100, ["hand_r"] = 100,
                    ["thigh_l"] = 150, ["thigh_r"] = 150,
                    ["calf_l"] = 130, ["calf_r"] = 130,
                    ["foot_l"] = 100, ["foot_r"] = 100,
                }
                local setups = physAsset.SkeletalBodySetups
                for i = 1, 80 do
                    pcall(function()
                        local bs = (type(setups.Get) == "function") and setups:Get(i-1) or setups[i]
                        if not bs or not slua.isValid(bs) then return end
                        local bn = tostring(bs.BoneName):lower()
                        local pct = nil
                        for pat, val in pairs(baseMap) do
                            if string.find(bn, pat) then pct = val * lvMult; break end
                        end
                        if not pct then return end
                        local sc = 1.0 + pct / 100.0
                        local ag = bs.AggGeom
                        pcall(function()
                            local bx = (ag and ag.BoxElems) or bs.BoxElems
                            if bx then
                                local b = (type(bx.Get) == "function") and bx:Get(0) or bx[1]
                                if b then
                                    b.X = (b.X or 30) * sc
                                    b.Y = (b.Y or 30) * sc
                                    b.Z = (b.Z or 60) * sc
                                    if type(bx.Set) == "function" then bx:Set(0, b) else bx[1] = b end
                                    if ag then bs.AggGeom = ag else bs.BoxElems = bx end
                                end
                            end
                        end)
                        pcall(function()
                            local sp = (ag and ag.SphylElems) or bs.SphylElems
                            if sp then
                                local s = (type(sp.Get) == "function") and sp:Get(0) or sp[1]
                                if s then
                                    if s.Radius then s.Radius = s.Radius * sc end
                                    if s.Length then s.Length = s.Length * sc end
                                    if type(sp.Set) == "function" then sp:Set(0, s) else sp[1] = s end
                                    if ag then bs.AggGeom = ag else bs.SphylElems = sp end
                                end
                            end
                        end)
                        pcall(function()
                            local sr = (ag and ag.SphereElems) or bs.SphereElems
                            if sr then
                                local r = (type(sr.Get) == "function") and sr:Get(0) or sr[1]
                                if r and r.Radius then
                                    r.Radius = r.Radius * sc
                                    if type(sr.Set) == "function" then sr:Set(0, r) else sr[1] = r end
                                    if ag then bs.AggGeom = ag else bs.SphereElems = sr end
                                end
                            end
                        end)
                    end)
                end
                pcall(function() mesh:RecreatePhysicsState(); mesh:WakeAllRigidBodies(); mesh:UpdateBounds() end)
                _G._MBones[assetName] = true
            end)
        end
    end)
end

-- ==================== ESP / WALLHACK (OPTIMIZED - NO BLINK) ====================

-- Cache for wallhack materials to prevent re-application
_G._WHMaterialCache = _G._WHMaterialCache or {}
_G._WHLastStateCache = _G._WHLastStateCache or {}

local function ApplyWallHack(enemy, pc)
    local cfg = _G.ModCfg
    if not cfg.WallhackEnabled then return end
    if not isValid(enemy) then return end
    
    -- Check if visibility state changed to avoid unnecessary reapplies
    local isVisible = false
    if isValid(pc) and isValid(enemy) and type(pc.LineOfSightTo) == "function" then
        pcall(function() isVisible = pc:LineOfSightTo(enemy) end)
    end
    
    local enemyKey = tostring(enemy)
    local stateChanged = (_G._WHLastStateCache[enemyKey] ~= isVisible)
    if not stateChanged and _G._WHMaterialCache[enemyKey] then
        return -- No change, skip reapplication
    end
    _G._WHLastStateCache[enemyKey] = isVisible
    
    local meshes = {}
    pcall(function()
        if isValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
        local SkelClass = import("SkeletalMeshComponent")
        if SkelClass then
            local childs = enemy:GetComponentsByClass(SkelClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for c = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(c-1) or childs[c]
                    if isValid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    
    pcall(function()
        local finalBodyColor = isVisible and cfg.WH_VisibleColor or cfg.WH_CoveredColor
        local finalGlowColor = isVisible and cfg.WH_VisibleGlow or cfg.WH_CoveredGlow
        local scale = {R=8, G=8, B=0, A=0}
        
        for _, comp in ipairs(meshes) do
            if isValid(comp) then
                pcall(function()
                    comp.bRenderCustomDepth = true
                    comp.CustomDepthStencilValue = 250
                    comp.CustomDepthStencilWriteMask = 255
                end)
                
                local ok, mat = pcall(function() return comp:GetMaterial(0) end)
                if ok and isValid(mat) then
                    local ok2, base = pcall(function() return mat:GetBaseMaterial() end)
                    if ok2 and isValid(base) then
                        if base.bDisableDepthTest ~= true then base.bDisableDepthTest = true end
                        if base.BlendMode ~= 2 then base.BlendMode = 2 end
                    end
                end
                
                comp.UseScopeDistanceCulling = false
                comp.PrimitiveShadingStrategy = 1
                comp.ShadingRate = 6
                
                local compKey = tostring(comp)
                _G._WHMaterialCache[enemyKey] = _G._WHMaterialCache[enemyKey] or {}
                
                for i = 0, 3 do -- Only first 4 materials, enough for wallhack
                    local ok3, mi = pcall(function() return comp:GetMaterial(i) end)
                    if not ok3 or not isValid(mi) then break end
                    
                    local mid = _G._WHMaterialCache[enemyKey][compKey.."_"..i]
                    if not isValid(mid) then
                        local ok4, nm = pcall(function() return comp:CreateAndSetMaterialInstanceDynamic(i) end)
                        if ok4 and isValid(nm) then 
                            _G._WHMaterialCache[enemyKey][compKey.."_"..i] = nm
                            mid = nm
                        end
                    end
                    
                    if isValid(mid) then
                        pcall(function()
                            local bodyParams = {"颜色","Extra Light Color","Para_Color","Para_ColorTint","Tint","Color","BaseColor","BodyColor","MainColor","DiffuseColor","EmissiveColor","SubsurfaceColor","AlbedoColor","SkinColor","BaseColorTint","FillColor","MaterialColor","TintColor","ColorTint","BodyTint","MainTint"}
                            local glowParams = {"GlowColor","HighlightColor","OutlineColor","FresnelColor","RimColor","Glow","SelfIlluminateColor","EmissiveLightColor","InnerGlowColor","OuterGlowColor","EdgeGlowColor","ScanGlowColor","HologramColor","NeonColor","BloomColor","RadianceColor","FlareColor","LightColor","EmissionColor","EmissiveColor","BloomTint"}
                            local glowScalars = {"Glow","GlowAmount","GlowIntensity","GlowPower","GlowStrength","GlowBoost","HighlightPower","HighlightIntensity","EmissiveBoost","EmissiveStrength","RimPower","RimIntensity","RimStrength","FresnelPower","FresnelIntensity","OutlineStrength","OutlineThickness","SelfIlluminate","SelfIllumination","Brightness","Opacity","Intensity","GlowScale","EmissionStrength","BloomIntensity","Radiance","LightIntensity","GlowBrightness"}
                            
                            for _, p in ipairs(bodyParams) do pcall(function() mid:SetVectorParameterValue(p, finalBodyColor) end) end
                            for _, p in ipairs(glowParams) do pcall(function() mid:SetVectorParameterValue(p, finalGlowColor) end) end
                            for _, p in ipairs(glowScalars) do pcall(function() mid:SetScalarParameterValue(p, 25.0) end) end
                            pcall(function() mid:SetVectorParameterValue("ParaScaleOffset", scale) end)
                        end)
                    end
                end
            end
        end
    end)
end

-- ESP Cache for persistent text (prevents blinking)
_G._ESPTextCache = _G._ESPTextCache or {}
_G._ESPFrameCounter = 0

local cachedPawns = {}
local lastPawnRefresh = 0
local boneList = {"head"} -- Only head bone for performance!

local function IsPawnAlive(p)
    if not isValid(p) then return false end
    if p.HealthStatus and _G.SecurityCommonUtils then return _G.SecurityCommonUtils.IsHealthStatusAlive(p.HealthStatus) end
    if p.IsAlive then return p:IsAlive() end
    return p.GetHealth and (p:GetHealth() or 0) > 0 or false
end

local function TextScale(distM)
    local t = math.min(distM / 400, 1)
    return 0.35 - t * 0.2
end

local function HPBar(pct)
    local n = math.floor((pct * 4) + 0.5)
    local s = ""
    for i = 1, 4 do s = s .. (i <= n and "|" or " ") end
    return s
end

-- Dynamic ESP interval based on player count
local function GetDynamicESPInterval()
    local totalPlayers = 0
    for _, p in pairs(cachedPawns) do
        if isValid(p) then totalPlayers = totalPlayers + 1 end
    end
    if totalPlayers > 40 then return 0.35
    elseif totalPlayers > 25 then return 0.25
    elseif totalPlayers > 15 then return 0.2
    else return 0.15 end
end

local function ESPTick()
    local cfg = _G.ModCfg
    if not cfg.ESPEnabled then return end
    
    _G._ESPFrameCounter = (_G._ESPFrameCounter or 0) + 1
    local frameMod = _G._ESPFrameCounter % 2 -- Alternate between updates to reduce load
    
    local ASTExtraPlayerController = import("/Script/ShadowTrackerExtra.STExtraPlayerController")
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
    pcall(function() if currentPawn.GetHeadLocation then myEyePos = currentPawn:GetHeadLocation(false) or myPos end end)
    
    local HUD = uCon:GetHUD()
    local now = os.clock()
    
    -- Refresh cache less frequently when crowded
    local refreshTime = 2.5
    if now - lastPawnRefresh > refreshTime then 
        lastPawnRefresh = now
        cachedPawns = Game:GetAllPlayerPawns() or {}
    end
    
    -- Count enemies for dynamic adjustment
    local totalAlive = 0
    local botCount = 0
    local playerCount = 0
    
    for _, p in pairs(cachedPawns) do
        if isValid(p) and p ~= currentPawn and p.TeamID ~= myTeamId and IsPawnAlive(p) then 
            totalAlive = totalAlive + 1
            local isBot = false
            pcall(function() isBot = Game:IsAI(p) end)
            if isBot then botCount = botCount + 1 else playerCount = playerCount + 1 end
        end
    end
    
    local crowded = totalAlive > 25
    local veryCrowded = totalAlive > 40
    
    -- Update ESP timer dynamically if needed
    if _G._ESPTimerHandle and _G._CurrentESPInterval ~= GetDynamicESPInterval() then
        -- Interval will be adjusted on next timer creation
    end
    
    for _, tPawn in pairs(cachedPawns) do
        if isValid(tPawn) and tPawn ~= currentPawn and tPawn.TeamID ~= myTeamId and IsPawnAlive(tPawn) then
            
            local enemyPos = tPawn:K2_GetActorLocation()
            local dx = enemyPos.X - myPos.X
            local dy = enemyPos.Y - myPos.Y
            local dz = enemyPos.Z - myPos.Z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            local distM = dist / 100
            
            -- Skip far enemies in very crowded situations
            if veryCrowded and distM > 150 then goto continue end
            
            if dist < 600000 and HUD then
                local name = tPawn.PlayerName or "UNKNOWN"
                local hp = tPawn.Health
                local maxHp = tPawn.HealthMax
                local isKnock = false
                local hpPercent = 0
                
                if not hp or not maxHp or maxHp <= 0 then isKnock = true
                elseif hp <= 0 then isKnock = true 
                else hpPercent = hp / maxHp end
                
                local hpColor = {R=0,G=255,B=0,A=255}
                if isKnock then hpColor = {R=255,G=0,B=0,A=255}
                elseif hpPercent < 0.3 then hpColor = {R=255,G=0,B=0,A=255}
                elseif hpPercent < 0.7 then hpColor = {R=255,G=255,B=0,A=255} end
                
                -- Only get head position (optimized)
                local headPos = nil
                local mesh = tPawn.Mesh
                if isValid(mesh) then
                    headPos = mesh:GetSocketLocation("head")
                end
                
                local origin = enemyPos
                local oz = origin.Z
                local headZ = headPos and (headPos.Z - oz) or 90
                local hpOffset = headZ + 70 + math.min(distM, 60) * 3 + math.max(0, distM - 60) * 0.5
                local nameOffset = -80 - math.min(distM, 60) * 0.33 - math.max(0, distM - 60) * 0.1
                
                -- Wallhack - only apply on state change (already optimized in ApplyWallHack)
                if cfg.WallhackEnabled then 
                    pcall(ApplyWallHack, tPawn, uCon)
                end
                
                -- ESP rendering with frame alternation to reduce load
                if frameMod == 0 or not veryCrowded then
                    if veryCrowded then
                        -- Very crowded: only show dot
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz and cfg.ESP_Box then
                            HUD:AddDebugText("●", tPawn, 0.2, {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true)
                        end
                    elseif crowded then
                        -- Crowded: show dot + HP
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz and cfg.ESP_Box then
                            HUD:AddDebugText("●", tPawn, 0.25, {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true)
                        end
                        if cfg.ESP_HP_Bar then
                            local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                            HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                        end
                    else
                        -- Normal: full ESP
                        local hz = headPos and (headPos.Z - oz + 15)
                        if hz and cfg.ESP_Box then
                            local headChar = distM <= 25 and "O" or "●"
                            HUD:AddDebugText(headChar, tPawn, TextScale(distM), {X=0,Y=0,Z=hz}, {X=0,Y=0,Z=hz}, {R=255,G=0,B=0,A=255}, true, false, true, nil, 1.0, true)
                        end
                        
                        if cfg.ESP_HP_Bar then
                            local hpText = isKnock and "DOWN" or HPBar(hpPercent)
                            HUD:AddDebugText(hpText, tPawn, TextScale(distM), {X=0,Y=0,Z=hpOffset}, {X=0,Y=0,Z=hpOffset}, hpColor, true, false, true, nil, 1.0, true)
                        end
                        
                        if cfg.ESP_ShowName or cfg.ESP_ShowDistance then
                            local nameColor = {R=0,G=255,B=0,A=255}
                            if cfg.ChamsGreenEnabled and cfg.ChamsYellowEnabled then
                                local targetPos = headPos or tPawn:K2_GetActorLocation()
                                local visible = false
                                pcall(function()
                                    if Game.IsTargetPosVisible then visible = Game:IsTargetPosVisible(myEyePos, targetPos, {currentPawn}) end
                                end)
                                if visible then nameColor = cfg.ChamsGreenRGB else nameColor = cfg.ChamsYellowRGB end
                            end
                            local text = ""
                            if cfg.ESP_ShowDistance then text = string.format("[%.0fm]", distM) end
                            if cfg.ESP_ShowName then text = text .. " " .. name end
                            HUD:AddDebugText(text, tPawn, TextScale(distM), {X=0,Y=0,Z=nameOffset}, {X=0,Y=0,Z=nameOffset}, nameColor, true, false, true, nil, 1.0, true)
                        end
                    end
                end
            end
        end
        ::continue::
    end
    
    -- Show count only when not crowded
    if not crowded and cfg.ESP_ShowCount and HUD and currentPawn then
        HUD:AddDebugText(string.format("BOT: %d  PLAYER: %d", botCount, playerCount), currentPawn, 1, {X=0,Y=0,Z=170}, {X=0,Y=0,Z=170}, {R=255,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
    end
end

-- Dynamic ESP timer that adjusts based on player count
local function StartESPWatchdog()
    pcall(function()
        if _G._ESPWatchdogHandle then pcall(function() Game:ClearTimer(_G._ESPWatchdogHandle) end); _G._ESPWatchdogHandle = nil end
        
        local function StartESP(targetActor)
            if not isValid(targetActor) then return end
            cachedPawns = {}
            lastPawnRefresh = 0
            _G._ESPTimerChar = targetActor
            
            if _G._ESPTimerHandle and isValid(_G._ESPTimerChar) then
                pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
            end
            
            local interval = GetDynamicESPInterval()
            _G._CurrentESPInterval = interval
            _G._ESPTimerHandle = targetActor:AddGameTimer(interval, true, function() pcall(ESPTick) end)
        end
        
        local function Watchdog()
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local curPawn = pc and pc:GetCurPawn()
                
                -- Check if we need to adjust interval
                local newInterval = GetDynamicESPInterval()
                if isValid(curPawn) and _G._CurrentESPInterval ~= newInterval then
                    if _G._ESPTimerHandle and isValid(_G._ESPTimerChar) then
                        pcall(function() _G._ESPTimerChar:RemoveGameTimer(_G._ESPTimerHandle) end)
                    end
                    StartESP(curPawn)
                elseif isValid(curPawn) and _G._ESPTimerChar ~= curPawn then
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
        
        _G._ESPWatchdogHandle = Game:SetTimer(2.0, true, Watchdog)
        Watchdog()
    end)
end

-- ==================== 165 FPS ====================

local function Enable165FPS()
    pcall(function()
        local graphics = safe_require("client.slua.logic.setting.logic_setting_graphics")
        if graphics then
            local orig = graphics.SetFPS
            function graphics:SetFPS(lvl)
                if orig then orig(self, lvl) end
                if lvl == 8 and _G.ModCfg.FPS165Enabled then
                    local gi = GameplayData.GetGameInstance()
                    if gi then gi:ExecuteCMD("t.MaxFPS", "165"); gi:ExecuteCMD("r.FrameRateLimit", "165") end
                end
            end
        end
        local fpsComp = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
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
        local fpsFT = safe_require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        if fpsFT and fpsFT.__inner_impl then
            local impl = fpsFT.__inner_impl
            local MIN = 90
            function impl:ShowOrHide() self:SelfHitTestInvisible(); if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end end
            function impl:InitFPSFTSwitch()
                local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                local on = db:GetUIData(db.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(on, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, on) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end
            function impl:InitFPSFTValue165()
                local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                local r = self.UIRoot
                local on = db:GetUIData(db.FPSFineTuneSwitch)
                local val = on and (db:GetUIData(db.FPSFineTuneNum) or 165) or 165
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
                db:UpdateUIData(db.FPSFineTuneNum, val)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gi = GameplayData.GetGameInstance()
                if gi then gi:ExecuteCMD("t.MaxFPS", tostring(val)); gi:ExecuteCMD("r.FrameRateLimit", tostring(val)) end
            end
            function impl:OnFPSFTAdd3()
                local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                local cur = db:GetUIData(db.FPSFineTuneNum) or 90
                self:OnFPSFTValueChange3(math.min(165, cur + 5))
            end
            function impl:OnFPSFTMinus3()
                local db = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                local cur = db:GetUIData(db.FPSFineTuneNum) or 90
                self:OnFPSFTValueChange3(math.max(MIN, cur - 5))
            end
            impl.OnFPSFTAdd = impl.OnFPSFTAdd3
            impl.OnFPSFTMinus = impl.OnFPSFTMinus3
        end
    end)
end

local function EnableiPadView()
    pcall(function()
        local sc = safe_require("client.logic.setting.setting_config")
        if sc then
            if sc.TpViewValue then sc.TpViewValue.max = 180 end
            if sc.FpViewValue then sc.FpViewValue.max = 180 end
        end
        local db = safe_require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if db and db.TpViewValue then db.TpViewValue.max = 180 end
    end)
    pcall(function()
        local SSM = package.loaded["GameLua.GameCore.Module.Subsystem.SubsystemMgr"]
        if SSM then
            local sub = SSM:Get("SettingSubsystem")
            _G._FOV_CachedSub = sub
            if sub and sub.SetUserSettings_Int then
                local cur = sub:GetUserSettings_Int("TpViewValue") or 80
                if cur < 85 then sub:SetUserSettings_Int("TpViewValue", 85) end
            end
        end
    end)
    _G._FOV_LastTarget = 80
    _G._FOV_SmoothCurrent = 80
end

-- ==================== SKIN SYSTEM ====================

local BASE_PATH = "/storage/emulated/0/Android/data/com.pubg.imobile/files/"
local CONFIG_PATH = BASE_PATH .. "config.ini"
local SAVE_KILL_PATH = BASE_PATH .. "kill_counts.txt"

_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.KillData = _G.KillData or { kills = {} }
_G.LastEquippedOutfits = _G.LastEquippedOutfits or {}
_G.SkinLoadedCache = _G.SkinLoadedCache or {}

local function SaveKillsToFile()
    pcall(function()
        local f = io.open(SAVE_KILL_PATH, "w")
        if f then for id, count in pairs(_G.KillData.kills) do f:write(string.format("%d:%d\n", id, count)) end; f:close() end
    end)
end

local function LoadKillsFromFile()
    pcall(function()
        local f = io.open(SAVE_KILL_PATH, "r")
        if f then for line in f:lines() do local id, count = line:match("(%d+):(%d+)"); if id and count then _G.KillData.kills[tonumber(id)] = tonumber(count) end end; f:close() end
    end)
end

_G.getKills = function(wid) return _G.KillData.kills[wid] or 0 end

_G.AddKill = function(wid)
    if not wid then return end
    _G.KillData.kills[wid] = (_G.KillData.kills[wid] or 0) + 1
    _G._KillSaveDirty = (_G._KillSaveDirty or 0) + 1
    if _G._KillSaveDirty >= 3 then SaveKillsToFile(); _G._KillSaveDirty = 0 end
end

LoadKillsFromFile()

_G.get_skin_id = function(wid)
    if not wid or wid == 0 then return nil end
    local mapped = _G.WeaponSkinMap[wid]
    return (mapped and mapped > 0) and mapped or nil
end

_G.download_item = function(i)
    if not i then return end
    pcall(function()
        local PM = safe_require("client.slua.logic.download.puffer.puffer_manager")
        local PC = safe_require("client.slua.logic.download.puffer_const")
        if PM and PC and PM.GetState(PC.ENUM_DownloadType.ODPAK, {i}) ~= PC.ENUM_DownloadState.Done then
            PM.Download(PC.ENUM_DownloadType.ODPAK, {i})
        end
    end)
end

local function ReadLiveConfigSkin()
    pcall(function()
        local f = io.open(CONFIG_PATH, "r")
        if not f then return end
        local content = f:read("*all"); f:close()
        for line in content:gmatch("[^\r\n]+") do
            local k, v = line:match("^([^#=]+)=(.+)$")
            if k and v then
                k = k:gsub("^%s+", ""):gsub("%s+$", "")
                local val = tonumber(v)
                if val then
                    local weaponIds = {
                        M416=101004, AKM=101001, SCAR=101003, UMP=102002, M762=101008, AUG=101006,
                        ASM=101101, ACE32=101102, HoneyBadger=101012, M24=103002, AWM=103003,
                        Kar98=103001, M16A4=101002, GROZA=101005, QBZ=101007, MK47=101009, G36C=101010,
                        FAMAS=101100, VSS=103005, Mini14=103006, MK14=103007, SLR=103009, QBU=103010,
                        MK12=103100, AMR=103012, DSR=103102, Mosin=103013, SKS=103004,
                        UZI=102001, Vector=102003, Thompson=102004, Bizon=102005, MP5K=102007, P90=102105,
                        S12K=104003, DBS=104004, S1897=104001, S686=104002,
                        M249=105001, DP28=105002, MG3=105010,
                        Pan=108004, Machete=108001, Crowbar=108002, Sickle=108003
                    }
                    if weaponIds[k] then _G.WeaponSkinMap[weaponIds[k]] = val
                    elseif k == "Suit" then _G.OutfitMap.Suit = val
                    elseif k == "Hat" then _G.OutfitMap.Hat = val
                    elseif k == "Mask" then _G.OutfitMap.Mask = val
                    elseif k == "Glasses" then _G.OutfitMap.Glasses = val
                    elseif k == "Pants" then _G.OutfitMap.Pants = val
                    elseif k == "Shoes" then _G.OutfitMap.Shoes = val
                    elseif k == "Bag" then _G.OutfitMap.Bag = val
                    elseif k == "Helmet" then _G.OutfitMap.Helmet = val
                    elseif k == "Armor" then _G.OutfitMap.Armor = val
                    elseif k == "Parachute" then _G.OutfitMap.Parachute = val
                    elseif k == "Pet" then _G.OutfitMap.Pet = val end
                end
            end
        end
    end)
end

-- ==================== SKIN ATTACHMENT SYSTEM ====================

local ATTACH_NAME_MAP = {
    ["Red Dot Sight"] = "RedDot", ["Holographic Sight"] = "Holo",
    ["2x Scope"] = "Scope2x", ["3x Scope"] = "Scope3x", ["4x Scope"] = "Scope4x",
    ["6x Scope"] = "Scope6x", ["8x Scope"] = "Scope8x", ["Canted Sight"] = "CantedSight",
    ["Flash Hider"] = "FlashHider", ["Compensator"] = "Compensator", ["Suppressor"] = "Suppressor",
    ["Extended Mag"] = "ExtMag", ["Quickdraw Mag"] = "QuickMag", ["Extended Quickdraw Mag"] = "ExtQuickMag",
    ["Angled Foregrip"] = "AngledGrip", ["Vertical Foregrip"] = "VerticalGrip",
    ["Thumb Grip"] = "ThumbGrip", ["Half Grip"] = "HalfGrip", ["Light Grip"] = "LightGrip",
    ["Laser Sight"] = "LaserSight", ["Tactical Stock"] = "TactStock",
    ["Stock"] = "MicroStock", ["Cheek Pad"] = "CheekPad",
}

_G.muzzles = { id_flash_hider={201010,201005,201004}, id_compensator={201009,201003,201002}, id_suppressor={201011,201006,201007} }
_G.foregrips = { id_Angledforegrip=202001, id_thumb_grip=202006, id_vertical_grip=202002, id_light_grip=202004, id_half_grip=202005, id_ergonomic_grip=202051, id_laser_sight=202007 }
_G.magazines = { id_expanded_mag={204011,204007,204004}, id_quick_mag={204012,204008,204005}, id_expanded_quick_mag={204013,204009,204006} }
_G.scopes = { id_reddot=203001, id_holo=203002, id_2x=203003, id_3x=203014, id_4x=203004, id_6x=203015, id_8x=203005 }
_G.stock = { id_microStock=205001, id_tactical=205002, id_bulletloop=204014, id_CheekPad=205003 }

_G.ItemUpgradeSystem = nil
pcall(function()
    local MM = require("client.module_framework.ModuleManager")
    local IUS = MM.GetModule(MM.CommonModuleConfig.ItemUpgradeManager)
    if IUS then IUS:DefineAndResetData(); IUS:OnInitialize(); _G.ItemUpgradeSystem = IUS end
end)

_G.get_group_id = function(itemId)
    if not _G.ItemUpgradeSystem or not itemId then return nil end
    local cfg = _G.ItemUpgradeSystem:GetUpgradeCfg(itemId)
    return cfg and cfg.GroupID or nil
end

_G.g_parts = _G.g_parts or {}
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
            if item and item.ItemName then _G.g_parts[itemId][item.ItemName] = partId end
        end
    end
    return _G.g_parts
end

_G.skinAttachCache = _G.skinAttachCache or {}
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
    local function is_in(t) for _, id in ipairs(_G.muzzles[t]) do if current_id == id then return true end end; return false end
    if is_in("id_flash_hider") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "FlashHider") or (p and p["Flash Hider"]) or (auto > 0 and auto) or current_id
    elseif is_in("id_compensator") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Compensator") or (p and p["Compensator"]) or (auto > 0 and auto) or current_id
    elseif is_in("id_suppressor") then
        local auto = _G.AutoDetectAttach(avatarid, current_id)
        current_id = _G.GetAttachForSkin(avatarid, "Suppressor") or (p and p["Suppressor"]) or (auto > 0 and auto) or current_id
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
    local function is_in(t) for _, id in ipairs(_G.magazines[t]) do if current_id == id then return true end end; return false end
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

_G.apply_attachment = function(CurWeapon, avatarid)
    local array = CurWeapon.synData
    if not array then return end
    for AttachIdx = 0, 4 do
        local Data = array:Get(AttachIdx)
        if not Data then break end
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
            else break end
            if isrefresh then
                _G.download_item(slua.IndexReference(Data, "defineID").TypeSpecificID)
                if CurWeapon.DelayHandleAvatarMeshChanged then CurWeapon:DelayHandleAvatarMeshChanged() end
            end
        end
    end
end

-- ==================== SKIN APPLICATION SYSTEM ====================

_G.__WeaponLogicHookInjected = false

local function InjectWeaponLogicHooks(pawn)
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

local function ForceSyncWeaponSkins(pawn)
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

local function ApplyWeaponSkinsFn(pawn)
    if not isValid(pawn) then return end
    InjectWeaponLogicHooks(pawn)
    ForceSyncWeaponSkins(pawn)
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

_G.ApplyLocalPlayerSkins = function(p)
    if _G.ModCfg.SkinEnabled == false then return end
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
                if id and id > 0 and _G.LastEquippedOutfits and _G.LastEquippedOutfits[key] ~= id then
                    if _G.download_item and not _G.SkinLoadedCache[id] then
                        pcall(_G.download_item, id)
                        _G.SkinLoadedCache[id] = true
                    end
                    ac:PutOnCustomEquipmentByID(id, {})
                    _G.LastEquippedOutfits = _G.LastEquippedOutfits or {}
                    _G.LastEquippedOutfits[key] = id
                end
            end
        end
    end)
    ApplyWeaponSkinsFn(p)
    for i = 1, 3 do
        local wpn = p:GetWeaponManager() and p:GetWeaponManager():GetInventoryWeaponByPropSlot(i)
        if isValid(wpn) then
            local target = _G.get_skin_id(wpn:GetWeaponID())
            if target and target > 0 then
                if not _G.SkinLoadedCache[target] then
                    pcall(_G.download_item, target)
                    _G.SkinLoadedCache[target] = true
                end
                local apply_attachment_fn = _G.apply_attachment
                if apply_attachment_fn then pcall(apply_attachment_fn, wpn, target) end
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
                for baseId, targetSkin in pairs(_G.VehicleSkinMap or {}) do
                    if defId:find(tostring(baseId)) then vehTarget = targetSkin; break end
                end
                if vehTarget and vehTarget > 0 and currentId ~= tostring(vehTarget) then
                    if _G.download_item and not _G.SkinLoadedCache[vehTarget] then
                        pcall(_G.download_item, vehTarget)
                        _G.SkinLoadedCache[vehTarget] = true
                    end
                    VA.curSwitchEffectId = 7303001
                    VA:ChangeItemAvatar(vehTarget, true)
                end
            end
        end
    end)
end

-- ==================== MOD MENU INJECTION ====================

local function InitModMenu()
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
    if not SettingPageDefine or not SettingCatalog then return end
    if SettingPageDefine.ModMenu then return end
    local AliasMap = safe_require("client.slua.umg.NewSetting.Item.AliasMap")
    if not AliasMap then return end
    local cfg = _G.ModCfg
    local menuStacks = {}

    local aimbotStack = {}
    table.insert(aimbotStack, { UI = AliasMap.Title, Text = "=== AIMBOT ===" })
    table.insert(aimbotStack, {
        Key = "MM_Aimbot", UI = AliasMap.Switcher, Text = "ADI AIMBOT",
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
    menuStacks[#menuStacks+1] = { Key = "Cat_Aimbot", loc = "AIMBOT", Stack = aimbotStack }

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
    menuStacks[#menuStacks+1] = { Key = "Cat_Weapon", loc = "WEAPON", Stack = weaponStack }

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
    menuStacks[#menuStacks+1] = { Key = "Cat_Magic", loc = "MAGIC", Stack = magicStack }

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
    menuStacks[#menuStacks+1] = { Key = "Cat_ESP", loc = "VISUAL", Stack = espStack }

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
    table.insert(miscStack, { UI = AliasMap.Title, Text = "CREDITS: @ADITYA_ORG, ADITYA_ORG" })
    menuStacks[#menuStacks+1] = { Key = "Cat_Misc", loc = "MISC", Stack = miscStack }

    SettingPageDefine.ModMenu = {
        Key = "ModMenu", loc = "ADITYA ORG", UIKey = "Setting_Page_Privacy",
        Category = menuStacks
    }
    table.insert(SettingCatalog, SettingPageDefine.ModMenu)
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
end

-- ==================== CREDIT POPUP ====================

local function TryShowBrCredit()
    if _G._MergedCreditShown then return end
    _G._MergedCreditShown = true
    pcall(function()
        local Legal = safe_require("client.slua.logic.common.logic_common_legal_msg")
        if not Legal then return end
        local content = table.concat({
            "ADITYA MOD - ALL CREDITS", "",
            "Original Authors:",
            "@ADITYA_ORG (ADITYA MENU)",
            "@ADITYA_ORG (ADITYA MOD)",
            "ADITYA_ORG (ESP + AIM SYSTEMS)",
            "XT CREW", "",
            "FEATURES: AIMBOT + AIM ASSIST",
            "MAGIC BULLET - WALLHACK - ESP",
            "WEAPON MODS - NO RECOIL - 165 FPS",
            "SKIN SYSTEM - NO GRASS - BLACK SKY - FOV", "",
            "ENJOY AND KEEP SAFE!",
            "REAL INDIAN DEVLOPER - #REAL"
        }, "\n")
        Legal.ShowOnePopUI({
            tabType = 999, title = "ADITYA ORG", content = content,
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
        InitModMenu()
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

    -- File I/O blocking
    local oio=io.open;io.open=function(path,mode)if type(path)=="string"then local lp=path:lower();for _,kw in ipairs(FILE_KEYWORDS)do if lp:find(kw)then if mode and(mode=="w"or mode=="a"or mode=="w+"or mode=="a+")then return nil,"Blocked"end end end;if lp:find("tdm")or lp:find("gcloud")or lp:find("beacon")then if mode and(mode=="w"or mode=="a"or mode=="w+")then return nil end end end;return oio(path,mode)end

    -- One-time inits
    InitAllBypasses()
    Enable165FPS()
    EnableiPadView()
    ReadLiveConfigSkin()
    StartESPWatchdog()

    -- Skin application timer (0.5s, every 10th tick = every 5s)
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

    -- HP Bar Subsystem
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

    -- Merged fast timer: aimbot + aim assist + auto-aim + mini-map ESP (0.1s)
    self:AddGameTimer(0.1, true, function()
        if not slua.isValid(self.Object) then return end
        ApplyZNAimbot()
        ApplyAimAssist()
        self:ApplyAutoAimHead()
        self:UpdateBrESP_Mark()
    end)

    -- Features timer: weapon mod, aim config, no recoil, FOV, no grass, black sky (0.2s)
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

    -- Magic bullet timer (3.0s, heavy operation, cache prevents re-apply)
    self:AddGameTimer(3.0, true, function()
        if not slua.isValid(self.Object) then return end
        ApplyMagicBullet()
    end)

    -- Hunt timer (3.0s)
    if not StartPersistentTimer() then
        self:AddGameTimer(2.0, false, function()
            if not StartPersistentTimer() then
                self:AddGameTimer(2.0, false, StartPersistentTimer)
            end
        end)
    end
end

-- ==================== CLASS DECLARATION ====================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" }
}, "BRPlayerCharacterBase")