$outputFile = "Contexto_Arquitectura_AWS.txt"
$basePath = (Get-Location).Path
$targetPaths = "main.tf","variables.tf","outputs.tf","backend.tf","README.md","modules","src",".github/workflows","tests"

$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText("$basePath\$outputFile", "=== REPORTE DE ARQUITECTURA PARA ANALISIS ===`n`n", $utf8)

Write-Host "[*] Iniciando extraccion segura..." -ForegroundColor Cyan

foreach ($p in $targetPaths) {
    $fullPath = "$basePath\$p"
    if (Test-Path $fullPath) {
        $items = Get-ChildItem -Path $fullPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -match "\.(tf|go|py|js|ts|json|yml|yaml|md|sh)$" -and $_.FullName -notmatch "\\\.terraform\\|\\node_modules\\|\\\.git\\"
        }
        foreach ($file in $items) {
            $rel = $file.FullName.Substring($basePath.Length + 1)
            Write-Host "Adjuntando: $rel" -ForegroundColor Yellow
            
            $header = "`n`n================================================================================`n"
            $header += "PATH: $rel`n"
            $header += "================================================================================`n`n"
            
            [IO.File]::AppendAllText("$basePath\$outputFile", $header, $utf8)
            
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($content)) { $content = "[ARCHIVO VACIO]`n" }
            
            [IO.File]::AppendAllText("$basePath\$outputFile", $content,$utf8)
        }
    } else {
        Write-Host "Omitiendo (no encontrado): $p" -ForegroundColor DarkGray
    }
}

Write-Host "[OK] Extraccion finalizada con exito. Archivo: $basePath\$outputFile" -ForegroundColor Green