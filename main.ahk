#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

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
)
global AllowProcessMap := Map()
global AllowTitleList := []
global AllowListFile := A_ScriptDir "\allowlist.txt"
global lastPids := Map()
global processPollMs := 700
global windowPollMs := 300

; ---------- GUI ----------
myGui := Gui("+ToolWindow")
myGui.Title := "Pomodoro - Bloqueio"
btn := myGui.AddButton("w240 h42 vBtn", "Ativar (25:00)")
lbl := myGui.AddText("w240 Center vLbl", "25:00")
btn.OnEvent("Click", StartSession)

; Bloqueio de fechar a janela
myGui.OnEvent("Close", OnGuiClose)
myGui.Show()

OnGuiClose(*) {
    global PomodoroOn
    if PomodoroOn {
        ToolTip("🚫 Você não pode fechar a janela durante o Pomodoro!")
        SetTimer(() => ToolTip(), -1500)
    } else {
        ExitApp()
    }
}


StartSession(*) {
    global PomodoroOn, endTick, btn, lastPids
    if PomodoroOn
        return
    InitAllowList()
    PomodoroOn := true
    endTick := A_TickCount + (25 * 60 * 1000)
    btn.Enabled := false
    btn.Text := "Pomodoro em andamento."
    UpdateTaskbarRect()
    lastPids := SnapshotPids()
    SetTimer(UpdateTimer, 1000)
    SetTimer(WatchNewProcesses, processPollMs)
    SetTimer(EnforceWindowRestrictions, windowPollMs)
    ToolTip("Pomodoro iniciado")
    SetTimer(() => ToolTip(), -800)
}

FinishSession() {
    global PomodoroOn, btn, lbl
    PomodoroOn := false
    SetTimer(UpdateTimer, 0)
    SetTimer(WatchNewProcesses, 0)
    SetTimer(EnforceWindowRestrictions, 0)
    lbl.Text := "25:00"
    btn.Enabled := true
    btn.Text := "Ativar (25:00)"
    ToolTip("Sessao concluida!")
    SetTimer(() => ToolTip(), -1200)
}

UpdateTimer() {
    global PomodoroOn, endTick, lbl
    if !PomodoroOn
        return
    rem := endTick - A_TickCount
    if (rem <= 0) {
        FinishSession()
        return
    }
    secsTotal := rem // 1000
    mins := Floor(secsTotal / 60)
    secs := Mod(secsTotal, 60)
    lbl.Text := Format("{:02}:{:02}", mins, secs)
}

UpdateTaskbarRect() {
    global taskbarRect
    try {
        if !WinExist("ahk_class Shell_TrayWnd")
            throw Error("Taskbar not found")
        WinGetPos &tx, &ty, &tw, &th, "ahk_class Shell_TrayWnd"
        if (tw && th) {
            taskbarRect["left"] := tx
            taskbarRect["top"] := ty
            taskbarRect["right"] := tx + tw
            taskbarRect["bottom"] := ty + th
            return
        }
    }
    height := 48
    taskbarRect["left"] := 0
    taskbarRect["top"] := A_ScreenHeight - height
    taskbarRect["right"] := A_ScreenWidth
    taskbarRect["bottom"] := A_ScreenHeight
}

InTaskbarArea() {
    global taskbarRect
    MouseGetPos &mx, &my
    return mx >= taskbarRect["left"]
        && mx <= taskbarRect["right"]
        && my >= taskbarRect["top"]
        && my <= taskbarRect["bottom"]
}

