
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# promedio.R : Script que contiene la función para calcular el promedio de las
#              predicciones de modelos habilitados
################################################################################

calcularPROMEDIO <- function(df){
  
  library(dplyr)
  library(log4r)
  
  tryCatch({
    
    #creación df auxiliar
    data_promedio <- df
    #se agrupa por periodo y serie, sumarizando la variable valor por la funcion mean
    # a partir de las predicciones.
    # a continuacion se agregan las columnas que se perdieron y se redondea el valor promedio
    data_promedio <- data_promedio %>%
      filter(es_prediccion == 'T') %>%
      group_by(periodo, serie) %>%
      summarise(valor = mean(valor), .groups = "drop") %>%
      mutate(es_prediccion = 'T') %>%
      mutate(modelo = 'PROMEDIO') %>%
      mutate(valor = round(valor, 2))
    
    #se obtienen las series originales, para cada una de las series ingresadas
    # a continuación se adapta su formato para hacerlo compatible con el df auxiliar
    # que contiene la media de las predicciones de los modelos.
    series_originales <- filter(df, es_prediccion == 'F') %>%
      group_by(periodo, serie) %>%
      summarise(valor = min(valor), .groups = "drop") %>%
      mutate(es_prediccion = 'F') %>%
      mutate(modelo = 'PROMEDIO')
    
    #se juntan ambos df, ordenandolos por serie y periodo
    data_promedio <- rbind(series_originales, data_promedio) %>%
      arrange(serie, periodo)

    info(logger, paste0("PROMEDIO... OK"))
    
    return(data_promedio)
    
  },
  error = function(e){
    error(logger, paste0("[promedio.R] ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[promedio.R] WARNING: ", e))
  })
  
  
}