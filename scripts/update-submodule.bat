@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "repository_root=%~dp0.."

git -C "%repository_root%" submodule update --init --recursive
if errorlevel 1 exit /b 1

for /f "tokens=1,2" %%A in ('git -C "%repository_root%" config -f .gitmodules --get-regexp "^submodule\..*\.branch$"') do (
    set "path_key=%%A"
    set "path_key=!path_key:.branch=.path!"
    for /f "delims=" %%P in ('git -C "%repository_root%" config -f .gitmodules --get "!path_key!"') do set "submodule_path=%%P"

    git -C "%repository_root%\!submodule_path!" fetch origin "%%B"
    if errorlevel 1 exit /b 1
    git -C "%repository_root%\!submodule_path!" show-ref --verify --quiet "refs/heads/%%B"
    if errorlevel 1 (
        git -C "%repository_root%\!submodule_path!" checkout -b "%%B" --track "origin/%%B"
    ) else (
        git -C "%repository_root%\!submodule_path!" checkout "%%B"
    )
    if errorlevel 1 exit /b 1
    git -C "%repository_root%\!submodule_path!" pull --ff-only origin "%%B"
    if errorlevel 1 exit /b 1
)

pause