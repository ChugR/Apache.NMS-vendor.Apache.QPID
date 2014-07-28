::
:: a-build_qpid.bat
::
@ECHO OFF
:: SUBST is broken 2014-06-16 Windows Server 2012 R2! Since Dos 3.1, a good run.

:: Don't inherit anything from caller
set bq_platform=
set bq_version=
set bq_MAJOR=
set bq_MINOR=
set bq_REVISION=
set bq_BUILD=
set bq_versionstring=
set bq_builddir=
set bq_reusebuild=
set bq_bindingSln=
set bq_vendordir=

:: Version
:: Unix day = Epoch / 3600 / 24. http://www.epochconverter.com
IF NOT "%A_UNATTENDED%"=="T" SET /P bq_version=Enter version number [0.28.0.16239]:
if "%bq_version%"=="" SET bq_version=0.28.0.16239
FOR /f "tokens=1,2,3,4 delims=." %%a in ("%bq_version%") do set bq_MAJOR=%%a&set bq_MINOR=%%b&set bq_REVISION=%%c&set bq_BUILD=%%d

set bq_versionstring=%bq_MAJOR%.%bq_MINOR%.%bq_REVISION%.%bq_BUILD%

echo.
echo set("winver_FILE_VERSION_N1" "%bq_MAJOR%")         > cpp\src\CMakeWinVersions.cmake
echo set("winver_FILE_VERSION_N2" "%bq_MINOR%")        >> cpp\src\CMakeWinVersions.cmake
echo set("winver_FILE_VERSION_N3" "%bq_REVISION%")     >> cpp\src\CMakeWinVersions.cmake
echo set("winver_FILE_VERSION_N4" "%bq_BUILD%")        >> cpp\src\CMakeWinVersions.cmake
echo set("winver_PRODUCT_VERSION_N1" "%bq_MAJOR%")     >> cpp\src\CMakeWinVersions.cmake
echo set("winver_PRODUCT_VERSION_N2" "%bq_MINOR%")     >> cpp\src\CMakeWinVersions.cmake
echo set("winver_PRODUCT_VERSION_N3" "%bq_REVISION%")  >> cpp\src\CMakeWinVersions.cmake
echo set("winver_PRODUCT_VERSION_N4" "%bq_BUILD%")     >> cpp\src\CMakeWinVersions.cmake
type cpp\src\CMakeWinVersions.cmake

:: Fresh vendor directory
call :MakeNewDir vendor

:: build twice
call :build_qpid 2008 %build_root%
call :build_qpid 2010 %build_root%
goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::
:: build a qpid
:::::::::::::::::::::::::::::::::::::::::::::::
::  %1 selects studio 2008 or 2010
::  %2 is absolute path to install root. Install to build-specific folder
::     such as install_x86_2010.
:build_qpid

set vsname=%1
set install_root=%2

:: set output paths
set   bq_builddir=build_x86_%vsname%
set bq_installdir=%install_root%\install_x86_%vsname%

:: VS2008 or VS2010, x86
if "%vsname%"=="2008" (
	call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
	set cmakegen="Visual Studio 9 2008"
	set bq_platform=VS2008-32bit
	set MY_BOOST=C:/boost-win-1.47-32bit-vs2008
	set bq_bindingSln=%build_root%\qpid\cpp\bindings\qpid\dotnet\msvc9\org.apache.qpid.messaging.sln
	set bq_vendordir=%cd%\vendor\%bq_versionstring%\net-2.0
) else (
	call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\vcvars32.bat"
	set cmakegen="Visual Studio 10"
	set bq_platform=VS2010-32bit
	set MY_BOOST=C:/boost-win-1.47-32bit-vs2010
	set bq_bindingSln=%build_root%\qpid\cpp\bindings\qpid\dotnet\msvc10\org.apache.qpid.messaging.sln
	set bq_vendordir=%cd%\vendor\%bq_versionstring%\net-4.0
)

:: push environment
setlocal

