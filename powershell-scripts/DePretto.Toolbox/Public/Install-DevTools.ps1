#Requires -Version 7.5

<#
.SYNOPSIS
    Installs developer Tools via winget.

.DESCRIPTION
    Checks for the presence of winget, then installs Git, VS Code, Visual Studio 2022,
    and JetBrains Toolbox. Supports WhatIf and Verbose.

.PARAMETER VSVersion
    The version of Visual Studio 2022 to install (Community, Professional, Enterprise).

.EXAMPLE
    # Dry-run, show what would be done
    Install-DevTools -VSVersion Community -WhatIf -Verbose

.EXAMPLE
    # Actually perform installations
    Install-DevTools -VSVersion Professional -Verbose
#>

function Install-DevTools {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
    param(
        [Parameter()]
        [ValidateSet("Community", "Professional", "Enterprise")]
        [string]$VSVersion = "Community"
    )

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget not found. Please install the App Installer from Microsoft Store."
        return
    }

    $Tools = @(
        @{ Name = "Git"; Id = "Git.Git" },
        @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode" },
        @{ Name = "Visual Studio $VSVersion"; Id = "Microsoft.VisualStudio.2022.$VSVersion" },
        @{ Name = "JetBrains Toolbox"; Id = "JetBrains.Toolbox" }
    )

    for ($i = 0; $i -lt $Tools.Count; $i++) {
        $tool = $Tools[$i]

        Write-Progress -Activity "Installing developer tools" `
            -Status "Installing $($tool.Name)" `
            -PercentComplete [int]((($i + 1) / $Tools.Count) * 100)

        if ($PSCmdlet.ShouldProcess($tool.Name, "Install")) {
            Write-Verbose "Installing $($tool.Name) via winget..."

            try {
                $null = winget install --source winget --id $tool.Id -e --silent -ErrorAction Stop
                Write-Host "Installed $($tool.Name)"
            }
            catch {
                Write-Error "Failed to install $($tool.Name): $_"
            }
        }
    }

    Write-Progress -Activity "Installing developer tools" -Completed
}