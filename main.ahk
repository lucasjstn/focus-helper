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
btn.OnEvent("Click", StartSession)

lbl := myGui.AddText("w240 Center vLbl", "25:00")

myGui.AddText("w240 Center", "Adicionar processo à allowlist:")
myGui.AddEdit("w240 vAllowEdit", "")
btnAdd := myGui.AddButton("w240 h30", "Adicionar")
btnAdd.OnEvent("Click", AddToAllowlistHandler)

; --- NOVO CONTROLE LISTVIEW ADICIONADO AQUI ---
myGui.AddText("w240", "Processos permitidos atualmente:")
global AllowListView := myGui.AddListView("w240 r10 vAllowListView", ["Nome do Processo"])
AllowListView.ModifyCol(1, "230") ; Ajusta a largura da coluna
; --- FIM DO NOVO CONTROLE ---

; Bloqueio de fechar a janela
myGui.OnEvent("Close", OnGuiClose)
myGui.Show()

; --- LÓGICA INICIAL ADICIONADA AQUI ---
; Carrega a lista de permissões e atualiza a exibição na tela assim que o script inicia.
InitAllowList()
; --- FIM DA LÓGICA INICIAL ---


; --- NOVA FUNÇÃO DE EXIBIÇÃO ADICIONADA AQUI ---
UpdateAllowlistDisplay() {
    global AllowListView, CoreAllowList, AllowListFile

    ; 1. Limpa a lista atual para evitar duplicatas
    AllowListView.Delete()

    ; 2. Adiciona os itens da lista principal (CoreAllowList)
    for exe, _ in CoreAllowList {
        AllowListView.Add(, exe)
    }

    ; 3. Lê e adiciona os itens da lista externa (allowlist.txt)
    if FileExist(AllowListFile) {
        for line in StrSplit(FileRead(AllowListFile, "UTF-8"), "`n") {
            cleaned := Trim(line, "`r`n `t")
            ; Ignora linhas vazias, comentários ou de permissão por título
            if (cleaned = "" || SubStr(cleaned, 1, 1) = "#" || InStr(cleaned, "title:"))
                continue
            
            AllowListView.Add(, cleaned)
        }
    }
    AllowListView.ModifyCol(1, "AutoHdr") ; Reajusta a coluna ao conteúdo
}
; --- FIM DA NOVA FUNÇÃO ---


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