SnapshotPids() {
    list := Map()
    try {
        wmi := ComObject("winmgmts:")
        col := wmi.ExecQuery("SELECT ProcessId, Name FROM Win32_Process")
        for proc in col {
            pid := proc.ProcessId
            name := proc.Name
            if IsInteger(pid) && name != ""
                list[pid] := name
        }
    } catch {
        tmp := A_Temp "\\plist.txt"
        RunWait(A_ComSpec ' /c tasklist /fo csv /nh > "' tmp '"', , "Hide")
        for line in StrSplit(FileRead(tmp, "UTF-8"), "`n") {
            line := Trim(line, "`r`n `t")
            if (line = "")
                continue
            if (SubStr(line, 1, 1) = '"' && SubStr(line, -1) = '"')
                line := SubStr(line, 2, -1)
            parts := StrSplit(line, '","')
            if (parts.Length >= 2) {
                name := parts[1]
                pid := Integer(parts[2])
                if IsInteger(pid) && name != ""
                    list[pid] := name
            }
        }
            try FileDelete(tmp)
        }
        return list
    }

    EnsureAllowListFile() {
        global AllowListFile
        if FileExist(AllowListFile)
            return
        sample :=
            "# Adicione uma linha por aplicativo permitido (ex.: obsidian.exe)`n# Use title:Texto para liberar pelo titulo da janela.`n# Linhas iniciadas com # sao ignoradas.`n"
        FileAppend(sample, AllowListFile, "UTF-8")
    }

    LoadExtraAllowList() {
        global AllowListFile
        EnsureAllowListFile()
        extras := { processes: [], titles: [] }
        try content := FileRead(AllowListFile, "UTF-8")
        catch
            return extras
        for line in StrSplit(content, "`n") {
            cleaned := Trim(line, "`r`n `t")
            if (cleaned = "" || SubStr(cleaned, 1, 1) = "#")
                continue
            prefix := StrLower(SubStr(cleaned, 1, 6))
            if (prefix = "title:") {
                title := Trim(SubStr(cleaned, 7))
                if (title != "")
                    extras.titles.Push(StrLower(title))
                continue
            }
            extras.processes.Push(StrLower(cleaned))
        }
        return extras
    }

    InitAllowList() {
        global AllowProcessMap, AllowTitleList, CoreAllowList
        AllowProcessMap := Map()
        AllowTitleList := []
        for exe, _ in CoreAllowList
            AllowProcessMap[StrLower(exe)] := true
        extras := LoadExtraAllowList()
        for exe in extras.processes
            AllowProcessMap[exe] := true
        for title in extras.titles
            AllowTitleList.Push(title)
    }

    HasVisibleTopWindow(pid) {
        wins := WinGetList("ahk_pid " pid)
        for h in wins {
            try {
                if !WinExist("ahk_id " h)
                    continue
                if WinGetTitle("ahk_id " h) != ""
                    return true
            }
        }
        return false
    }

    BlockProcess(pid, exe) {
        try {
            WinClose("ahk_pid " pid)
            Sleep(120)
            if HasVisibleTopWindow(pid)
                ProcessClose(pid)
            ToolTip("Bloqueado: " exe)
            SetTimer(() => ToolTip(), -1000)
        }
    }

    IsAllowedProcessName(exeName) {
        global AllowProcessMap
        exeLower := StrLower(exeName)
        return AllowProcessMap.Has(exeLower)
    }

    IsAllowedTitle(title) {
        global AllowTitleList
        if (AllowTitleList.Length = 0 || title = "")
            return false
        lowered := StrLower(title)
        for allowed in AllowTitleList {
            if InStr(lowered, allowed)
                return true
        }
        return false
    }

    HasAllowedTitle(pid) {
        global AllowTitleList
        if AllowTitleList.Length = 0
            return false
        wins := WinGetList("ahk_pid " pid)
        for h in wins {
            try {
                if !WinExist("ahk_id " h)
                    continue
                if IsAllowedTitle(WinGetTitle("ahk_id " h))
                    return true
            }
        }
        return false
    }

    IsAllowedWindow(pid, exeName, title := "") {
        if IsAllowedProcessName(exeName)
            return true
        if (title != "" && IsAllowedTitle(title))
            return true
        return HasAllowedTitle(pid)
    }

    WatchNewProcesses() {
        global PomodoroOn, lastPids
        if !PomodoroOn
            return
        curr := SnapshotPids()
        for pid, exe in curr {
            if !lastPids.Has(pid) {
                if !IsAllowedWindow(pid, exe) && HasVisibleTopWindow(pid)
                    BlockProcess(pid, exe)
            }
        }
        lastPids := curr
    }

    EnforceWindowRestrictions() {
        global PomodoroOn
        if !PomodoroOn
            return
        for hwnd in WinGetList() {
            try {
                if !WinExist("ahk_id " hwnd)
                    continue
                title := WinGetTitle("ahk_id " hwnd)
                if !WinGetMinMax("ahk_id " hwnd) {
                    if title = ""
                        continue
                }
                pid := WinGetPID("ahk_id " hwnd)
                exe := ProcessGetName(pid)
                if !IsAllowedWindow(pid, exe, title)
                    BlockProcess(pid, exe)
            }
        }
    }

    ; ---------- Bloqueio de teclas ----------
    #HotIf PomodoroOn
    !Tab:: return
    +!Tab:: return
    #Tab:: return
    !Esc:: return
    ^+Esc:: return
    #d:: return
    #m:: return
    #+m:: return
    #Down:: return
    #Home:: return
    !F4:: return
    ^w:: return
    ^F4:: return
    #l:: return
    !Space:: return
    #Space:: return
    #r:: return
    #e:: return
    #1:: return
    #2:: return
    #3:: return
    #4:: return
    #5:: return
    #6:: return
    #7:: return
    #8:: return
    #9:: return
    #0:: return
    ^t:: return
    #HotIf

    #HotIf PomodoroOn && InTaskbarArea()
    *LButton:: return
    *RButton:: return
    *MButton:: return
    #HotIf