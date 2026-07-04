@echo off
setlocal enabledelayedexpansion

rem TEMPLATE ONLY.
rem This file runs at the end of Windows setup.
rem Keep secrets out of committed examples and replace placeholders before use.
rem Safe placeholder: attempt a silent VMware Tools install if the installer is present.

set "FOUND=0"
for %%D in (D E F G H I J K L) do (
  if exist "%%D:\setup64.exe" (
    echo Found VMware Tools installer at %%D:\setup64.exe
    start /wait "" "%%D:\setup64.exe" /S /v "/qn REBOOT=R"
    set "FOUND=1"
    goto :done
  )
  if exist "%%D:\VMware Tools\setup64.exe" (
    echo Found VMware Tools installer at %%D:\VMware Tools\setup64.exe
    start /wait "" "%%D:\VMware Tools\setup64.exe" /S /v "/qn REBOOT=R"
    set "FOUND=1"
    goto :done
  )
)

echo VMware Tools installer was not found on the mounted media.
echo Replace this placeholder logic with your preferred bootstrap flow.

:done
exit /b 0
