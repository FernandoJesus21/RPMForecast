
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# tbats.R : Script que contiene la función para ejecutar modelos TBATS
################################################################################

ejecutarTBATS <- function(ts_data, df_data, cv = F, steps){
  
  library(dplyr)
  library(forecast)
  library(lubridate)
  library(log4r)
  
  tryCatch({
    
    # Función de validación cruzada con modelo fijo
    evaluate_tbats <- function(train, h) {
      model <- tbats(train)
      # Realiza el forecast
      forecast_values <- forecast(model, h = h)
      return(forecast_values)
    }
    
    #ajuste del modelo con el conjunto entrenamiento
    model_tbats <- tbats(ts_data) #modelo propuesto
    
    mae_per_step_tbats <- NULL
    rmse_per_step_tbats <- NULL
    if(cv){
      #valicacion cruzada del modelo propuesto
      cv_errors_tbats <- tsCV(ts_data, evaluate_tbats, h = 12)
      #lista de errores de la validacion cruzada
      rmse_per_step_tbats <- sqrt(colMeans(cv_errors_tbats^2, na.rm = TRUE))
      mae_per_step_tbats <- colMeans(abs(cv_errors_tbats), na.rm = TRUE)
    }
    
    #generar previsiones segun la cantidad de periodos especificada
    fcast_tbats <- forecast(model_tbats, h = steps)
    #DF que contendra los datos originales mas las previsiones
    data_tbats <- df_data
    #guardo la longitud actual del df
    lng_data <- nrow(df_data)
    #este bucle se encarga de agregar los nuevos registros a data_tbats correspondientes a los periodos predichos
    for (j in 1:steps) {
      data_tbats[lng_data+j,]$periodo <- data_tbats[lng_data+j-1,]$periodo + months(1)
      data_tbats[lng_data+j,]$serie <- data_tbats[lng_data+j-1,]$serie
      data_tbats[lng_data+j,]$valor <- fcast_tbats$mean[j]
      data_tbats[lng_data+j,]$es_prediccion <- "T"
    }
    #agrego etiqueta del modelo
    data_tbats$modelo <- "TBATS"
    info(logger, paste0("TBATS (", data_tbats$serie[1], ") OK"))
    
    resultados <- list(data_tbats, mae_per_step_tbats, rmse_per_step_tbats, model_tbats)
    return(resultados)
    
  },
  error = function(e){
    error(logger, paste0("[tbats.R] (", df_data$serie[1], ") ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[tbats.R] (", df_data$serie[1], ") WARNING: ", e))
  })
  
}