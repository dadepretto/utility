#Requires -Version 7.5

<#
.SYNOPSIS
    Uninstall a fixed list of built-in UWP apps for all users.

.DESCRIPTION
    Iterates a curated list of package identifiers, attempts to find matching
    AppxPackages by name across all users, and removes them. Reports progress
    and distinguishes between "not found" and "failed to remove" scenarios.

.EXAMPLE
    # Dry-run
    Remove-Bloatware -WhatIf -Verbose

.EXAMPLE
    # Actually remove with verbose output
    Remove-Bloatware -Verbose
#>

function Remove-Bloatware {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param()

    $packagesToRemove = @(
        "Microsoft.549981C3F5F10"
        "Clipchamp.Clipchamp"
        "Microsoft.Getstarted"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.People"
        "Microsoft.ScreenSketch"
        "Microsoft.WindowsAlarms"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsNotepad"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.YourPhone"
        "MicrosoftCorporationII.QuickAssist"
        "MicrosoftTeams"
        "Microsoft.Paint"
        "Microsoft.ZuneMusic"
    )

    for ($i = 0; $i -lt $packagesToRemove.Count; $i++) {
        $packageName = $packagesToRemove[$i]

        Write-Progress -Activity "Removing bloatware" `
            -Status "Processing $packageName" `
            -PercentComplete ([int]((($i + 1) / $packagesToRemove.Count) * 100))

        try {
            $found = Get-AppxPackage -AllUsers -Name $packageName -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to query package '$packageName': $_"
            continue
        }

        if (-not $found) {
            Write-Warning "Package not found: '$packageName'"
            continue
        }

        foreach ($package in $found) {
            $fullName = $package.PackageFullName
            if ($PSCmdlet.ShouldProcess($fullName, "Remove AppxPackage")) {
                try {
                    Remove-AppxPackage -Package $fullName -ErrorAction Stop
                    Write-Verbose "Removed $fullName"
                }
                catch {
                    Write-Error "Failed to remove '$fullName': $_"
                }
            }
        }
    }

    Write-Progress -Activity "Removing bloatware" -Completed
}