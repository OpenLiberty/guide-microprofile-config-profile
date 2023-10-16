setlocal

if "%~1"=="" (
    echo Usage: deployApp.bat ^<username^> ^<password^>
    exit /b 1
)

set USERNAME=%~1
set PASSWORD=%~2

call mvn -pl system ^
         -ntp clean package liberty:create liberty:install-feature liberty:deploy

call mvn -pl query ^
         -ntp clean package liberty:create liberty:install-feature liberty:deploy

call mvn -pl system ^
         -ntp -P prod ^
         -Dliberty.var.default.username="%USERNAME%" ^
         -Dliberty.var.default.password="%PASSWORD%" ^
         liberty:start

call mvn -pl query ^
         -ntp -Dliberty.var.mp.config.profile="prod" ^
         -Dliberty.var.system.user="%USERNAME%" ^
         -Dliberty.var.system.password="%PASSWORD%" ^
         liberty:start
