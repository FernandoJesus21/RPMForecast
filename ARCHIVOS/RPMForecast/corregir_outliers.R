
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.2
# Fecha 17/04/2025 
# Autor: Fernando J. Heredia
# corregir_outliers.R : Script que contiene una función que reemplaza valores atípicos.
#                       Se considera valor atípico numeros mayores a 1e20, menores a -1e20
#                       valores Inf o NA. Finalmente se redondean los valores que contienen decimales.
################################################################################

corregir_outliers <- function(data){
  
  library(log4r)
  
  tryCatch({
    
    #banderas, al comenzo estan todas en FALSE
    O_valor_extremadamente_pequenio <- F
    O_valor_extremadamente_grande <- F
    O_infinito <- F
    O_desconocido <- F
    
    #si se encuentran valores menores a -1e20, se cambia a TRUE la bandera correspondiente y se reemplaza el valor por -999999999999990
    if(min(data$valor, na.rm = T) < -1e20){
      O_valor_extremadamente_pequenio <- T
      data$valor[data$valor < -1e20] <- -999999999999990
    }
    #si se encuentran valores mayores a 1e20, se cambia a TRUE la bandera correspondiente y se reemplaza el valor por 999999999999990
    if(max(data$valor, na.rm = T) > 1e20){
      O_valor_extremadamente_grande <- T
      data$valor[data$valor > 1e20] <- 999999999999990
    }
    #si se encuentran valores Inf, se cambia a TRUE la bandera correspondiente y se reemplaza el valor por 999999999999999
    if(any(is.infinite(data$valor))){
      O_infinito <- T
      data$valor[is.infinite(data$valor)] <- 999999999999999
    }
    #si se encuentran valores NA, se cambia a TRUE la bandera correspondiente y se reemplaza el valor por 0
    if(any(is.na(data$valor))){
      O_infinito <- T
      data$valor[is.na(data$valor)] <- 0
    }
    #redondeo de valores con decimales (comentar esta línea si se desean predicciones con decimales)
    data$valor <- round(data$valor, 0)
    #Si ocurre que alguna de las banderas es TRUE, se informa por log que el resultado original ha sido modificado
    if(any(O_valor_extremadamente_pequenio, O_valor_extremadamente_grande, O_infinito)){
      warn(logger, "Se econtraron los siguientes valores atípicos:")
      warn(logger, paste0("\tValores menores a -1e20: ", O_valor_extremadamente_pequenio, ". Si existe se reemplaza por -999999999999990"))
      warn(logger, paste0("\tValores mayores a 1e20: ", O_valor_extremadamente_grande, ". Si existe se reemplaza por 999999999999990"))
      warn(logger, paste0("\tValores 'Inf': ", O_infinito, ". Si existe se reemplaza por 999999999999999"))
      warn(logger, paste0("\tValores 'NA': ", O_desconocido, ". Si existe se reemplaza por 0"))
      warn(logger, "Se reemplazaron estos valores para evitar errores.")
    }else{
      info(logger, "No se encontraron valores atípicos en la columna 'valor'")
    }
    
    return(data)
    
  },
  error = function(e){
    error(logger, paste0("[corregir_outliers.R] ERROR: ", e))
    stop("Subproceso truncado. No se puede continuar.\n")
  },
  warning = function(e){
    warn(logger, paste0("[corregir_outliers.R] WARNING: ", e))
  })
  

}














