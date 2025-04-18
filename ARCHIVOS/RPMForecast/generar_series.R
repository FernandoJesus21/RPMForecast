
################################################################################
# Marco de trabajo para previsiones múltiples - RPMForecast
# Versión 3.1
# Fecha 18/12/2024 
# Fernando Heredia
# generar_series.R : Script que permite la generación de series de prueba.
################################################################################

set.seed(123)
library(lubridate)
library(dplyr)

#cantidad de series a generar
cantidad_series <- 10
#lista que contendrá las series
series <- list()
#generación de series.
for (i in 1:cantidad_series) {
  aux <- data.frame(periodo = seq(ymd("2010-01-01"), ymd("2024-12-01"), by = "months")) %>%
    mutate(periodo = paste0(year(periodo), ifelse(nchar(month(periodo)) < 2, paste0("0", month(periodo)), month(periodo)))) %>%
    mutate(serie = paste0("AR", i)) %>%
    mutate(valor = as.data.frame( ts(arima.sim(n = 180, model = list(order = c(1, 1, 1), ar = 0.5, ma = -0.5)), frequency = 12))[2:181,])
  series[[i]] <- aux
}
#colapso de la lista para generar un único df
series <- bind_rows(series)
#exportar df
write.csv(series, "series.csv", fileEncoding = "UTF-8", row.names = F)














