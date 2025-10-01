#Requires AutoHotkey v2.0
#UseHook

; --- Carrega todas as partes do nosso script ---
#Include "config.ahk"
#Include "utils.ahk"
#Include "pomodoro_engine.ahk"
#Include "blocking_engine.ahk"


; --- CONFIGURAÇÃO DO ÍCONE NA BANDEJA (SYSTEM TRAY) ---
#SingleInstance Force ; Garante que apenas uma instância do script rode
A_IconTip := "Pomodoro Blocker" ; Texto que aparece ao parar o mouse sobre o ícone
TrayMenu := A_TrayMenu
TrayMenu.Delete() ; Remove as opções padrão
TrayMenu.Add("Mostrar / Ocultar", ShowHideGUI)
TrayMenu.Add("Sair", ExitScriptHandler)
TrayMenu.Default := "Mostrar / Ocultar"
TrayMenu.Tip := A_IconTip ; <--- CORRIGIDO: Define o texto do ícone


; ---------- GUI ----------
myGui := Gui("-Resize") ; Janela padrão, não redimensionável
myGui.Title := "Pomodoro - Bloqueio"
btn := myGui.AddButton("w240 h42 vBtn", "Ativar (25:00)")
btn.OnEvent("Click", StartSession) ; <--- CORRIGIDO: Ação do botão adicionada
lbl := myGui.AddText("w240 Center vLbl", "25:00")

myGui.AddText("w240 Center", "Adicionar processo à allowlist:")
myGui.AddEdit("w240 vAllowEdit", "")
btnAdd := myGui.AddButton("w240 h30", "Adicionar")
btnAdd.OnEvent("Click", AddToAllowlistHandler)

myGui.AddText("w240", "Processos permitidos atualmente:")
global AllowListView := myGui.AddListView("w240 r10 vAllowListView", ["Nome do Processo"])
AllowListView.ModifyCol(1, "230")

; O evento "Close" agora apenas oculta a janela
myGui.OnEvent("Close", (*) => myGui.Hide())
myGui.Show()

InitAllowlist()


UpdateAllowlistDisplay() {
    global AllowListView, CoreAllowList, AllowListFile

    AllowListView.Delete()

    for exe, _ in CoreAllowList {
        AllowListView.Add(, exe)
    }

    if FileExist(AllowListFile) {
        for line in StrSplit(FileRead(AllowListFile, "UTF-8"), "`n") {
            cleaned := Trim(line, "`r`n `t")
            if (cleaned = "" || SubStr(cleaned, 1, 1) = "#" || InStr(cleaned, "title:"))
                continue
            
            AllowListView.Add(, cleaned)
        }
    }
    AllowListView.ModifyCol(1, "AutoHdr")
}


; --- NOVAS FUNÇÕES PARA GERENCIAR A JANELA E SAÍDA ---
ShowHideGUI(*) {
    if myGui.Visible
        myGui.Hide()
    else
        myGui.Show()
}

ExitScriptHandler(*) {
    global PomodoroOn
    if PomodoroOn {
        response := MsgBox("Uma sessão Pomodoro está em andamento. Deseja realmente sair?", "Confirmação", "YesNo IconQuestion")
        if response = "No"
            return
    }
    ExitApp()
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