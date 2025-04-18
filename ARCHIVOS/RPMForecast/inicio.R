
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# inicio.R : Script principal que se ejecuta desde Pentaho PDI. Este script llama
#            a todos los demás a lo largo de la ejecución del proceso.
################################################################################

#carga de bibliotecas
library(rmarkdown)
library(dplyr)
library(forecast)
library(xts)
library(data.table)
library(lubridate)
library(flexdashboard)
library(readr)
library(doParallel)
library(log4r)

#evitar notación exponencial
options(scipen = 20)

#tiempo de inicio
inicio0 <- Sys.time()
#parametro de configuracion para evitar error de version de pandoc en pentaho
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")

#recuperacion del argumento recibido desde la llamada del script
args <- commandArgs(trailingOnly = TRUE)
#establecimiento del directorio de trabajo
setwd(args[1])
#directorio de trabajo (para pruebas desde el script)
#setwd("C:/path")

# Crear un logger
logger <- create.logger()
logfile(logger) <- paste("log/RPMForecast_", gsub("[:| |-]", "_", inicio0), ".txt", sep = "")
level(logger) <- "INFO"

#LECTURA DE PARAMETROS
#archivo de configuracion
config <- read_csv("config.csv", col_types = cols(valor = col_character()))
#parametros de configuracion
MODELO_NAIVE <- as.logical(filter(config, param == "MODELO_NAIVE")$valor)
MODELO_ARIMA <- as.logical(filter(config, param == "MODELO_ARIMA")$valor)
MODELO_ARIMA_BOX_COX <- as.logical(filter(config, param == "MODELO_ARIMA_BOX_COX")$valor)
MODELO_ETS <- as.logical(filter(config, param == "MODELO_ETS")$valor)
MODELO_TBATS <- as.logical(filter(config, param == "MODELO_TBATS")$valor)
MODELO_THETA <- as.logical(filter(config, param == "MODELO_THETA")$valor)
PROMEDIO <- as.logical(filter(config, param == "PROMEDIO")$valor)
PERIODOS_A_PREDECIR <- as.numeric(filter(config, param == "PERIODOS_A_PREDECIR")$valor)
USAR_CV <- as.logical(filter(config, param == "USAR_CV")$valor)
PROCESADORES <- as.numeric(filter(config, param == "PROCESADORES")$valor)
cl <- makeCluster(PROCESADORES)
registerDoParallel(cl)
#ejecucion de los script auxiliares para acceder a las funciones de los modelos
source("naive.R")
source("arima.R")
source("arima_box_cox.R")
source("ets.R")
source("tbats.R")
source("theta.R")
source("promedio.R")
source("corregir_outliers.R")
source("validar_series.R")

info(logger, "Lectura de archivos de entrada")

#LECTURA DE ARCHIVO RINPUT
r_input_g <- read_delim(paste("entrada/", "r_input.csv", sep = ""), delim = ",", 
                        escape_double = FALSE, col_types = cols(periodo = col_character(), 
                                                                serie = col_character(), 
                                                                es_prediccion = col_character()), 
                        locale = locale(), trim_ws = TRUE)

#################################################################
#Operacion de validacion para series temporales
#se filtran series que no sean contiguas o que tengan menos de 36 periodos
res <- validar_series(r_input_g)

write.csv(res[[1]], "entrada/r_input_val.csv", row.names = F, fileEncoding = "UTF-8", quote = F)
write.csv(res[[2]], "entrada/val_resultados.csv", row.names = F, fileEncoding = "UTF-8", quote = F)
#################################################################

#LECTURA DE ARCHIVO RINPUT VALIDADO
r_input_g <- read_delim(paste("entrada/", "r_input_val.csv", sep = ""), delim = ",", 
                        escape_double = FALSE, col_types = cols(periodo = col_character(), 
                                                                serie = col_character(), 
                                                                es_prediccion = col_character()), 
                        locale = locale(), trim_ws = TRUE)

#convierto r_input_g a formato lista
ts_pool <- split(r_input_g, r_input_g$serie)

###########################################
info(logger, "----------------------------CONFIGURACIÓN-----------------------------")
info(logger, paste("Ubicación:", getwd()))
info(logger, paste("Versión de R:", R.version$version.string))
info(logger, paste("Cantidad de procesadores:", PROCESADORES))
info(logger, paste0("Cantidad de series: ", length(ts_pool)))
info(logger, paste0("Habilitar bondad/validación cruzada: ", USAR_CV))
info(logger, paste0("Periodos a predecir: ", PERIODOS_A_PREDECIR))
info(logger, "Algoritmos:")
info(logger, paste0("\tNAIVE:", MODELO_NAIVE))
info(logger, paste0("\tARIMA:", MODELO_ARIMA))
info(logger, paste0("\tARIMA (BOX-COX):", MODELO_ARIMA_BOX_COX))
info(logger, paste0("\tETS:", MODELO_ETS))
info(logger, paste0("\tTBATS:", MODELO_TBATS))
info(logger, paste0("\tTHETA:", MODELO_THETA))
info(logger, paste0("\tPROMEDIO:", PROMEDIO))
info(logger, "----------------------------------------------------------------------")
info(logger, "Inicio de ejecución de modelos.")

