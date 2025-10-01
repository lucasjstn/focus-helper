#Requires AutoHotkey v2.0

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
    global PomodoroOn, btn, lbl, myGui ; <--- Adicionada a variável 'myGui'
    PomodoroOn := false
    SetTimer(UpdateTimer, 0)
    SetTimer(WatchNewProcesses, 0)
    SetTimer(EnforceWindowRestrictions, 0)
    lbl.Text := "25:00"
    btn.Enabled := true
    btn.Text := "Ativar (25:00)"
    myGui.Title := "Pomodoro - Bloqueio" ; <--- Linha nova para restaurar o título
    ToolTip("Sessao concluida!")
    SetTimer(() => ToolTip(), -1200)
}

UpdateTimer() {
    global PomodoroOn, endTick, lbl, myGui ; <--- Adicionada a variável 'myGui'
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
    
    formattedTime := Format("{:02}:{:02}", mins, secs)
    
    lbl.Text := formattedTime
    myGui.Title := "Pomodoro - " formattedTime ; <--- Linha nova para atualizar o título
}