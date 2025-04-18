
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# arima_box_cox.R : Script que contiene la función para ejecutar modelos ARIMA con transformación
#         de box cox
################################################################################

ejecutarARIMA_BOX_COX <- function(ts_data, df_data, cv = F, steps){
  
  library(dplyr)
  library(forecast)
  library(lubridate)
  library(log4r)
  
  tryCatch({

    # Función de validación cruzada con modelo fijo
    evaluate_arima <- function(train, h) {
      model <- auto.arima(train, max.p = 4, max.q = 4, lambda = "auto")
      # Realiza el forecast
      forecast_values <- forecast(model, h = h)
      return(forecast_values)
    }
    
    #ajuste del modelo con el conjunto entrenamiento
    model_arima <- auto.arima(ts_data, max.p = 4, max.q = 4, lambda = "auto") #modelo propuesto
    
    
    mae_per_step_arima <- NULL
    rmse_per_step_arima <- NULL
    if(cv){
      #valicacion cruzada del modelo propuesto
      cv_errors_arima <- tsCV(ts_data, evaluate_arima, h = 12)
      #lista de errores de la validacion cruzada
      rmse_per_step_arima <- sqrt(colMeans(cv_errors_arima^2, na.rm = TRUE)) 
      mae_per_step_arima <- colMeans(abs(cv_errors_arima), na.rm = TRUE)
    }
    
    #generar previsiones segun la cantidad de periodos especificada
    fcast_arima <- forecast(model_arima, h = steps)
    #DF que contendra los datos originales mas las previsiones
    data_arima <- df_data
    #guardo la longitud actual del df
    lng_data <- nrow(df_data)
    #este bucle se encarga de agregar los nuevos registros a data_arima correspondientes a los periodos predichos
    for (j in 1:steps) {
      data_arima[lng_data+j,]$periodo <- data_arima[lng_data+j-1,]$periodo + months(1)
      data_arima[lng_data+j,]$serie <- data_arima[lng_data+j-1,]$serie
      data_arima[lng_data+j,]$valor <- fcast_arima$mean[j]
      data_arima[lng_data+j,]$es_prediccion <- "T"
    }
    #agrego etiqueta del modelo
    data_arima$modelo <- "ARIMA (BOX-COX)"
    info(logger, paste0("ARIMA (BOX-COX) (", data_arima$serie[1], ") OK"))
    
    resultados <- list(data_arima, mae_per_step_arima, rmse_per_step_arima, model_arima)
    return(resultados)
  },
  error = function(e){
    error(logger, paste0("[arima_box_cox.R] (", df_data$serie[1], ") ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[arima_box_cox.R] (", df_data$serie[1], ") WARNING: ", e))
  })
  
  
}