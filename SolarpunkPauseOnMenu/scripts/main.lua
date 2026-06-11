--[[
    SolarpunkPauseOnMenu
    Congela o jogo quando W_IngameMenu_C fica visivel (menu ESC).
    Usa TimeDilation em vez de SetGamePaused para nao bloquear ESC fechar o menu.
]]

local Config = {
    discoverKey = Key.F8,
    pollIntervalMs = 150,

    menuWidgetPatterns = {
        "w_ingamemenu",
        "ingamemenu",
    },

    debug = true,
}

local modFrozen = false
local pollActive = false

local function log(message)
    if Config.debug then
        print("[SolarpunkPauseOnMenu] " .. message .. "\n")
    end
end

local function getPlayerController()
    local controller = FindFirstOf("PlayerController")
    if controller and controller:IsValid() then
        return controller
    end
    return nil
end

local function getGameplayStatics()
    local statics = StaticFindObject("/Script/Engine.Default__GameplayStatics")
    if statics and statics:IsValid() then
        return statics
    end
    return nil
end

local function clearEnginePause(controller, statics)
    statics:SetGamePaused(controller, false)
end

local function setWorldFrozen(shouldFreeze)
    local statics = getGameplayStatics()
    local controller = getPlayerController()
    if not statics or not controller then
        return false
    end

    clearEnginePause(controller, statics)
    statics:SetGlobalTimeDilation(controller, shouldFreeze and 0.0 or 1.0)

    pcall(function()
        controller:SetIgnoreMoveInput(shouldFreeze)
        controller:SetIgnoreLookInput(shouldFreeze)
    end)

    return true
end

local function isWidgetActuallyVisible(widget)
    local okViewport, inViewport = pcall(function() return widget:IsInViewport() end)
    if not okViewport or not inViewport then
        return false
    end
    local okVis, vis = pcall(function() return widget:GetVisibility() end)
    if okVis and vis ~= nil then
        local value = tonumber(vis)
        if value ~= nil and (value == 1 or value == 2) then
            return false
        end
    end
    return true
end

local function widgetMatchesMenu(widget)
    local className = string.lower(widget:GetClass():GetFName():ToString())
    for _, pattern in ipairs(Config.menuWidgetPatterns) do
        if string.find(className, pattern, 1, true) then
            return true
        end
    end
    return false
end

local function isIngameMenuVisible()
    local widgets = FindAllOf("UserWidget")
    if not widgets then
        return false
    end
    for _, widget in ipairs(widgets) do
        if widget:IsValid() and widgetMatchesMenu(widget) and isWidgetActuallyVisible(widget) then
            return true
        end
    end
    return false
end

local function syncFreezeState()
    local shouldFreeze = isIngameMenuVisible()
    if shouldFreeze == modFrozen then
        return
    end
    if setWorldFrozen(shouldFreeze) then
        modFrozen = shouldFreeze
        log(shouldFreeze and "Jogo CONGELADO (menu ESC aberto)." or "Jogo RETOMADO (menu ESC fechado).")
    end
end

local function dumpVisibleWidgets()
    local widgets = FindAllOf("UserWidget")
    if not widgets then
        log("Nenhum UserWidget encontrado.")
        return
    end
    log("--- Widgets VISIVEIS na viewport ---")
    local count = 0
    for _, widget in ipairs(widgets) do
        if widget:IsValid() and isWidgetActuallyVisible(widget) then
            count = count + 1
            local mark = widgetMatchesMenu(widget) and "  <== MENU ESC" or ""
            log("  " .. widget:GetClass():GetFName():ToString() .. mark)
        end
    end
    log("--- Total visiveis: " .. count .. " ---")
end

local function startPolling()
    if pollActive then
        return
    end
    pollActive = true
    setWorldFrozen(false)
    log("Polling ativo. Congela via TimeDilation (ESC do menu preservado). F8 lista widgets.")
    LoopAsync(Config.pollIntervalMs, function()
        ExecuteInGameThread(syncFreezeState)
        return false
    end)
end

RegisterKeyBind(Config.discoverKey, function()
    ExecuteInGameThread(dumpVisibleWidgets)
end)

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function() end, function()
    ExecuteInGameThread(startPolling)
end)

log("Carregado. Polling inicia ao entrar no jogo.")
