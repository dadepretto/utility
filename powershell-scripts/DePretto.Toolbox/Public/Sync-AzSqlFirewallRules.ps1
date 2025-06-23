#Requires -Version 7.5

<#
.SYNOPSIS
    Synchronizes Azure SQL Server firewall rules.

.DESCRIPTION
    Connects to Azure under the given TenantId, then for each server in $Servers
    analyzes DesiredRules vs existing rules, queues create/update/delete actions based on flags,
    and executes them. Reports overall server progress and per-action progress.

.PARAMETER TenantId
    The Azure AD tenant ID to use for login.

.PARAMETER Servers
    Array of PSCustomObjects with ResourceGroup and Name properties.

.PARAMETER DesiredRules
    Array of PSCustomObjects with Name, StartIpAddress, and EndIpAddress properties.

.PARAMETER Create
    Switch to allow creating missing rules.

.PARAMETER Update
    Switch to allow updating rules whose IP ranges differ.

.PARAMETER Delete
    Switch to allow removing rules not in $DesiredRules.

.EXAMPLE
    # Dry-run
    Sync-AzSqlFirewallRules -TenantId "<tenant-id>" -Servers $servers -DesiredRules $rules -Create -Update -Delete -WhatIf

.EXAMPLE
    # Sync rules
    Sync-AzSqlFirewallRules -TenantId "<tenant-id>" -Servers $servers -DesiredRules $rules -Create -Update -Delete -Verbose
#>

function Sync-AzSqlFirewallRules {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$Servers,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]$DesiredRules,

        [switch]$Create,
        [switch]$Update,
        [switch]$Delete
    )

    Write-Verbose "Connecting to Azure tenant $TenantId"
    try {
        Connect-AzAccount -Tenant $TenantId -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
        return
    }

    for ($i = 0; $i -lt $Servers.Count; $i++) {
        $server = $Servers[$i]
        
        Write-Progress `
            -Activity "Syncing Azure SQL firewall rules" `
            -Status   "Server $($server.ResourceGroup)/$($server.Name)" `
            -PercentComplete ([int]((($i + 1) / $Servers.Count) * 100))

        Write-Verbose "Processing SQL server $($server.ResourceGroup)/$($server.Name)"

        try {
            $existing = Get-AzSqlServerFirewallRule `
                -ResourceGroupName $server.ResourceGroup `
                -ServerName $server.Name `
                -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to list firewall rules on $($server.ResourceGroup)/$($server.Name): $_"
            continue
        }

        # Prepare action lists
        $toCreate = @()
        if ($Create) {
            foreach ($rule in $DesiredRules) {
                if ($existing.FirewallRuleName -notcontains $rule.Name) {
                    $toCreate += $rule
                }
            }
        }

        $toUpdate = @()
        if ($Update) {
            foreach ($rule in $DesiredRules) {
                $match = $existing | Where-Object FirewallRuleName -eq $rule.Name
                if ($match -and ($match.StartIpAddress -ne $rule.StartIpAddress -or $match.EndIpAddress -ne $rule.EndIpAddress)) {
                    $toUpdate += $rule
                }
            }
        }
        
        $toDelete = @()
        if ($Delete) {
            foreach ($rule in $existing) {
                if ($DesiredRules.Name -notcontains $rule.FirewallRuleName) {
                    $toDelete += $rule
                }
            }
        }

        $totalActions = $toCreate.Count + $toUpdate.Count + $toDelete.Count

        if ($totalActions -eq 0) { 
            Write-Verbose "Nothing to do on $($server.ResourceGroup)/$($server.Name)"
            continue
        }

        $step = 0

        # Create rules
        for ($j = 0; $j -lt $toCreate.Count; $j++) {
            $rule = $toCreate[$j]
            $step++

            Write-Progress `
                -Activity "Deploying rules to $($server.ResourceGroup)/$($server.Name)" `
                -Status   "Creating rule $($rule.Name)" `
                -PercentComplete ([int](($step / $totalActions) * 100))

            if ($PSCmdlet.ShouldProcess($rule.Name, "Create rule on $($server.ResourceGroup)/$($server.Name)")) {
                try {
                    $null = New-AzSqlServerFirewallRule `
                        -ResourceGroupName $server.ResourceGroup `
                        -ServerName        $server.Name `
                        -FirewallRuleName  $rule.Name `
                        -StartIpAddress    $rule.StartIpAddress `
                        -EndIpAddress      $rule.EndIpAddress `
                        -ErrorAction       Stop

                    Write-Verbose "Created firewall rule '$($rule.Name)' on $($server.ResourceGroup)/$($server.Name)"
                }
                catch {
                    Write-Error "Failed to create firewall rule '$($rule.Name)' on $($server.ResourceGroup)/$($server.Name): $_"
                }
            }
        }

        # Update rules
        for ($j = 0; $j -lt $toUpdate.Count; $j++) {
            $rule = $toUpdate[$j]
            $step++

            Write-Progress `
                -Activity "Deploying rules to $($server.ResourceGroup)/$($server.Name)" `
                -Status   "Updating rule $($rule.Name)" `
                -PercentComplete ([int](($step / $totalActions) * 100))

            if ($PSCmdlet.ShouldProcess($rule.Name, "Update rule on $($server.ResourceGroup)/$($server.Name)")) {
                try {
                    $null = Set-AzSqlServerFirewallRule `
                        -ResourceGroupName $server.ResourceGroup `
                        -ServerName        $server.Name `
                        -FirewallRuleName  $rule.Name `
                        -StartIpAddress    $rule.StartIpAddress `
                        -EndIpAddress      $rule.EndIpAddress `
                        -ErrorAction       Stop

                    Write-Verbose "Updated firewall rule '$($rule.Name)' on $($server.ResourceGroup)/$($server.Name)"
                }
                catch {
                    Write-Error "Failed to update firewall rule '$($rule.Name)' on $($server.ResourceGroup)/$($server.Name): $_"
                }
            }
        }

        # Delete rules
        for ($j = 0; $j -lt $toDelete.Count; $j++) {
            $rule = $toDelete[$j]
            $step++

            Write-Progress `
                -Activity "Deploying rules to $($server.ResourceGroup)/$($server.Name)" `
                -Status   "Deleting rule $($rule.FirewallRuleName)" `
                -PercentComplete ([int](($step / $totalActions) * 100))

            if ($PSCmdlet.ShouldProcess($rule.FirewallRuleName, "Delete rule on $($server.ResourceGroup)/$($server.Name)")) {
                try {
                    $null = Remove-AzSqlServerFirewallRule `
                        -ResourceGroupName $server.ResourceGroup `
                        -ServerName        $server.Name `
                        -FirewallRuleName  $rule.FirewallRuleName `
                        -Force             `
                        -ErrorAction       Stop

                    Write-Verbose "Removed firewall rule '$($rule.FirewallRuleName)' on $($server.ResourceGroup)/$($server.Name)"
                }
                catch {
                    Write-Error "Failed to remove firewall rule '$($rule.FirewallRuleName)' on $($server.ResourceGroup)/$($server.Name): $_"
                }
            }
        }

        Write-Progress `
            -Activity "Deploying rules to $($server.ResourceGroup)/$($server.Name)" `
            -Completed
    }

    Write-Progress `
        -Activity "Syncing Azure SQL firewall rules" `
        -Completed
}
