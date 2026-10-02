# Localization Helper (Windows / PowerShell)
# 与 generate_language.sh 行为一致：管理 lib/l10n/arb 下的语言文件。
# 用法（PowerShell 7 / Windows PowerShell）：
#   powershell -ExecutionPolicy Bypass -File .\generate_language.ps1 list
#   powershell -ExecutionPolicy Bypass -File .\generate_language.ps1 add fr
#   powershell -ExecutionPolicy Bypass -File .\generate_language.ps1 generate
#   powershell -ExecutionPolicy Bypass -File .\generate_language.ps1 check

# 不声明 param()，统一手工解析 $args，保持与 .sh 相同的子命令约定。

$ErrorActionPreference = 'Stop'

$baseArbDir = 'lib/l10n/arb'
$baseArbFile = "$baseArbDir/intl_en.arb"

# 只取顶层的普通字符串条目（与 .sh 的 grep 等价，@ 开头的是元数据）
function Get-ArbKeys {
    param([string]$Path)
    $content = [System.IO.File]::ReadAllText($Path)
    $keyMatches = [regex]::Matches($content, '(?m)^\s*"([^"@][^"]*)":\s*"')
    return @($keyMatches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
}

function Invoke-GenerateL10n {
    Write-Host 'Generating localization files...' -ForegroundColor Yellow
    & flutter gen-l10n
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Localization files generated successfully!' -ForegroundColor Green
    } else {
        Write-Host 'Failed to generate localization files!' -ForegroundColor Red
        exit 1
    }
}

function Show-Languages {
    Write-Host 'Currently supported languages:' -ForegroundColor Yellow
    Get-ChildItem -LiteralPath $baseArbDir -Filter 'intl_*.arb' -File | ForEach-Object {
        $langCode = ($_.BaseName -replace '^intl_', '')
        $content = [System.IO.File]::ReadAllText($_.FullName)
        $langName = $langCode
        if ($content -match '"@@locale":\s*"([^"]*)"') { $langName = $Matches[1] }
        Write-Host " - $langCode ($langName)" -ForegroundColor Green
    }
}

function Add-Language {
    param([string]$LangCode)

    if (-not $LangCode) {
        Write-Host 'Error: No language code provided.' -ForegroundColor Red
        Write-Host 'Usage: generate_language.ps1 add <language_code>'
        exit 1
    }

    $newArbFile = "$baseArbDir/intl_${LangCode}.arb"
    if (Test-Path -LiteralPath $newArbFile) {
        Write-Host "Error: Language file for '$LangCode' already exists." -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path -LiteralPath $baseArbFile)) {
        Write-Host "Error: Base language file ($baseArbFile) not found." -ForegroundColor Red
        exit 1
    }

    $content = [System.IO.File]::ReadAllText($baseArbFile)
    $content = [regex]::Replace($content, '"@@locale":\s*"[^"]*"', ('"@@locale": "' + $LangCode + '"'))
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($newArbFile, $content, $utf8)

    Write-Host "Created new language file: $newArbFile" -ForegroundColor Green
    Write-Host 'Please translate the strings in the new file.' -ForegroundColor Yellow
}

function Test-MissingTranslations {
    Write-Host 'Checking for missing translations...' -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $baseArbFile)) {
        Write-Host "Error: Base language file ($baseArbFile) not found." -ForegroundColor Red
        exit 1
    }

    $baseKeys = Get-ArbKeys $baseArbFile
    $baseFull = Resolve-Path -LiteralPath $baseArbFile

    Get-ChildItem -LiteralPath $baseArbDir -Filter 'intl_*.arb' -File | ForEach-Object {
        if ((Resolve-Path -LiteralPath $_.FullName).Path -eq $baseFull.Path) { return }

        $langCode = ($_.BaseName -replace '^intl_', '')
        Write-Host ""
        Write-Host "Checking ${langCode}:" -ForegroundColor Blue

        $keys = Get-ArbKeys $_.FullName
        $missing = @($baseKeys | Where-Object { $keys -notcontains $_ })
        if ($missing.Count -eq 0) {
            Write-Host ' All translations present' -ForegroundColor Green
        } else {
            $missing | ForEach-Object { Write-Host " - Missing: $_" -ForegroundColor Red }
            Write-Host " $($missing.Count) translation(s) missing" -ForegroundColor Red
        }
    }
}

function Show-Usage {
    Write-Host 'Usage: generate_language.ps1 <command>'
    Write-Host ""
    Write-Host 'Commands:'
    Write-Host '  generate     - Generate localization files' -ForegroundColor Green
    Write-Host '  list         - List supported languages' -ForegroundColor Green
    Write-Host "  add <code>   - Add a new language (e.g., 'add fr' for French)" -ForegroundColor Green
    Write-Host '  check        - Check for missing translations' -ForegroundColor Green
    Write-Host '  help         - Show this help message' -ForegroundColor Green
}

Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

switch ($args[0]) {
    'generate' { Invoke-GenerateL10n }
    'list' { Show-Languages }
    'add' { Add-Language $args[1] }
    'check' { Test-MissingTranslations }
    'help' { Show-Usage }
    default {
        Show-Usage
        exit 1
    }
}
exit 0
