#Requires AutoHotkey v2.0

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
        tmp := A_Temp "\plist.txt"
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