#Requires -Version 7.5

<#
.SYNOPSIS
    Relocates and reconfigures NuGet caches to a specified folder.

.DESCRIPTION
    Clears existing NuGet locals, creates a structured set of cache folders
    under the specified base path, sets the NUGET_* environment variables
    at user scope, then reloads them into the current session so you can
    immediately verify.

.PARAMETER NewPath
    Full path where to host the NuGet caches.

.EXAMPLE
    # Dry-run
    Move-NuGetEnv -NewPath "D:\Dev\NuGet" -WhatIf

.EXAMPLE
    # Actually relocate caches
    Move-NuGetEnv -NewPath "D:\Dev\NuGet" -Verbose
#>

function Move-NuGetEnv {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$NewPath
    )

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Write-Error "dotnet CLI not found. Please install the .NET SDK."
        return
    }

    if (-not (Test-Path $NewPath)) {
        if ($PSCmdlet.ShouldProcess($NewPath, "Create directory")) {
            try { 
                $null = New-Item -ItemType Directory -Path $NewPath -Force
            }
            catch { 
                Write-Error "Failed to create directory "$NewPath": $_"
                return 
            }
        }
    }

    if ($PSCmdlet.ShouldProcess("NuGet locals", "Clear all")) {
        nuget locals all --clear
    }

    $settings = @(
        @{ Key = "NUGET_PACKAGES"; Path = Join-Path $NewPath "packages" }
        @{ Key = "NUGET_HTTP_CACHE_PATH"; Path = Join-Path $NewPath "http-cache" }
        @{ Key = "NUGET_SCRATCH"; Path = Join-Path $NewPath "scratch" }
        @{ Key = "NUGET_PLUGINS_CACHE_PATH"; Path = Join-Path $NewPath "plugins-cache" }
    )

    for ($i = 0; $i -lt $settings.Count; $i++) {
        $setting = $settings[$i]

        Write-Progress -Activity "Relocating NuGet caches" `
            -Status "Processing $($setting.Key)" `
            -PercentComplete ([int]((($i + 1) / $settings.Count) * 100))

        if ($PSCmdlet.ShouldProcess($setting.Path, "Create folder")) {
            try { 
                $null = New-Item -ItemType Directory -Path $setting.Path -Force
            }
            catch { 
                Write-Error "Failed to create "$($setting.Path)": $_"
                continue 
            }
        }

        if ($PSCmdlet.ShouldProcess($setting.Key, "Set environment variable")) {
            try { 
                [Environment]::SetEnvironmentVariable($setting.Key, $setting.Path, "User") 
            }
            catch {
                Write-Error "Failed to set env var $($setting.Key): $_"
                continue 
            }
        }
    }

    Write-Progress -Activity "Relocating NuGet caches" -Completed
}