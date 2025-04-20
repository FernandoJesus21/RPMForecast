# Multi previsión de series temporales en R y Pentaho (RPMForecast)
Un proyecto para facilitar la previsión de múltiples series temporales con múltiples modelos estadísticos.

Probado bajo entornos Windows con R 4.4.1, Pentaho PDI 10.2 y PostgreSQL 16.

# Objetivos
Este proyecto tiene por objetivo facilitar la creación y reporte de previsiones de múltiples series temporales a partir de múltiples modelos estadísticos, a la vez de facilitar herramientas al analista para identificar que tan bien resulta el ajuste de cada modelo para cada serie temporal.

![alt text](https://github.com/FernandoJesus21/RPMForecast/blob/main/app_01.png?raw=true)

# Tech stack
1) PostgreSQL
2) Pentaho PDI
3) R
4) PowerBI

El proyecto utiliza Pentaho Data Integration (PDI), en su versión community para la extracción de datos a partir de una base de datos PostgreSQL previamente definida, a su vez tiene la opción de incorporar conjuntos de datos de series temporales con formato .CSV. 

Todos los datos recuperados por el proceso de Pentaho serán transformados y enviados como entrada a un script de R que se encargará del ajuste de modelos, la elaboración de las predicciones y el exportado del archivo de salida para que Pentaho realice el guardado en una tabla de la base de datos. 

Finalmente, el tablero realizado en PowerBI accederá a la tabla con los resultados del proceso y se mostrarán los valores reales y las predicciones realizadas en un formato cómodo para su análisis.

![alt text](https://github.com/FernandoJesus21/RPMForecast/blob/main/app_02.png?raw=true)

# Parámetros
Existen parámetros que pueden ser configurados por el usuario a través del archivo kettle.properties. Estos parámetros serán guardados en el archivo /ARCHIVOS/RPMForecast/config.csv para su uso en el script de R.

1) DIRECTORIO_TRABAJO: Establece la ubicación absoluta de la carpeta ‘ARCHIVOS’ del proyecto.
2) PERIODOS_A_PREDECIR: Define cuantos periodos en el futuro se desea que predigan los modelos.
3) MODELO_NAIVE: Habilita el uso de modelos NAIVE en el proceso.
4) MODELO_ARIMA: Habilita el uso de modelos ARIMA en el proceso.
5) MODELO_ETS: Habilita el uso de modelos ETS en el proceso.
6) MODELO_TBATS: Habilita el uso de modelos TBATS en el proceso.
7) MODELO_THETA: Habilita el uso de modelos THETA en el proceso.

# Instrucciones
- Descomprimir la carpeta del proyecto en el lugar deseado, a continuación, modificar el parámetro DIRECTORIO_TRABAJO del archivo kettle.properties para que coincida con la ubicación de la subcarpeta 'ARCHIVOS'.
- Crear una base de datos PostgreSQL nombrada 'tseries' con las tablas ‘indicadores’ y ‘previsiones’, como se establece en el script sql ‘tablas’ ubicado en ARCHIVOS/RPMForecast/sql.
- Crear las carpetas ARCHIVOS/RPMForecast/log y ARCHIVOS/RPMForecast/salida

Si se desea añadir archivos en formato .CSV para que sean cargados*:
1) Deben ser archivos separados por coma ','. 
2) Separadores decimales deben ser con punto '.'.
3) Sin separador de miles.
4) Nombre de columnas: periodo (formato YYYYMM), serie (texto con el nombre de la serie) y valor.
5) Nombre de archivo: prefijo 'SERIE_', de lo contrario no será leído por el proceso.
6) Ubicación: ARCHIVOS/RPMForecast/entrada/series/

- PostgreSQL: añadir las series temporales deseadas a la tabla *indicadores* respetando el mismo formato que de los archivos .CSV. El proceso leerá los datos de esta tabla y los juntará con los provenientes de los archivos .CSV si los hubiera. Asegurarse no cargar la misma serie desde la BD y desde CSV.

*se incluyen series temporales de ejemplo con datos económicos provistos por el IDECBA.

