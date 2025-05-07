# Requires elevated privileges
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Bootstraps a developer workstation: installs tools, creates a Windows 11 Dev Drive VHDX, and configures NuGet caches.
.PARAMETER VhdPath
    Full path where the VHDX will be created (default: C:\DevDrive.vhdx).
.PARAMETER VhdSize
    Size of the VHDX (default: 50GB).
.PARAMETER VsEdition
    Visual Studio edition to install (default: Community).
#>
param (
    [string]$VhdPath  = 'C:\DevDrive.vhdx',
    [string]$VhdSize  = '50GB',
    [string]$VsEdition = 'Community'
)

function Install-Tools {
    param([string]$Edition)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget not found. Please install the App Installer package."
        exit 1
    }

    Write-Host "Installing Git..."
    winget install --id Git.Git -e --source winget

    Write-Host "Installing Visual Studio Code..."
    winget install --id Microsoft.VisualStudioCode -e

    Write-Host "Installing Visual Studio $Edition..."
    winget install --id "Microsoft.VisualStudio.2022.$Edition" -e

    Write-Host "Installing JetBrains Toolbox..."
    winget install --id=JetBrains.Toolbox  -e
}

function New-DevDrive {
    param(
        [string]$Path,
        [string]$Size
    )

    if (-not (Test-Path $Path)) {
        Write-Host "Creating VHD at $Path..."
        New-VHD -Path $Path -Dynamic -SizeBytes $Size | Out-Null
    }
    else {
        Write-Host "VHD already exists at $Path; skipping creation."
    }

    Write-Host "Mounting VHD..."
    $vhd = Mount-VHD -Path $Path -Passthru
    $diskImage = $vhd | Get-DiskImage
    $disk    = $diskImage | Get-Disk
    $diskNumber = $disk.Number

    if ($disk.PartitionStyle -eq 'RAW') {
        Write-Host "Initializing disk #$diskNumber..."
        $initDisk = Initialize-Disk -Number $diskNumber -PartitionStyle GPT -PassThru

        Write-Host "Creating partition..."
        $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter -PassThru

        Write-Host "Formatting volume as ReFS DevDrive..."
        $volume = Format-Volume -Partition $partition -DevDrive -FileSystem ReFS -NewFileSystemLabel 'DevDrive' -Confirm:$false -Force
    }
    else {
        Write-Host "Disk #$diskNumber already initialized; skipping partition/format."
        $partition = Get-Partition -DiskNumber $diskNumber | Where-Object DriveLetter
        $volume = Get-Volume -Partition $partition
    }

    Write-Host "Dev Drive is mounted as $($volume.DriveLetter):"
    return $volume.DriveLetter
}

function Setup-NuGetEnv {
    param([string]$DriveLetter)

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Write-Error "dotnet CLI not found. Please install .NET SDK."
        exit 1
    }

    $BasePath = "$DriveLetter`:\NuGet"
    $Paths = @{
        'NUGET_PACKAGES'           = "$BasePath\packages"
        'NUGET_HTTP_CACHE_PATH'    = "$BasePath\http-cache"
        'NUGET_SCRATCH'            = "$BasePath\scratch"
        'NUGET_PLUGINS_CACHE_PATH' = "$BasePath\plugins-cache"
    }

    Write-Host "Clearing existing NuGet locals..."
    nuget locals all --clear

    foreach ($kv in $Paths.GetEnumerator()) {
        $key   = $kv.Key
        $value = $kv.Value

        Write-Host "Creating folder $value..."
        New-Item -ItemType Directory -Path $value -Force | Out-Null

        Write-Host "Setting environment variable $key = $value"
        $Env:$key = $value
        [System.Environment]::SetEnvironmentVariable($key, $value, 'User')
    }

    Write-Host "Listing NuGet locals:"
    dotnet nuget locals all -l
}

try {
    Install-Tools -Edition $VsEdition
    $driveLetter = New-DevDrive -Path $VhdPath -Size $VhdSize
    Setup-NuGetEnv -DriveLetter $driveLetter
    Write-Host "✅ Dev environment setup complete!"
}
catch {
    Write-Error "Setup failed: $_"
    exit 1
}