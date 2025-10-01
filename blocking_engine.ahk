#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0

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

BlockProcess(pid, exe) {
    global LogFile
    try {
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        logEntry := timestamp " - Bloqueado: " exe "`n"
        FileAppend(logEntry, LogFile, "UTF-8")

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