# Requisitos de las series
1) Deben ser de formato mensual (no se ha probado series con otros formatos).
2) Deben ser contiguas, es decir, que no debe haber ningún periodo intermedio faltante.
3) Deben tener al menos 36 períodos.

# Precondiciones
Se requiere:
1) La definición de la variable de entorno para que R pueda ser ejecutado desde un proceso BATCH. 
2) JAVA JDK para el funcionamiento de Pentaho PDI. 
3) Ubicar el archivo kettle.properties en la ruta por defecto establecida según la documentación de Pentaho PDI.
4) Instalar las bibliotecas requeridas por el script de R: rmarkdown, dplyr, forecast, data.table, lubridate, flexdashboard, log4r y readr.

# Características
1) Soporte para cinco modelos: NAIVE, ARIMA, Suavizado exponencial (ETS), Exponential smoothing state space model with Box-Cox transformation, ARMA errors, Trend and Seasonal components (TBATS) y THETA.
2) Soporte para validación cruzada de series temporales (tsCV).
3) Enfoque de modelo variable: el modelo se construye mediante las funciones automatizadas auto.arima(), ets(), tbats() y thetaf() sobre el 100% de los datos de las series temporales. La función de validación cruzada reconstruye el modelo cambiando sus parámetros de modo que este se ajuste lo mejor posible en cada iteración.
4) Generación de reportes de bondad: para cada serie temporal se genera un archivo de reporte con información acerca de la bondad de ajuste de los modelos. Esta información es útil para el analista de manera que pueda evaluar la efectividad y robustez de dichos modelos.

# Funcionamiento
1) Una vez ejecutado el proceso procede a la recuperación de datos tanto desde la BD como de los CSV, generando columnas adicionales necesarias para la etapa de ejecución del script. Se generará entonces una salida intermedia llamada 'entrada/r_input.CSV'.
2) Posteriormente, 'entrada/r_input.CSV' será leido por el script y validado, generando salidas intermedias como 'entrada/r_input_val.CSV' y 'entrada/val_resultados.CSV'. El script continuará con 'entrada/r_input_val.CSV' que contendrá las series que cumplen los requisitos y aplicando los modelos elegidos. Se puede consultar el archivo 'entrada/val_resultados.CSV' para ver cuál requisito no cumplió cada una de las series que fueron desestimadas.
3) Una vez finalizado el script de R satisfactoriamente se habrá generado el archivo 'salida/output.CSV', que será el archivo utilizado por el proceso para poblar la tabla *previsiones*.
4) Ya se podrá recargar el archivo app.PBIX en este punto, debido a que tiene una conexión con la tabla *previsiones*. Si se cambiaron las credenciales de acceso a la BD, recordar actualizar dichas credenciales en el archivo .PBIX.

NOTA: Es normal que el logging del panel de Pentaho identifique la carga de paquetes de R cuando se ejecuta el script como error. Esto no indica que el proceso haya fallado. Ante sospecha de error revisar los logs que son generados en un archivo .TXT por el script de R ubicados en ARCHIVOS/RPMForecast/log/.

# Enfoque de CV
1) El enfoque de validación cruzada evalúa el desempeño de la técnica en general y no un modelo específico.
2) Adecuado si se desea comprobar que tan efectiva es cada técnica o algoritmo de previsión en el ajuste.
3) Permite el soporte e inclusión de técnicas de modelado más sofisticadas, ya que no es necesario buscar y extraer todos los parámetros de cada modelo.

# Limitaciones
1) Se cambia el enfoque de evaluación: se evalúa la efectividad de la técnica de modelado en general y no de un modelo en particular.
2) El modelo va a variar siempre en cada periodo, por lo que no tiene sentido identificar los parámetros.
3) Se debe disponer de al menos una serie temporal y un modelo habilitado en el archivo kettle.properties para que el proceso funcione correctamente.

# Documentación
Se puede encontrar documentación complementaria [aquí](https://drive.google.com/file/d/1iVOvdX_cUkNpf0wRh-vUDJ1v-7FAxZbf/view?usp=sharing).


