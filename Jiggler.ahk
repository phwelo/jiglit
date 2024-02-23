#Persistent

; Effectively the Main{}
SetTimer, CheckIdle, 1000
configFile := "config.ini" ; Specify the path to your INI file

; Read each setting from the INI file
IniRead, waitTimeSeconds, %configFile%, Settings, waitTimeSeconds
IniRead, movementSpeed, %configFile%, Settings, movementSpeed
IniRead, countdownTime, %configFile%, Settings, countdownTime
IniRead, osdMsg, %configFile%, Settings, osdMsg
IniRead, transColor, %configFile%, Settings, transColor
IniRead, fontSize, %configFile%, Settings, fontSize
IniRead, fontColor, %configFile%, Settings, fontColor
IniRead, font, %configFile%, Settings, font
IniRead, boxWidth, %configFile%, Settings, boxWidth
IniRead, boxHeight, %configFile%, Settings, boxHeight
IniRead, xStart, %configFile%, Settings, xStart
IniRead, yStart, %configFile%, Settings, yStart
IniRead, username, %configFile%, Settings, username
IniRead, coords, %configFile%, Settings, coords
IniRead, icon, %configFile%, Settings, icon
coordinates := LoadCoordinatesFromFile("coords")

; Initialize variables
Menu, Tray, Icon, %icon%
moving := false

F12::
    Tooltip
    Pause
    return

ShowOSD(text) {
    global fontsize, transcolor, osdText, fontcolor, font, xStart, yStart, boxheight, boxwidth
    screenHeight := A_ScreenHeight  ; Get the screen height

    if !WinExist("OSD")
    {
        Gui, osd:New, +LastFound +AlwaysOnTop -Caption +ToolWindow ; +ToolWindow for no taskbar icon, -Caption for borderless
        Gui, osd:Color, %transcolor%
        WinSet, TransColor, %transcolor% 200
        Gui, osd:Font, s%fontsize% %fontcolor%, %font% ; Set the font size to 9 and color to white
        Gui, osd:Add, Text, vosdText Center, %text%... 
        xPos := xStart
        yPos := screenHeight + yStart
        Gui, osd:Show, w%boxwidth% h%boxheight% x%xPos% y%yPos% , OSD ; Show the GUI near the bottom left
    }
    else
    {
        ; Update the text of the existing Text control
        GuiControl, osd:, osdText, %text%...
    }
    return
}

RemoveOSD:
    Gui, osd:Hide
    return

CheckIdle:
    global countdowntime, moving, waitTimeSeconds
    RunPowerShellScript()
    sleep 500
    statusContent := GetStatus()

    if (!InStr(statusContent, "Available"))
    {
        moving := false
        return
    }
    idleTime := GetIdleTime()
    remainingTime := (waitTimeSeconds * 1000 - idleTime) / 1000  ; Calculate remaining time in seconds
    ; Check if we're within the final X seconds countdown and not moving yet
    if (remainingTime <= countdowntime && remainingTime > 0 && !moving)
    {
        roundedRemainingTime := Round(remainingTime)
        ; Display the countdown text on a transparent background
        ShowCountdown(roundedRemainingTime)
        Sleep, 1000  ; Update every second
        return
    }
    else if (idleTime >= waitTimeSeconds * 1000 && !moving)
    {
        HideCountdown()  ; Clear any existing countdown display
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
        sleep 500
    }
return

GetStatus() {
    ; Ensure the file exists
    if !FileExist("status") {
        MsgBox, % "File not found: " "status"
        return ""  ; Return an empty string if the file does not exist
    }
    FileRead, fileContents, status
    return %fileContents%
}

ShowCountdown(remainingTime) {
    global fontsize, transcolor, fontcolor, font, CountdownText, xStart, yStart, boxheight, boxwidth
    screenHeight := A_ScreenHeight  ; Get the screen height
    text = Move mode in %remainingTime%...
    ; Check if GUI exists, if not create it
    if !WinExist("Countdown")
    {
        Gui, tb:New, +LastFound +AlwaysOnTop -Caption +ToolWindow ; +ToolWindow for no taskbar icon, -Caption for borderless
        Gui, tb:Color, %transcolor%
        WinSet, TransColor, %transcolor% 200
        Gui, tb:Font, s%fontsize% %fontcolor%, %font% ; Set the font size to 9 and color to white
        Gui, tb:Add, Text, vCountdownText Center, %text%
        xPos := xStart ; Small x value to keep it near the left edge
        yPos := screenHeight + yStart ; screenHeight minus GUI height minus a little padding (e.g., 10 pixels)
        Gui, tb:Show, w%boxwidth% h%boxheight% x%xPos% y%yPos% , Countdown ; Show the GUI near the bottom left
    }
    else
    {
        ; Update the text of the existing Text control
        GuiControl, tb:, CountdownText, %text%
    }
    return
}

HideCountdown() {
    Gui, tb:Destroy
}

CheckForInterrupt() {
    global moving  ; Access the global moving variable
    ; Check for user input (mouse click or space bar press) to exit the loop 
    if (GetKeyState("LButton", "P") || GetKeyState("RButton", "P") ||  GetKeyState("Escape", "P") || GetKeyState("LControl", "P") || GetKeyState("RControl", "P") || GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))
    {
        Gosub, RemoveOSD
        moving := false
        return true  ; Indicate that an interrupt has occurred
    }
    return false  ; No interrupt, continue execution
}

MoveMouseCursor:
    ShowOSD(osdmsg)
    global coordinates, movementSpeed
    Loop
    {
        for index, coord in coordinates
        {
            MouseMove, coord.x, coord.y + 20, movementSpeed

            if (CheckForInterrupt())
                return
        }
        Sleep, 100 ; Pause for a moment before reversing the path
        ; Move backward along the path
        loop, % coordinates.MaxIndex()
        {
            coord := coordinates[coordinates.MaxIndex() + 1 - A_Index]
            MouseMove, coord.x, coord.y + 20, movementSpeed
            if (CheckForInterrupt())
                return
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

LoadCoordinates(filePath) {
    ; Initialize an empty array to hold the coordinates
    local coordinates := []
    if !FileExist(filePath)
    {
        MsgBox, % "File not found: " filePath
        return coordinates ; Return an empty array if file doesn't exist
    }
    FileRead, csvContent, % filePath
    lines := StrSplit(csvContent, "`n", "`r")
    for _, line in lines
    {
        if (line = "")
            continue
        xy := StrSplit(line, ",")
        x := xy[1]
        y := xy[2]
        coordinates.Push({"x": x, "y": y})
    }
    return coordinates
}

RunPowerShellScript() {
    global username
    scriptPath := ".\status.ps1"
    command := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ . A_ScriptDir . "\" . scriptPath . """ -username " . username
    Run, %command%, , Hide  ; Use 'Hide' to run the script without showing the PowerShell window
}

LoadCoordinatesFromFile(filePath) {
    local coordinates := []
    if !FileExist(filePath) {
        MsgBox, % "File not found: " filePath
        
    }
    FileRead, fileContent, %filePath%
    lines := StrSplit(fileContent, "`n", "`r")
    for _, line in lines {
        if (line = "")
            continue
        xy := StrSplit(line, ",")
        coordinates.Push({"x": Trim(xy[1]), "y": Trim(xy[2])})
    }
    return coordinates
}
