
function Ensure-MgGraphReady {
    # Check and install Microsoft.Graph module if missing
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "📦 Microsoft.Graph module not found. Installing..."
        Install-Module Microsoft.Graph -Scope AllUsers -Force
    }

    # Check if connected to Microsoft Graph
    try {
        if (-not (Get-MgContext)) {
            Write-Host "🔐 Not connected to Microsoft Graph. Signing in..."
            Connect-MgGraph # -Scopes "Group.ReadWrite.All", "Device.Read.All", "Directory.Read.All"
        }
    } catch {
        Write-Error "❌ Failed to connect to Microsoft Graph: $_"
        throw
    }
}
function Add-DeviceToGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$GroupName,
        [Parameter(ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    begin {
        Ensure-MgGraphReady
    }
    process {
        $device = Get-MgDevice -Filter "displayName eq '$DeviceName'" -ErrorAction SilentlyContinue
        if (-not $device) {
            Write-Warning "⚠️ Device'$DeviceName' is not found"
            return
        }
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
        if (-not $group) {
            Write-Warning "⚠️ Group '$GroupName' is not found"
            return
        }
        try {
            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($device.Id)"
            }
            Write-Host "✅ Device'$DeviceName' has been added to Group '$GroupName'"
        } catch {
            Write-Error "❌ Failed to add: $_"
        }
    }
}
function Remove-DeviceFromGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$GroupName,
        [Parameter(ValueFromPipeline = $true)]
        [string]$DeviceName
    )
    begin {
        Ensure-MgGraphReady
    }
    process {
        $device = Get-MgDevice -Filter "displayName eq '$DeviceName'" -ErrorAction SilentlyContinue
        if (-not $device) {
            Write-Warning "⚠️ Device $DeviceName' is not found."
            return
        }
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
        if (-not $group) {
            Write-Warning "⚠️ Group'$GroupName' is not found"
            return
        }
        try {
            Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $device.Id
            Write-Host "✅ Device '$DeviceName' has been removed from Group $GroupName'"
        } catch {
            Write-Error "❌ Faied to remove: $_"
        }
    }
}


