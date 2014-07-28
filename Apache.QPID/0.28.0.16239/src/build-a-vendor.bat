goto :start

A set of procedures and scripts for creating an
"apache qpid vendor kit for NMS" from qpid 0.28/proton 0.7 sources. 

This procedure executes in the following directory/file setup:

   <drive:\dir\>
   |   build-a-vendor.bat
   |   a-build_proton.bat
   |   a-build_qpid.bat
   |   proton-0.7.patch
   |
   +---src-tar-gz-proton
   |       qpid-proton-0.7.tar.gz
   |       SHA1SUM.txt
   |
   \---src-tar-gz-qpid-cpp
           qpid-cpp-0.28.tar.gz
           SHA1SUM.txt

Step 1. Get sources.
The sources are contained in this kit but one may download the tar.gz files from
   http://archive.apache.org/dist/qpid/0.28/
   http://archive.apache.org/dist/qpid/proton/0.7/
Manually verify that the sha1sum for each download is correct.
Note: The SHA1SUM.txt files are not necessary for the build but are part of the
download verification.

Step 2. Execute the build.
> build-a-vendor.bat

Note: This procedure may stop at critical places for debug or manual version
overrides. SET A_UNATTENDED=T to do an unattended complete as-is build.

Note: The build system must have Visual Studio 2008, 2010, python, ruby, Boost, 7zip
and the usual utilities that Apache QPID and Apache QPID PROTON builds require.

Step 3. Delivery the output <drive:\dir\>qpid\vendor\ to Apache 
https://svn.apache.org/repos/asf/activemq/activemq-dotnet/vendor/QPid/Apache.QPID

:start

SET A_UNATTENDED=T
setlocal enabledelayedexpansion

::
:: Select src versions
::
SET   QPID_V=qpid-cpp-0.28
SET PROTON_V=qpid-proton-0.7

::
:: Remember top level directory
::
set BUILD_ROOT=%~dp0%
set BUILD_ROOT=%BUILD_ROOT:~0,-1%

::
:: Delete previous tar and build directories
::
del      /q *.tar
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rmdir /s /q qpid
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rmdir /s /q proton
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rmdir /s /q %qpid_v%
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rmdir /s /q %proton_v%
                                        if %errorlevel% neq 0 exit /b %errorlevel%

::
:: Unpack pristine sources with 7zip
:: Leave sources in unversioned \qpid and \proton folders
::
7z x src-tar-gz-qpid-cpp\%QPID_V%.tar.gz     > NUL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
7z x %QPID_V%.tar                        > NUL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rename %QPID_V% cpp                         
                                        if %errorlevel% neq 0 exit /b %errorlevel%
mkdir qpid
mv cpp qpid

7z x src-tar-gz-proton\%PROTON_V%.tar.gz > NUL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
7z x %PROTON_V%.tar                      > NUL
                                        if %errorlevel% neq 0 exit /b %errorlevel%
rename %PROTON_V% proton                      
                                        if %errorlevel% neq 0 exit /b %errorlevel%
del      /q *.tar
                                        if %errorlevel% neq 0 exit /b %errorlevel%

::
:: Patch the formerly pristene sources
:: Note: Proton requires a one-line patch to build under Visual Studio 2008
::
pushd proton
patch -p 1 < ..\proton-0.7.patch

::
:: Installs go to %BUILD_ROOT%\install_x86_2008.
:: Note: Proton and Qpid must share an install directory to enable AMQP 1.0
:: support in Qpid.
::
pushd proton
copy %BUILD_ROOT%\a-build_proton.bat .
call a-build_proton.bat
popd

pushd qpid
copy %BUILD_ROOT%\a-build_qpid.bat .
call a-build_qpid.bat
popd




