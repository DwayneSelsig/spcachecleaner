:: Get existing Powershell ExecutionPolicy
FOR /F "tokens=*" %%x in ('"%SYSTEMROOT%\system32\windowspowershell\v1.0\powershell.exe" Get-ExecutionPolicy') do (set ExecutionPolicy=%%x)
:: Set Bypass, in case we are running over a net share or UNC
IF NOT "%ExecutionPolicy%"=="Bypass" IF NOT "%ExecutionPolicy%"=="Unrestricted" (
    SET RestoreExecutionPolicy=1
%SYSTEMROOT%\system32\windowspowershell\v1.0\powershell.exe -Command Start-Process "$PSHOME\powershell.exe" -Verb RunAs -ArgumentList "'-Command Set-ExecutionPolicy Bypass'"
	)

%SYSTEMROOT%\system32\windowspowershell\v1.0\powershell.exe -file %~dp0SPCacheCleaner.ps1 %1

IF "%RestoreExecutionPolicy%"=="1" (
%SYSTEMROOT%\system32\windowspowershell\v1.0\powershell.exe -Command Start-Process "$PSHOME\powershell.exe" -Verb RunAs -ArgumentList "'-Command Set-ExecutionPolicy RemoteSigned'"
    )
exit