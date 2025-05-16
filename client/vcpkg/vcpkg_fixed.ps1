[CmdletBinding()]
param(
    $badParam,
    [Parameter(Mandatory=$False)][switch]$win64 = $false,
    [Parameter(Mandatory=$False)][string]$withVSPath = "",
    [Parameter(Mandatory=$False)][string]$withWinSDK = "",
    [Parameter(Mandatory=$False)][switch]$disableMetrics = $false
)
Set-StrictMode -Version Latest
# Powershell2-compatible way of forcing named-parameters
if ($badParam)
{
    if ($disableMetrics -and $badParam -eq "1")
    {
        Write-Warning "'disableMetrics 1' is deprecated, please change to 'disableMetrics' (without '1')."
    }
    else
    {
        throw "Only named parameters are allowed."
    }
}

if ($win64)
{
    Write-Warning "-win64 no longer has any effect; ignored."
}

if (-Not [string]::IsNullOrWhiteSpace($withVSPath))
{
    Write-Warning "-withVSPath no longer has any effect; ignored."
}

if (-Not [string]::IsNullOrWhiteSpace($withWinSDK))
{
    Write-Warning "-withWinSDK no longer has any effect; ignored."
}

# Definir o diretório de instalação do vcpkg como c:\vcpkg
$vcpkgRootDir = "c:\vcpkg"

# Criar o diretório se não existir
if (!(Test-Path -Path $vcpkgRootDir)) {
    Write-Host "Criando diretório $vcpkgRootDir..."
    New-Item -ItemType Directory -Path $vcpkgRootDir -Force | Out-Null
}

# Criar arquivo .vcpkg-root para marcar o diretório como raiz do vcpkg
if (!(Test-Path "$vcpkgRootDir\.vcpkg-root")) {
    Write-Host "Criando arquivo .vcpkg-root em $vcpkgRootDir..."
    New-Item -ItemType File -Path "$vcpkgRootDir\.vcpkg-root" -Force | Out-Null
}

Write-Verbose "Usando $vcpkgRootDir como diretório raiz do vcpkg"

# Salvar o diretório atual do script
$scriptsDir = split-path -parent $script:MyInvocation.MyCommand.Definition

# Verificar se o arquivo de metadados existe no diretório do script
$metadataPath = Join-Path $scriptsDir "vcpkg-tool-metadata.txt"
Write-Host "Procurando arquivo de metadados em: $metadataPath"

if (Test-Path $metadataPath) {
    # Read the vcpkg-tool config file to determine what release to download
    Write-Host "Arquivo de metadados encontrado, lendo configuração..."
    $Config = ConvertFrom-StringData (Get-Content $metadataPath -Raw)
    $versionDate = $Config.VCPKG_TOOL_RELEASE_TAG
    Write-Host "Versão do vcpkg definida como: $versionDate"
} else {
    # Usar a versão mais recente se o arquivo não existir
    $versionDate = "2023.12.12"
    Write-Host "Arquivo de metadados não encontrado. Usando versão padrão: $versionDate"
}

# Baixar o binário do vcpkg diretamente
Write-Host "Baixando vcpkg para $vcpkgRootDir..."

