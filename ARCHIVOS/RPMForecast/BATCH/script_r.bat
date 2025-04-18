@echo off

::variable con el nombre del ejecutable
set RSCRIPT="Rscript.exe"

::variable con la ubicacion del script de R
set RSCRIPT_FILE="%DIRECTORIO_TRABAJO%\inicio.R"

::llamada del script utilizando las variables, se pasa el argumento %DIRECTORIO_TRABAJO% al script de R.
%RSCRIPT% --verbose %RSCRIPT_FILE% %DIRECTORIO_TRABAJO%

::salir
exit
