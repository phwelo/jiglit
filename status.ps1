param (
    [Parameter(Mandatory=$true)]
    [string]$Username
)

function Get-Status($UserName) {
    Connect-MgGraph -NoWelcome
    $User = Get-MgUser -UserId $UserName
    $Presence = Get-MgCommunicationPresence -PresenceId $User.Id
    $Presence.Availability
}

function main {
    Get-Status -UserName $UserName
}

Out-File -FilePath ./status -InputObject (main) -Encoding ascii
