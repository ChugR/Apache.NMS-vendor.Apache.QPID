::
:: a-build_proton.bat
::

:: build N times
call :build_proton 2008 %build_root%
call :build_proton 2010 %build_root%
goto :eof


:: build a proton
::  %1 selects studio 2008 or 2010
::  %2 selects install root
:build_proton

set vsname=%1
set install_root=%2

set   build_dir=build_x86_%vsname%
set install_dir=%install_root%\install_x86_%vsname%

:: push path
setlocal

:: fresh build area
call :MakeNewDir   %build_dir% 
call :MakeNewDir %install_dir%

:: descend into build area
pushd %build_dir%

REM VS2008 or VS2010, x86
if "%vsname%"=="2008" (
	call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
                                        if %errorlevel% neq 0 exit /b %errorlevel%
	set cmakegen="Visual Studio 9 2008"
) else (
	call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\vcvars32.bat"
                                        if %errorlevel% neq 0 exit /b %errorlevel%
	set cmakegen="Visual Studio 10"
)

echo.
echo Ready to build.
IF NOT "%A_UNATTENDED%"=="T" echo Press Enter to continue, ^C to abort && pause

:: run cmake
CD
cmake -G %cmakegen% ^
  -DCMAKE_INSTALL_PREFIX=%install_dir% ^
  -DNOBUILD_JAVA=Yes ^
  -DNOBUILD_PHP=Yes ^
  -DNOBUILD_PERL=Yes ^
  -DNOBUILD_PYTHON=Yes ^
  -DNOBUILD_RUBY=Yes ^
  -DSYSINSTALL_BINDINGS=No ..
                                        if %errorlevel% neq 0 exit /b %errorlevel%

:: build/install proton
devenv proton.sln /build "Debug|Win32"          /project INSTALL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
devenv proton.sln /build "RelWithDebInfo|Win32" /project INSTALL
                                        if %errorlevel% neq 0 exit /b %errorlevel%

:: ascend from build area
popd

:: restore path
endlocal

:: done
goto :eof

REM
REM MakeNewDir dirname
REM
:MakeNewDir
echo MakeNewDir: Start recreating %1. Delete %1
rmdir /s /q %1
echo MakeNewDir: Checking if %1 still exists
if exist %1\nul (echo "ERROR: %1 still exists. Type ctrl-C to exit and fix %1" && pause && goto :eof)
echo MakeNewDir: Create %1
mkdir       %1
echo MakeNewDIr: Done  recreating %1
goto :eof
