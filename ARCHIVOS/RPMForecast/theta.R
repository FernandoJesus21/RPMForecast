
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# theta.R : Script que contiene la función para ejecutar modelos THETA
################################################################################

ejecutarTHETA <- function(ts_data, df_data, cv = F, steps){
  
  library(dplyr)
  library(forecast)
  library(lubridate)
  library(log4r)
  
  tryCatch({
    
    # Función de validación cruzada con modelo fijo
    evaluate_theta <- function(train, h) {
      model <- thetaf(train)
      # Realiza el forecast
      forecast_values <- forecast(model, h = h)
      return(forecast_values)
    }
    
    #ajuste del modelo con el conjunto entrenamiento
    model_theta <- thetaf(ts_data) #modelo propuesto
    
    mae_per_step_theta <- NULL
    rmse_per_step_theta <- NULL
    if(cv){
      #valicacion cruzada del modelo propuesto
      cv_errors_theta <- tsCV(ts_data, evaluate_theta, h = 12)
      #lista de errores de la validacion cruzada
      rmse_per_step_theta <- sqrt(colMeans(cv_errors_theta^2, na.rm = TRUE))
      mae_per_step_theta <- colMeans(abs(cv_errors_theta), na.rm = TRUE)
    }
    
    #generar previsiones segun la cantidad de periodos especificada
    fcast_theta <- forecast(model_theta, h = steps)
    #DF que contendra los datos originales mas las previsiones
    data_theta <- df_data
    #guardo la longitud actual del df
    lng_data <- nrow(df_data)
    #este bucle se encarga de agregar los nuevos registros a data_theta correspondientes a los periodos predichos
    for (j in 1:steps) {
      data_theta[lng_data+j,]$periodo <- data_theta[lng_data+j-1,]$periodo + months(1)
      data_theta[lng_data+j,]$serie <- data_theta[lng_data+j-1,]$serie
      data_theta[lng_data+j,]$valor <- fcast_theta$mean[j]
      data_theta[lng_data+j,]$es_prediccion <- "T"
    }
    #agrego etiqueta del modelo
    data_theta$modelo <- "THETA"
    info(logger, paste0("THETA (", data_theta$serie[1], ") OK"))
    
    resultados <- list(data_theta, mae_per_step_theta, rmse_per_step_theta, model_theta)
    return(resultados)
  },
  error = function(e){
    error(logger, paste0("[theta.R] (", df_data$serie[1], ") ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[theta.R] (", df_data$serie[1], ") WARNING: ", e))
  })
  
  
}