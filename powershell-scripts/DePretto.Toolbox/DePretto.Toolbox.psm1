Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter *.ps1 -File | ForEach-Object { . $_.FullName }

Export-ModuleMember -Function *