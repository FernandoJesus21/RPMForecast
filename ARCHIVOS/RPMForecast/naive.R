
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# naive.R : Script que contiene la función para ejecutar modelos NAIVE
################################################################################

ejecutarNAIVE <- function(ts_data, df_data, cv = F, steps){
  
  library(dplyr)
  library(forecast)
  library(lubridate)
  library(log4r)
  
  tryCatch({
    
    # Función de validación cruzada con modelo fijo
    evaluate_naive <- function(train, h) {
      # Realiza el forecast
      forecast_values <- naive(train, h = h)
      return(forecast_values)
    }
    
    
    mae_per_step_naive <- NULL
    rmse_per_step_naive <- NULL
    if(cv){
      #valicacion cruzada del modelo propuesto
      cv_errors_naive <- tsCV(ts_data, evaluate_naive, h = 12)
      #lista de errores de la validacion cruzada
      rmse_per_step_naive <- sqrt(colMeans(cv_errors_naive^2, na.rm = TRUE))
      mae_per_step_naive <- colMeans(abs(cv_errors_naive), na.rm = TRUE)
    }
    
    #generar previsiones segun la cantidad de periodos especificada
    fcast_naive <- naive(ts_data, h = steps)
    #DF que contendra los datos originales mas las previsiones
    data_naive <- df_data
    #guardo la longitud actual del df
    lng_data <- nrow(df_data)
    #este bucle se encarga de agregar los nuevos registros a data_naive correspondientes a los periodos predichos
    for (j in 1:steps) {
      data_naive[lng_data+j,]$periodo <- data_naive[lng_data+j-1,]$periodo + months(1)
      data_naive[lng_data+j,]$serie <- data_naive[lng_data+j-1,]$serie
      data_naive[lng_data+j,]$valor <- fcast_naive$mean[j]
      data_naive[lng_data+j,]$es_prediccion <- "T"
    }
    #agrego etiqueta del modelo
    data_naive$modelo <- "NAIVE"
    info(logger, paste0("NAIVE (", data_naive$serie[1], ") OK"))
    
    resultados <- list(data_naive, mae_per_step_naive, rmse_per_step_naive, fcast_naive)
    return(resultados)
  },
  error = function(e){
    error(logger, paste0("[naive.R] (", df_data$serie[1], ") ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[naive.R] (", df_data$serie[1], ") WARNING: ", e))
  })
  
  
}




