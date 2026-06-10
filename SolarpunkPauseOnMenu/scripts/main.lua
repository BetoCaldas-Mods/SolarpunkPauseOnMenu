--[[
    SolarpunkPauseOnMenu
    Pausa o jogo quando o menu (ESC) e exibido e despausa quando ele e fechado.

    Funciona via UE4SS (Lua) em cima da Unreal Engine 5.
    Veja o README.md para instalacao.

    Modos de funcionamento (Config.mode):
      "toggle" -> (padrao) Alterna a pausa a cada ESC pressionado. Comeca SEMPRE
                  despausado. Atende ao pedido: ESC abre o menu -> pausa;
                  ESC fecha o menu -> despausa. Robusto e sem risco de travar.
      "detect" -> Detecta o widget do menu VISIVEL na viewport e sincroniza a pausa
                  automaticamente. Mais robusto contra fechar o menu pelo mouse, MAS
                  exige que Config.menuWidgetPatterns case SOMENTE com o widget do
                  menu de pausa (descubra o nome com a tecla F8).
]]

local Config = {
    mode = "toggle",

    pauseKey = Key.ESCAPE,

    discoverKey = Key.F8,

    -- Use apenas no modo "detect". Padroes em minusculas, casados por substring
    -- no nome da CLASSE do widget. Mantenha o mais especifico possivel.
    menuWidgetPatterns = {
        "pausemenu",
        "pause_menu",
    },

    pollIntervalMs = 200,

    debug = true,
}

local modPaused = false

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

local function setGamePaused(shouldPause)
    local statics = getGameplayStatics()
    local controller = getPlayerController()
    if not statics or not controller then
        log("Nao foi possivel resolver GameplayStatics/PlayerController.")
        return false
    end
    statics:SetGamePaused(controller, shouldPause)
    log(shouldPause and "Jogo PAUSADO." or "Jogo DESPAUSADO.")
    return true
end

-- ESlateVisibility: 0=Visible, 1=Collapsed, 2=Hidden, 3=HitTestInvisible, 4=SelfHitTestInvisible
local function isWidgetActuallyVisible(widget)
    local okViewport, inViewport = pcall(function() return widget:IsInViewport() end)
    if not okViewport or not inViewport then
        return false
    end
    local okVis, vis = pcall(function() return widget:GetVisibility() end)
    if okVis and vis ~= nil then
        local v = tonumber(vis)
        if v ~= nil and (v == 1 or v == 2) then
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

local function isMenuVisible()
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

local function syncPauseWithMenu()
    local menuVisible = isMenuVisible()
    if menuVisible and not modPaused then
        if setGamePaused(true) then modPaused = true end
    elseif not menuVisible and modPaused then
        if setGamePaused(false) then modPaused = false end
    end
end

local function startDetectMode()
    log("Modo 'detect' ativo. Padroes do widget: " .. table.concat(Config.menuWidgetPatterns, ", "))
    LoopAsync(Config.pollIntervalMs, function()
        ExecuteInGameThread(function() syncPauseWithMenu() end)
        return false
    end)
end

local function startToggleMode()
    log("Modo 'toggle' ativo. Pressione ESC para alternar a pausa.")
    RegisterKeyBind(Config.pauseKey, function()
        ExecuteInGameThread(function()
            modPaused = not modPaused
            setGamePaused(modPaused)
        end)
    end)
end

local function dumpVisibleWidgets()
    ExecuteInGameThread(function()
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
                local mark = widgetMatchesMenu(widget) and "  <== CASA com padrao" or ""
                log("  " .. widget:GetClass():GetFName():ToString() .. mark)
            end
        end
        log("--- Total visiveis: " .. count .. " ---")
        log("Copie o nome da classe do menu de pausa para Config.menuWidgetPatterns e use mode='detect'.")
    end)
end

RegisterKeyBind(Config.discoverKey, function()
    dumpVisibleWidgets()
end)

if Config.mode == "detect" then
    startDetectMode()
elseif Config.mode == "toggle" then
    startToggleMode()
else
    log("Config.mode invalido: use 'toggle' ou 'detect'.")
end

log("Carregado. Modo: " .. Config.mode .. ". Tecla de descoberta de widgets: F8 (configuravel).")
