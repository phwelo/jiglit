#Persistent
SetTimer, CheckIdle, 1000

; Configuration
appclass = TeamsWebView  ; Class of the application to activate, from Window Spy
waitTimeSeconds := 90  ; Idle time before the script activates
movementSpeed := 20  ; Speed of mouse movement, lower is faster. Looks cooler slower, but less responsive to interruption
countdowntime := 15  ; Time for which to display countdown tooltip
osdmsg = Hold a mouse button to wake
transcolor = "0f0f0f"
fontsize = 30
fontcolor = cWhite
;   "cBlack",
;   "cWhite",
;   "cRed",
;   "cGreen",
;   "cBlue",
;   "cYellow",
;   "cMagenta",
;   "cFuchsia",
;   "cCyan",
;   "cAqua",
;   "cSilver",
;   "cGray",
;   "cGrey",
;   "cMaroon",
;   "cOlive",
;   "cPurple",
;   "cTeal",
;   "cNavy",
;   "cLime"

font = Times New Roman
;   "Arial",
;   "Verdana",
;   "Times New Roman",
;   "Courier New",
;   "Calibri",
;   "Cambria",
;   "Segoe UI"

countSize = 12
countColor = cWhite
countFont = Arial

; Initialize variables
Menu, Tray, Icon, C:\Windows\explorer.exe, 13 ; 13 = globe, 
stepSize := 1000
screenWidth := A_ScreenWidth
movementWidth := screenWidth * 0.4  ; 40% of the screen width
startPosX := (screenWidth - movementWidth) / 2
endPosX := startPosX + movementWidth
currentPosX := startPosX
direction := 1
moving := false

F12::
Tooltip
Pause
return

ShowOSD(text) {
    global fontcolor, font, fontsize, transcolor
    Gui, osd:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +Owner  ; Always on top, no window borders, and not appear in taskbar
    Gui, osd:Color, transcolor
    Gui, osd:Font, s%fontsize% fontcolor, %font%
    textOptions := fontcolor . " Center"
    Gui, osd:Add, Text, %textOptions%, %text%
    Gui, osd:Show, NoActivate Center
    Gui_ID := WinExist()  ; Correctly capture the GUI window's ID
    WinSet, TransColor, transcolor, ahk_id %Gui_ID% 
    return
}

RemoveOSD:
    Gui, Destroy
    return

    CheckIdle:
    global countdowntime, moving, waitTimeSeconds
    idleTime := GetIdleTime()
    remainingTime := (waitTimeSeconds * 1000 - idleTime) / 1000  ; Calculate remaining time in seconds

    ; Check if we're within the final 5 seconds countdown and not moving yet
    if (remainingTime <= countdowntime && remainingTime > 0 && !moving)
    {
        ; Round the remaining time to the nearest second
        roundedRemainingTime := Round(remainingTime)
        ; Display the countdown text on a transparent background
        ShowCountdown(roundedRemainingTime)
        Sleep, 1000  ; Update every second
        return  ; Ensure the loop continues checking without proceeding further
    }
    else if (idleTime >= waitTimeSeconds * 1000 && !moving)
    {
        HideCountdown()  ; Clear any existing countdown display
        Gosub, ActivateApp
        moving := true
        Gosub, MoveMouseCursor
    }
    else if (moving && GetIdleTime() < 1000)  ; Exit loop if user activity is detected
    {
        moving := false
    }
    else
    {
        HideCountdown()  ; Ensure the countdown display is cleared if not in the final countdown
        sleep 200
    }
return

ShowCountdown(remainingTime) {
    global countSize, countColor, countFont, transcolor
    screenHeight := A_ScreenHeight  ; Get the screen height
    screenWidth := A_ScreenWidth  ; Get the screen width
    Gui, Countdown:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +Owner +0x80000
    Gui, Countdown:Color, %transcolor%
    Gui, Countdown:Font, s%countSize% %countColor%, %countFont%
    Gui, Countdown:Add, Text, % "Center " . countColor, % "Away mode in " . remainingTime . "..."
    
    ; Calculate positions for the GUI
    xPos := screenWidth - 210  ; Calculate x position
    yPos := screenHeight - 128  ; Calculate y position to avoid overlapping with the taskbar
    
    Gui, Countdown:Show, NoActivate x%xPos% y%yPos% w200 h50  ; Show the GUI
    Gui_ID := WinExist()  ; Correctly capture the GUI window's ID
    
    WinSet, TransColor, %transcolor% 255, ahk_id %Gui_ID%  ; Apply transparency to the specified background color
}


HideCountdown() {
    Gui, Countdown:Destroy  ; Close the countdown GUI
}



ActivateApp:
    global appclass
    If WinExist("ahk_class " . appclass)
    {
        WinActivate
    }
return

CheckForInterrupt() {
    global moving  ; Access the global moving variable
    ; Check for user input (mouse click or space bar press) to exit the loop
    if (GetKeyState("LButton", "P") || GetKeyState("RButton", "P") || GetKeyState("Space", "P")) {
        Gosub, RemoveOSD
        moving := false
        return true  ; Indicate that an interrupt has occurred
    }
    return false  ; No interrupt, continue execution
}

MoveMouseCursor:
    ShowOSD(osdmsg)
    Loop
    {
        if (CheckForInterrupt())
            return

        ; Adjust the mouse position and move it
        MouseMove, currentPosX, A_ScreenHeight / 2, movementSpeed  ; Use the movementSpeed variable

        if (CheckForInterrupt())
            return

        currentPosX += stepSize * direction
        if (currentPosX >= endPosX || currentPosX <= startPosX) {
            direction *= -1  ; Change direction at the boundaries
            currentPosX := direction == 1 ? startPosX : endPosX
        }
    }
return


GetIdleTime(){
    VarSetCapacity(lii, 8, 0)  ; Prepare the structure for the DllCall
    NumPut(8, lii, 0, "UInt")  ; Set the size of the structure
    if !DllCall("GetLastInputInfo", "Ptr", &lii)
        return -1  ; Error handling
    return A_TickCount - NumGet(lii, 4, "UInt")  ; Calculate and return idle time
}
