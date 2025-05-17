@echo off
echo Instalando MinGW-w64 e configurando ambiente Rust...

REM Baixar instalador do MinGW-w64
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/niXman/mingw-builds-binaries/releases/download/15.1.0-rt_v12-rev0/x86_64-15.1.0-release-posix-seh-msvcrt-rt_v12-rev0.7z' -OutFile 'mingw64.7z'"

REM Extrair usando 7-Zip (certifique-se de ter 7-Zip instalado)
"C:\Program Files\7-Zip\7z.exe" x mingw64.7z -oc:\

REM Adicionar MinGW ao PATH
setx /M PATH "%PATH%;C:\mingw64\bin"

REM Configurar Rust para usar GNU toolchain
rustup default stable-x86_64-pc-windows-gnu

REM Limpar e reconstruir projeto
cargo clean
cargo update
cargo build -vv

echo Instalação concluída. Reinicie o terminal.