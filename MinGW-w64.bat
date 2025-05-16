@echo off
echo Instalando MinGW-w64 e configurando ambiente Rust...

REM Baixar instalador do MinGW-w64
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/niXman/mingw-builds-binaries/releases/download/15.1.0-rt_v12-rev0/x86_64-15.1.0-release-posix-seh-msvcrt-rt_v12-rev0.7z' -OutFile 'mingw64.7z'"
"C:\Program Files\7-Zip\7z.exe" x mingw64.7z -oc:\

powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-win.zip'  -OutFile 'ninja-build.zip'"
"C:\Program Files\7-Zip\7z.exe" x ninja-build.zip -oc:\mingw64\bin

REM Adicionar MinGW ao PATH
setx /M PATH "%PATH%;C:\mingw64\bin"