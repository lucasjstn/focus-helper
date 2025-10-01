#Requires AutoHotkey v2.0
#UseHook

; --- Carrega todas as partes do nosso script ---
#Include "config.ahk"
#Include "utils.ahk"
#Include "pomodoro_engine.ahk"
#Include "blocking_engine.ahk"


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