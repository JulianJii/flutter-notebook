# Test Generator & Runner (Windows / PowerShell)
# 与 test_generator.sh 行为一致：运行测试并生成覆盖率报告。
# 用法（PowerShell 7 / Windows PowerShell）：
#   powershell -ExecutionPolicy Bypass -File .\test_generator.ps1                 # 全量测试 + 覆盖率
#   powershell -ExecutionPolicy Bypass -File .\test_generator.ps1 --target test/features/auth/

# 不声明 param()，统一手工解析 $args，保持与 .sh 相同的命令行约定。

function Show-Usage {
    Write-Host "Usage: test_generator.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --no-coverage         Run tests without coverage"
    Write-Host "  --no-report           Don't generate coverage report"
    Write-Host "  --target <path>       Run tests in specific path only"
    Write-Host "  --help                Display this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\test_generator.ps1                                # Run all tests with coverage"
    Write-Host "  .\test_generator.ps1 --target test/features/auth/   # Run only auth feature tests"
    exit 1
}

$coverage = $true
$report = $true
$target = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '--no-coverage' { $coverage = $false }
        '--no-report' { $report = $false }
        '--target' { $target = $args[++$i] }
        '--help' { Show-Usage }
        default {
            Write-Host "Error: Unknown option: $($args[$i])" -ForegroundColor Red
            Show-Usage
        }
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host 'Error: Flutter command not found.' -ForegroundColor Red
    exit 1
}

if ($coverage) {
    Write-Host "`nRunning tests with coverage..." -ForegroundColor Yellow
    if ($target) {
        flutter test --coverage $target
    } else {
        flutter test --coverage
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nTests failed!" -ForegroundColor Red
        exit 1
    }

    if ($report) {
        Write-Host "`nGenerating coverage report..." -ForegroundColor Yellow
        if (Get-Command lcov -ErrorAction SilentlyContinue) {
            & genhtml coverage/lcov.info -o coverage/html
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`nCoverage report generated!" -ForegroundColor Green
                Write-Host 'Open coverage/html/index.html in your browser to view it.' -ForegroundColor Green
                Start-Process coverage/html/index.html
            } else {
                Write-Host "`nFailed to generate HTML coverage report." -ForegroundColor Red
                Write-Host 'Please make sure lcov is installed correctly.'
            }
        } else {
            Write-Host "`nlcov is not installed. Cannot generate HTML coverage report." -ForegroundColor Yellow
            Write-Host 'You can install it with: choco install lcov'
            Write-Host "`nAlternatively, you can view the raw coverage data in coverage/lcov.info" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "`nRunning tests without coverage..." -ForegroundColor Yellow
    if ($target) {
        flutter test $target
    } else {
        flutter test
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nTests failed!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nTests completed successfully!" -ForegroundColor Green
exit 0