#funcion principal, lee los parametros de configuracion y ejecuta los modelos especificados
procesarSerie <- function(tsdf){

  library(dplyr)
  library(forecast)
  library(lubridate)
  library(flexdashboard)
  library(rmarkdown)
  
  tryCatch({

    #aplico formato de fechas
    data <- tsdf %>%
      mutate(periodo = as.Date(paste0(substr(periodo,1, 4), "-", substr(periodo,5, 6), "-01")))
    
    #se obtiene el año y mes de inicio
    a_o <- year(min(data$periodo))
    mes <- month(min(data$periodo))
    
    #convertir el df a serie ts
    ts_data <- ts(data$valor, frequency = 12, start = c(a_o, mes))
    
    #aux: data frame vacio que se va a ir poblando a medida que se reciban los resultados de las predicciones de los modelos
    aux <- data.frame(periodo = NULL,
                      serie = NULL,
                      valor = NULL,
                      es_prediccion = NULL,
                      modelo = NULL)
    
    #conjunto de condiciones que evaluan los parametros configurados y ejecutan los modelos segun corresponda
    if(any(MODELO_NAIVE, MODELO_ARIMA, MODELO_ARIMA_BOX_COX, MODELO_ETS, MODELO_TBATS, MODELO_THETA) == F){
      stop("SIN MODELOS CONFIGURADOS")
    }else{
      
      if(MODELO_NAIVE){
        res_naive <- ejecutarNAIVE(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_naive[[1]])
      }
      
      if(MODELO_ARIMA){
        res_arima <- ejecutarARIMA(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_arima[[1]])
      }
      
      if(MODELO_ARIMA_BOX_COX){
        res_arima_box_cox <- ejecutarARIMA_BOX_COX(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_arima_box_cox[[1]])
      }
      
      if(MODELO_ETS){
        res_ets <- ejecutarETS(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_ets[[1]])
      }
      
      if(MODELO_TBATS){
        res_tbats <- ejecutarTBATS(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_tbats[[1]])
      }
      
      if(MODELO_THETA){
        res_theta <- ejecutarTHETA(ts_data = ts_data, df_data = data, cv = USAR_CV, steps = PERIODOS_A_PREDECIR)
        aux <- rbind(aux, res_theta[[1]])
      }
      
    }
    
    ############################################################################################
    #Creacion del reporte de bondad en formato html 
    
    if(USAR_CV){
      
      # Crear un archivo temporal en el directorio de trabajo
      temp_rmd <- file.path(paste0(tsdf$serie[1], "_report.Rmd"))
      
      # Leer la plantilla y reemplazar las variables dinámicas
      template <- readLines("report.Rmd")
      
      # Escribir el contenido modificado a un archivo en el directorio de trabajo
      writeLines(template, con = temp_rmd)
      
      # Generar el reporte para esta iteración
      message("Generando reporte")
      output_file <- file.path(paste0("salida/", tsdf$serie[1], "_report.html"))
      render(temp_rmd, output_format = "flexdashboard::flex_dashboard", output_file = output_file)
      
      # Opción de eliminar el archivo .Rmd después de generar el reporte
      unlink(temp_rmd)
      
    }
    ############################################################################################
    
    list(
      aux
    )
    
  },
  error = function(e){
    error(logger, paste0("[inicio.R] ERROR: ", e))
    #stop("Proceso truncado. No se puede continuar.\n") #comentar para hacer que el proceso entero falle al primer error
  },
  warning = function(e){
    warn(logger, paste0("[inicio.R] WARNING: ", e))
  })
}

#ejecucion de la funcion principal, guarda el resultado en r_output
r_output <- foreach(serie = ts_pool, .packages = "forecast") %dopar% {
  procesarSerie(serie)
}

#junto todos los df de la lista en un unico df
r_output <- bind_rows(r_output)

###################################################################################
#corregir posibles valores atipicos

r_output <- corregir_outliers(r_output)

###################################################################################
#calculo del modelo promedio

if(PROMEDIO){
  info(logger, "Se seleccionó la opción de calcular el modelo promedio.")
  info(logger, "Generando promedio de las predicciones de los otros modelos...")
  res_promedio <- calcularPROMEDIO(r_output)
  r_output <- rbind(r_output, res_promedio)
}

info(logger, "Fin de ejecución de modelos.")


#vuelvo a cambiar el formato de las fechas
r_output$periodo <- paste0(year(r_output$periodo), ifelse(month(r_output$periodo)>9, month(r_output$periodo), paste0("0", month(r_output$periodo))))


###################################################################################

#exporto el df
write.csv(r_output, "salida/output.csv", row.names = F, fileEncoding = "UTF-8")
info(logger, paste0("Exportado 'salida/output.csv'"))

#tienpo de fin de ejecucion
fin0 <- Sys.time()
#calculo de la diferencia del tiempo
diferencia <- as.numeric(difftime(fin0, inicio0, units = "secs"))

# Convertir la diferencia a un formato legible
horas <- floor(diferencia / 3600)
minutos <- floor((diferencia %% 3600) / 60)
segundos <- round(diferencia %% 60, 2)  # Con dos decimales si es necesario

# Formatear como una cadena
tiempo_formateado <- sprintf("Finalizado en: %02d horas, %02d minutos y %.2f segundos", horas, minutos, segundos)


info(logger, tiempo_formateado)




