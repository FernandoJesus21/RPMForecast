
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# naive.R : Script que contiene la función para ejecutar modelos NAIVE
################################################################################

validar_series <- function(df){
  
  library(readr)
  library(data.table)
  library(dplyr)
  library(lubridate)
  
  #crear variable fecha
  df$date <- as.Date(paste0(substr(df$periodo, 1, 4), "-", substr(df$periodo, 5, 6), "-01"))
  #contabilizar la cantidad de periodos mensuales
  test <- df %>% group_by(serie) %>%
    summarise(cant_periodos = n(),
              min_date = min(date),
              max_date = max(date))
  #contabilizar los meses necesario que una serie debe tener para ser contigua (basadas en su periodo minimo y maximo)
  test$meses_necesarios <- (12 * (year(test$max_date) - year(test$min_date)) + (month(test$max_date) - month(test$min_date))) + 1
  #validar si tiene 36 o mas periodos
  test$tiene_36_o_mas_periodos <- ifelse(test$cant_periodos > 35, T, F)
  #validar si es contigua
  test$es_contigua <- ifelse((test$meses_necesarios - test$cant_periodos) > 0, F, T)
  #validar si cumple ambos requerimientos
  test$cumple_req <- ifelse(test$tiene_36_o_mas_periodos & test$es_contigua, T, F)
  #filtrar series que pasaron la validacion
  test_OK <- filter(test, test$cumple_req)
  #contabilizar series que pasaron la validacion
  print(paste0("Series que pasaron la validación: ", nrow(test_OK), "/", nrow(test)))
  #armado del df a devolver
  df_ok <- filter(df, df$serie %in% test_OK$serie)
  df_ok <- select(df_ok, -c(date))
  #devolver el df con las series validadas correctamente y los resultados de la validación
  res <- list(df_ok, test)
  return(res)
  
}



