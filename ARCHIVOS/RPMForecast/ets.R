
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# ets.R : Script que contiene la función para ejecutar modelos de suavizado exponencial
################################################################################

ejecutarETS <- function(ts_data, df_data, cv = F, steps){
  
  library(dplyr)
  library(forecast)
  library(lubridate)
  library(log4r)
  
  tryCatch({
    
    # Función de validación cruzada con modelo fijo
    evaluate_ets <- function(train, h) {
      model <- ets(train)
      # Realiza el forecast
      forecast_values <- forecast(model, h = h)
      return(forecast_values)
    }
    
    
    #ajuste del modelo con el conjunto entrenamiento
    model_ets <- ets(ts_data) #modelo propuesto
    
    mae_per_step_ets <- NULL
    rmse_per_step_ets <- NULL
    if(cv){
      #valicacion cruzada del modelo propuesto
      cv_errors_ets <- tsCV(ts_data, evaluate_ets, h = 12)
      #lista de errores de la validacion cruzada
      rmse_per_step_ets <- sqrt(colMeans(cv_errors_ets^2, na.rm = TRUE))
      mae_per_step_ets <- colMeans(abs(cv_errors_ets), na.rm = TRUE)
    }
    
    #generar previsiones segun la cantidad de periodos especificada
    fcast_ets <- forecast(model_ets, h = steps)
    #DF que contendra los datos originales mas las previsiones
    data_ets <- df_data
    #guardo la longitud actual del df
    lng_data <- nrow(df_data)
    #este bucle se encarga de agregar los nuevos registros a data_ets correspondientes a los periodos predichos
    for (j in 1:steps) {
      data_ets[lng_data+j,]$periodo <- data_ets[lng_data+j-1,]$periodo + months(1)
      data_ets[lng_data+j,]$serie <- data_ets[lng_data+j-1,]$serie
      data_ets[lng_data+j,]$valor <- fcast_ets$mean[j]
      data_ets[lng_data+j,]$es_prediccion <- "T"
    }
    #agrego etiqueta del modelo
    data_ets$modelo <- "ETS"
    info(logger, paste0("ETS (", data_ets$serie[1], ") OK"))
    
    resultados <- list(data_ets, mae_per_step_ets, rmse_per_step_ets, model_ets)
    return(resultados)
    
  },
  error = function(e){
    error(logger, paste0("[ets.R] (", df_data$serie[1], ") ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[ets.R] (", df_data$serie[1], ") WARNING: ", e))
  })
  
}