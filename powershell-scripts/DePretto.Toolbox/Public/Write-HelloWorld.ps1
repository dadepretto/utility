#Requires -Version 7.5

<#
.SYNOPSIS
    Displays the "Hello, World" standard message.

.DESCRIPTION
    Simple script that displays "Hello, World", just to verify that the basics are okay.

.EXAMPLE
    Write-HelloWorld
#>

function Write-HelloWorld {
    [CmdletBinding()]
    param()

    Write-Output 'Hello, World'
}