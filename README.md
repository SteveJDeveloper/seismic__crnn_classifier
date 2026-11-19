# Clasificación de eventos sísmicos volcánicos con una CRNN

Proyecto de tesis en el que se clasifican eventos sísmicos de origen volcánico en cuatro tipos usando una red neuronal convolucional-recurrente (CRNN) entrenada sobre espectrogramas.

- **Autor:** Steve Jimbo
- **Tutor:** Felipe Grijalva

---

## Objetivo

Clasificar automáticamente cada evento sísmico en una de estas cuatro clases:

| Etiqueta | Clase | Significado |
|---|---|---|
| 0 | HB | Híbrido (*Hybrid*) |
| 1 | VLP | Muy largo período (*Very Long Period*) |
| 2 | VT | Volcano-tectónico (*Volcano Tectonic*) |
| 3 | LP | Largo período (*Long Period*) |

En trabajos previos se probó *transfer learning* con Wav2Vec2 (modelo preentrenado en voz humana). Este proyecto propone un enfoque distinto: una CRNN entrenada de principio a fin sobre señales sísmicas.

## Datos

Eventos sísmicos etiquetados manualmente, en archivos separados por clase. 

| Clase | Eventos |
|---|---|
| HB | 170 |
| VLP | 181 |
| VT | 2802 |
| LP | 4121 |
| **Total** | **7274** |

El conjunto está **muy desbalanceado**: LP y VT concentran la gran mayoría de los eventos, mientras que HB y VLP son pocos. Esto condiciona todo el diseño del entrenamiento y de la evaluación.

> La carpeta `data/` **no se incluye** en el repositorio. Para ejecutar el proyecto hay que colocar los archivos originales en `data/raw/`. 

## Estructura del repositorio

```
proyecto/
├── README.md
├── data/                  # No versionada
│   ├── raw/               # Archivos originales (.mat)
│   ├── interim/           # Archivos convertidos a JSON
│   └── processed/         # CSV listos para el modelo (uno por clase)
├── src/
│   └── 01_mat_to_json.m   # Script de MATLAB: .mat → .json
├── notebooks/
│   ├── 02_filter_data.ipynb        # Filtrado: .json → .csv
│   └── 03_CRNN-CLASSIFIER.ipynb    # Preprocesamiento, modelo, entrenamiento y evaluación
├── models/                # Checkpoints del modelo (no versionada)
└── logs/                  # Registros de entrenamiento (no versionada)
```

## Flujo de trabajo

```
.mat  ──►  .json  ──►  .csv  ──►  espectrogramas  ──►  CRNN  ──►  evaluación
 (1)        (1)        (2)             (3)              (3)          (3)
```

### 1. Conversión de los datos originales — `src/01_mat_to_json.m`

Script de MATLAB que toma un archivo `.mat` de `data/raw/` y lo guarda como `.json` en `data/interim/`. Hay que indicar el nombre del archivo al inicio del script.

### 2. Filtrado y limpieza — `notebooks/02_filter_data.ipynb`

Lee el JSON evento por evento y genera un CSV por clase en `data/processed/` con las columnas `Event`, `Coda`, `Type` y `Data` (la señal). En el proceso:

- se conservan solo los eventos con detección **confirmada** (`Voting_Detection == "Confirmed"`);
- se extrae la señal del canal **BHZ**;
- se descartan los eventos sin señal o con valores no válidos (vacíos o no numéricos).

### 3. Clasificación — `notebooks/03_CRNN-CLASSIFIER.ipynb`

Este notebook reúne todo el trabajo de modelado en dos partes.

#### Parte A: primer modelo (base)

1. **Exploración:** carga de los seis CSV (HB, LP, VT y tres de VLP, que se unen en una sola clase), distribución de clases y visualización de señales.
2. **Preprocesamiento:** normalización de cada señal (z-score), ajuste a longitud fija (20 480 muestras) y conversión a espectrograma mel en escala logarítmica, con sus derivadas (delta y delta-delta) como tres canales.
3. **División de los datos:** 70 % entrenamiento, 15 % validación y 15 % prueba, estratificada por clase y con semilla fija.
4. **Modelo:** CNN de dos bloques para extraer patrones del espectrograma, seguida de una GRU bidireccional para la parte temporal y un clasificador de cuatro salidas.
5. **Entrenamiento:** PyTorch Lightning con Focal Loss, Adam y *CosineAnnealingWarmRestarts*.
6. **Evaluación:** métricas globales y por clase, y matriz de confusión sobre el conjunto de prueba.

#### Parte B: versión mejorada (v2)

Tras revisar los resultados por clase de la parte A, que mostraron un comportamiento muy desigual entre clases frecuentes y poco frecuentes, se hicieron los siguientes cambios:

- **Preprocesamiento:** la normalización se aplica antes de rellenar con ceros, y los parámetros del espectrograma (`N_FFT=512`, `HOP_LENGTH=128`) se usan de forma consistente.
- **Aumento de datos:** estiramiento temporal, ruido con relación señal-ruido controlada y SpecAugment (máscaras sobre el espectrograma).
- **Desbalance de clases:** pesos por clase en la función de pérdida y muestreo ponderado (`WeightedRandomSampler`) durante el entrenamiento.
- **Modelo:** la GRU procesa solo la parte real de cada señal (sin el relleno) y se usa un promedio y un máximo sobre el tiempo en lugar del último paso.
- **Selección del modelo:** el mejor punto de entrenamiento y la parada anticipada se basan en el **F1 macro** de validación, que da el mismo peso a las cuatro clases.
- **Ajuste de prior:** corrección posterior al entrenamiento que ajusta las predicciones según la frecuencia real de cada clase. Se calibra con el conjunto de validación y no requiere reentrenar.
- **Evaluación adicional:** *average precision* por clase, que mide qué tan bien se separa cada clase sin depender del umbral de decisión.

## Cómo ejecutarlo

1. Colocar los archivos originales (`.mat`) en `data/raw/`.
2. Ejecutar `src/01_mat_to_json.m` en MATLAB, cambiando `[NOMBRE_ARCHIVO]` por el de cada archivo.
3. Ejecutar `notebooks/02_filter_data.ipynb`, cambiando también `[NOMBRE_ARCHIVO]`.
4. Ejecutar `notebooks/03_CRNN-CLASSIFIER.ipynb` de principio a fin. Se recomienda una GPU, aunque también funciona en CPU, más lento.

Los notebooks usan rutas relativas (`../data/...`), por lo que deben ejecutarse desde la carpeta `notebooks/`.

### Dependencias

- **MATLAB** (solo para el paso 1)
- **Python** 3.x con: `numpy`, `pandas`, `scipy`, `scikit-learn`, `matplotlib`, `seaborn`, `librosa`, `ijson`, `torch`, `pytorch-lightning`, `torchmetrics` y `torchinfo`

## Próximos pasos

- 
