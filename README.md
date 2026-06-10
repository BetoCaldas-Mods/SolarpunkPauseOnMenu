# Solarpunk - Mod "Pausar no Menu (ESC)"

Mod que **pausa o jogo quando o menu de ESC e exibido** e **despausa quando o menu e fechado**.

O jogo Solarpunk e feito em **Unreal Engine 5** e empacotado com IoStore
(`.utoc` / `.ucas` / `.pak`). Esse tipo de jogo nao expoe um sistema de mods proprio,
entao a forma padrao (maio/junho de 2026) de injetar logica como "pausar/despausar"
e atraves do **UE4SS** (Unreal Engine 4/5 Scripting System), usando scripts em Lua.

- Referencia: documentacao oficial do UE4SS — https://docs.ue4ss.com
- Guia de mod Lua — https://docs.ue4ss.com/guides/creating-a-lua-mod.html

---

## 1. Pre-requisitos

- Jogo instalado em: `E:\SteamLibrary\steamapps\common\Solarpunk`
- Executavel real do jogo (shipping):
  `E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\SolarpunkSteam-Win64-Shipping.exe`

> IMPORTANTE: o `Solarpunk.exe` na raiz e apenas um launcher. O UE4SS precisa ser
> instalado na pasta do executavel **shipping** (`Solarpunk\Binaries\Win64`).

---

## 2. Instalar o UE4SS

1. Baixe a versao mais recente do UE4SS (use a release **experimental/2.5.2+**, que tem
   melhor compatibilidade com jogos UE5 recentes):
   https://github.com/UE4SS-RE/RE-UE4SS/releases
2. Extraia o conteudo do `.zip` para dentro de:
   ```
   E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\
   ```
   Apos extrair, essa pasta deve conter (entre outros):
   ```
   Solarpunk\Binaries\Win64\
       dwmapi.dll            (proxy do UE4SS)
       UE4SS.dll
       UE4SS-settings.ini
       Mods\
           mods.txt
           shared\
           (mods que ja vem de exemplo)
   ```

> Se o jogo nao iniciar com o `dwmapi.dll`, tente renomear o proxy para outro nome
> suportado pelo UE4SS (ex.: `xinput1_3.dll`). Veja a doc de instalacao do UE4SS.

---

## 3. Instalar este mod

1. Copie a pasta `SolarpunkPauseOnMenu` (que esta aqui ao lado deste README) para:
   ```
   E:\SteamLibrary\steamapps\common\Solarpunk\Solarpunk\Binaries\Win64\Mods\
   ```
   Resultado:
   ```
   ...\Win64\Mods\SolarpunkPauseOnMenu\
       enabled.txt
       scripts\main.lua
   ```
2. Habilite o mod. Ha duas formas (basta uma):
   - **enabled.txt** (ja incluso): o UE4SS carrega a pasta automaticamente; ou
   - **mods.txt**: abra `...\Win64\Mods\mods.txt` e adicione a linha
     (veja `mods.txt.exemplo`):
     ```
     SolarpunkPauseOnMenu : 1
     ```

---

## 4. Ativar o console do UE4SS (para ver logs)

No arquivo `...\Win64\UE4SS-settings.ini`, em `[Debug]`, garanta:
```
ConsoleEnabled = 1
GuiConsoleEnabled = 1
GuiConsoleVisible = 1
```
Assim abre uma janela de console com os logs `[SolarpunkPauseOnMenu] ...`.

---

## 5. Descobrir o nome do widget do menu (passo unico recomendado)

O mod vem no modo `toggle` por padrao (ESC alterna pausa). Para sincronizar automaticamente
com a visibilidade do menu, use o modo `detect`.
Para funcionar 100%, ele precisa reconhecer o **nome da classe do widget** do menu de
pausa. Para descobrir esse nome:

1. Inicie o jogo (carregue um save ate poder andar).
2. Abra o menu com **ESC**.
3. Com o menu aberto, pressione **F8** (tecla de descoberta deste mod).
4. Olhe o console do UE4SS: ele lista todos os widgets atualmente na viewport, ex.:
   ```
   [SolarpunkPauseOnMenu] --- Widgets atualmente NA VIEWPORT ---
   [SolarpunkPauseOnMenu]   WBP_PauseMenu_C
   [SolarpunkPauseOnMenu]   WBP_HUD_C
   ```
5. Identifique o widget do menu (algo como `WBP_PauseMenu_C`, `EscMenu_C`, etc.).
6. Abra `SolarpunkPauseOnMenu\scripts\main.lua` e adicione um trecho (em minusculas)
   desse nome em `Config.menuWidgetPatterns`. Ex.:
   ```lua
   menuWidgetPatterns = {
       "pausemenu",   -- casa com WBP_PauseMenu_C
   },
   ```
7. Salve e recarregue os mods (tecla padrao **Ctrl+R** se o hot reload estiver ligado
   no `UE4SS-settings.ini`) ou reinicie o jogo.

> Dica: o mod ja tenta varios padroes comuns por padrao. Se o seu menu casar com um
> deles, pode ja funcionar sem ajuste.

---

## 6. Modos do mod

No topo de `scripts/main.lua`, em `Config.mode`:

- `"toggle"` (padrao): alterna a pausa a cada **ESC**. Funciona sem saber o nome do widget,
  porem pode dessincronizar se o menu for fechado pelo mouse (basta apertar ESC de novo).
- `"detect"`: detecta o widget do menu e pausa/despausa automaticamente,
  independentemente de como o menu for aberto/fechado (ESC, mouse, botao "Resume").
  Mais robusto, mas depende de `menuWidgetPatterns` reconhecer o menu.

Outras opcoes:
- `discoverKey`: tecla para listar widgets na viewport (padrao `F8`).
- `pollIntervalMs`: frequencia de verificacao no modo detect (padrao 200 ms).
- `debug`: liga/desliga os logs no console.

---

## 7. Solucao de problemas

- **Nada acontece / sem logs**: confirme que o UE4SS carregou (console abriu) e que o
  mod aparece como carregado. Verifique se copiou para a pasta do `*-Shipping.exe`.
- **F8 nao lista nada**: o menu pode nao ser um `UserWidget` padrao; tente abrir o menu
  antes de apertar F8, e confira se o jogo esta em foco.
- **Pausa em menus errados (inventario, etc.)**: refine `menuWidgetPatterns` para casar
  apenas com o widget do menu de ESC.
- **Multiplayer**: `SetGamePaused` so funciona de fato em jogo single-player/standalone.
  Em sessoes online a engine ignora a pausa.

---

## Estrutura dos arquivos

```
SolarpunkPauseOnMenu\             (repositorio)
    README.md
    mods.txt.exemplo
    SolarpunkPauseOnMenu\           (copiar para ...\Win64\Mods\)
        enabled.txt
        scripts\
            main.lua
    tools\                          (opcional: gerar assinaturas UE4SS via PDB)
        gen_signatures.py
        gen_guobjectarray.py
        resolve_globals.py
```