# Criar diretório temporário para os downloads
$tempDir = Join-Path $env:TEMP "vcpkg-download"
if (!(Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Definir URLs e caminhos
$downloadUrl = "https://github.com/microsoft/vcpkg-tool/releases/download/$versionDate/vcpkg.exe"
$downloadUrlArm64 = "https://github.com/microsoft/vcpkg-tool/releases/download/$versionDate/vcpkg-arm64.exe"
$tempFile = Join-Path $tempDir "vcpkg.exe"

# Baixar o arquivo apropriado baseado na arquitetura
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_IDENTIFIER -match "ARMv[8,9] \(64-bit\)") {
    Write-Host "Detectada arquitetura ARM64, baixando versão específica..."
    Invoke-WebRequest -Uri $downloadUrlArm64 -OutFile $tempFile -UseBasicParsing
} else {
    Write-Host "Baixando vcpkg.exe..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
}

# Copiar para o diretório de destino
try {
    Copy-Item -Path $tempFile -Destination "$vcpkgRootDir\vcpkg.exe" -Force
    Write-Host "vcpkg.exe copiado com sucesso para $vcpkgRootDir"
} catch {
    Write-Error "Falha ao copiar vcpkg.exe para o diretório de destino: $_"
    Write-Error "Verifique sua conexão com a internet ou considere baixar o vcpkg.exe manualmente de https://github.com/microsoft/vcpkg-tool"
    throw
}

Write-Host ""

try {
    # Executar o comando vcpkg e capturar a saída
    $vcpkgOutput = & "$vcpkgRootDir\vcpkg.exe" version --disable-metrics 2>&1
    
    # Verificar se o comando foi bem-sucedido
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha ao executar vcpkg.exe: $vcpkgOutput"
        Write-Warning "O vcpkg foi instalado, mas pode haver problemas com a execução."
    } else {
        Write-Host "vcpkg instalado com sucesso!"
    }
} catch {
    Write-Error "Erro ao executar vcpkg.exe: $_"
    Write-Warning "O vcpkg foi instalado, mas pode haver problemas com a execução."
}

if ($disableMetrics)
{
    Set-Content -Value "" -Path "$vcpkgRootDir\vcpkg.disable-metrics" -Force
}
elseif (-Not (Test-Path "$vcpkgRootDir\vcpkg.disable-metrics"))
{
    # Note that we intentionally leave any existing vcpkg.disable-metrics; once a user has
    # opted out they should stay opted out.
    Write-Host @"
Telemetry
---------
vcpkg collects usage data in order to help us improve your experience.
The data collected by Microsoft is anonymous.
You can opt-out of telemetry by re-running the bootstrap-vcpkg script with -disableMetrics,
passing --disable-metrics to vcpkg on the command line,
or by setting the VCPKG_DISABLE_METRICS environment variable.

Read more about vcpkg telemetry at docs/about/privacy.md
"@
}

# Configurar variáveis de ambiente para o vcpkg
Write-Host "Configurando variáveis de ambiente para vcpkg..."

# Definir VCPKG_ROOT para o usuário atual
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", $vcpkgRootDir, [System.EnvironmentVariableTarget]::User)
# Atualizar a variável na sessão atual
$env:VCPKG_ROOT = $vcpkgRootDir

# Adicionar vcpkg ao PATH do usuário atual
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$vcpkgRootDir*") {
    $newPath = "$vcpkgRootDir;$currentPath"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    # Atualizar a variável na sessão atual
    $env:PATH = "$vcpkgRootDir;$env:PATH"
}

# Configurar variáveis específicas para o DeeperHub
[System.Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_TRIPLET", "x64-windows", [System.EnvironmentVariableTarget]::User)
$env:VCPKG_DEFAULT_TRIPLET = "x64-windows"

[System.Environment]::SetEnvironmentVariable("VCPKG_FEATURE_FLAGS", "versions", [System.EnvironmentVariableTarget]::User)
$env:VCPKG_FEATURE_FLAGS = "versions"

Write-Host "Configuração concluída. vcpkg instalado em: $vcpkgRootDir"
Write-Host "VCPKG_ROOT definido como: $env:VCPKG_ROOT"
Write-Host "VCPKG_DEFAULT_TRIPLET definido como: $env:VCPKG_DEFAULT_TRIPLET"
Write-Host "VCPKG_FEATURE_FLAGS definido como: $env:VCPKG_FEATURE_FLAGS"
Write-Host "vcpkg adicionado ao PATH do usuário"
Write-Host "Para usar o vcpkg em novos terminais, reinicie-os ou abra uma nova sessão do PowerShell"
