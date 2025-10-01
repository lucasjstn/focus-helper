#Requires AutoHotkey v2.0

global PomodoroOn := false
global endTick := 0
global taskbarRect := Map("left", 0, "top", 0, "right", 0, "bottom", 0)
global CoreAllowList := Map(
    "autohotkey64.exe", true,
    "autohotkey.exe", true,
    "explorer.exe", true,
    "dwm.exe", true,
    "shellexperiencehost.exe", true,
    "searchhost.exe", true,
    "textinputhost.exe", true,
    "cmd.exe", true,
    "powershell.exe", true,
    "pwsh.exe", true,
    "brave.exe", true,
    "Code - Insiders.exe", true,
    "Discord.exe", true,
    "Spotify.exe", true,
    "Todo.exe", true,
    "Code.exe", true,
    "DrRacket.exe", true,
    "PowerToys.WorkspacesEditor.exe", true,
    "Microsoft To Do", true,
    "FocusToDo.exe", true,
    "anki.exe", true,
    "pyw.exe", true
)
global AllowProcessMap := Map()
global AllowTitleList := []
global AllowListFile := A_ScriptDir "\allowlist.txt"
global LogFile := A_ScriptDir "\log_bloqueios.txt"
global lastPids := Map()
global processPollMs := 700
global windowPollMs := 300