:: announce intentions
echo.
echo Building version                 : %bq_versionstring%
echo Building for Studio/architecture : %bq_platform%
echo Using cmake                      : %cmakegen%
echo Using boost                      : %MY_BOOST%
echo Build directory                  : %bq_builddir%
echo Install directory                : %bq_installdir%
echo Proton is at                     : %bq_installdir%
echo Dotnet binding solution          : %bq_bindingSln%
echo Vendor directory                 : %bq_vendordir%
echo.

:: don't necessarily clobber existing build. Unattended build fresh every time
SET bq_reusebuild=
IF NOT "%A_UNATTENDED%"=="T" SET /P bq_reusebuild=Enter any nonblank nonsense to KEEP (not delete) and REUSE (not recompile) OLD build directory %bq_builddir%: 

:: Fresh build area
IF NOT "%bq_reusebuild%"=="" GOTO REUSE_BUILD
call :MakeNewDir %bq_builddir%
:REUSE_BUILD
::call :MakeNewDir %bq_installdir% Installation dir is shared with proton. Never clobber it.

:: New path in vendor area
mkdir %bq_vendordir%
mkdir %bq_vendordir%\debug
mkdir %bq_vendordir%\release

echo.
echo Ready to build.
IF NOT "%A_UNATTENDED%"=="T" echo Press Enter to continue, ^C to abort && pause


:: descend into build area
cd %bq_builddir%
echo Building in %CD%

set QPID_BUILD_ROOT=%CD%

:: run cmake
echo Running cmake...
cmake -G %cmakegen% -DCMAKE_INSTALL_PREFIX="%bq_installdir%" -DBOOST_ROOT="%MY_BOOST%" -DBUILD_DOCS="No" ..\cpp
                                        if %errorlevel% neq 0 exit /b %errorlevel%

:: build/install qpid
echo Compiling/installing qpid debug
devenv   qpid-cpp.sln /build "Debug|Win32"          /project INSTALL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
echo Compiling/installing qpid release
devenv   qpid-cpp.sln /build "RelWithDebInfo|Win32" /project INSTALL
                                        if %errorlevel% neq 0 exit /b %errorlevel%

:: Build the .NET Binding
echo Compiling .NET binding debug
devenv %bq_bindingSln% /build "Debug|Win32"          /project org.apache.qpid.messaging
                                        if %errorlevel% neq 0 exit /b %errorlevel%
echo Compiling .NET binding release
devenv %bq_bindingSln% /build "RelWithDebInfo|Win32" /project org.apache.qpid.messaging
                                        if %errorlevel% neq 0 exit /b %errorlevel%

:: ascend from build area
cd ..

:: Populate vendor files
echo Gathering files into vendor directory %bq_vendordir%
echo on

copy %bq_installdir%\bin\boost*.dll         %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_installdir%\bin\qpidclient*.dll    %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_installdir%\bin\qpidcommon*.dll    %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_installdir%\bin\qpidmessaging*.dll %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_installdir%\bin\qpidtypes*.dll     %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_installdir%\bin\qpid-proton*.dll   %bq_vendordir%\release
                                        if %errorlevel% neq 0 exit /b %errorlevel%

move %bq_vendordir%\release\*mt-gd*.dll %bq_vendordir%\debug
                                        if %errorlevel% neq 0 exit /b %errorlevel%
move %bq_vendordir%\release\*d.dll      %bq_vendordir%\debug
                                        if %errorlevel% neq 0 exit /b %errorlevel%

copy %bq_builddir%\src\Debug\org.apache.qpid.messaging.dll          %bq_vendordir%\debug\
                                        if %errorlevel% neq 0 exit /b %errorlevel%
copy %bq_builddir%\src\RelWithDebInfo\org.apache.qpid.messaging.dll %bq_vendordir%\release\
                                        if %errorlevel% neq 0 exit /b %errorlevel%

echo off

:: done
goto :eof

REM
REM MakeNewDir dirname
REM
:MakeNewDir
echo MakeNewDir: Start recreating %1. Delete %1
rmdir /s /q %1
echo MakeNewDir: Checking if %1 still exists
if exist %1\nul (echo "ERROR: %1 still exists. Type ^C to exit and fix %1" && pause && goto :eof)
echo MakeNewDir: Create %1
mkdir       %1
echo MakeNewDIr: Done  recreating %1
goto :eof
