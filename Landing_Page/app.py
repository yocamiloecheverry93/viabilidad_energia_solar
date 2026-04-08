import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# 1. Configuración inicial de la página
st.set_page_config(
    page_title="EDA Energía Solar | Grupo J",
    page_icon="☀️",
    layout="wide"
)

# 2. Encabezado principal
st.title("☀️ Análisis Exploratorio de Datos de la Energía Solar")
st.markdown("### Grupo J - BOOTCAMP TALENTO TECH")
st.markdown("---")

# 3. Función para cargar datos (con caché para optimizar rendimiento)
@st.cache_data
def load_data(file):
    # Cargamos la hoja principal de datos
    df = pd.read_excel(file, sheet_name='solar_weather')
    
    # Cargamos el diccionario de variables de la segunda hoja
    dic = pd.read_excel(file, sheet_name='solar_weather (2)', header=None)
    dic = dic.iloc[0] # Tomamos la primera fila como descripción
    
    return df, dic

# 4. Barra lateral para carga de archivo
st.sidebar.header("Carga de Datos")
st.sidebar.info("Por favor, sube el archivo `data.xlsx`.")
uploaded_file = st.sidebar.file_uploader("Sube tu archivo Excel", type=["xlsx", "xls"])

if uploaded_file is not None:
    df, dic = load_data(uploaded_file)
    
    st.sidebar.success("¡Datos cargados correctamente!")
    
    # 5. Creación de pestañas para organizar la información
    tab1, tab2, tab3, tab4 = st.tabs(["📊 Visión General", "🧮 Diccionario de Variables", "🧹 Calidad de Datos", "📈 Visualizaciones y Distribuciones"])
    
    with tab1:
        st.header("Visión General del Dataset")
        st.write("Muestra de los primeros registros:")
        st.dataframe(df.head())
        
        # Métricas principales
        col1, col2, col3 = st.columns(3)
        col1.metric("Total de Registros", df.shape[0])
        col2.metric("Total de Variables", df.shape[1])
        col3.metric("Promedio Temp (°C)", round(df['temp'].mean(), 2))
        
        st.subheader("Estadísticas Descriptivas")
        st.write("Se sospecha una distribución con cola a la izquierda en la mayoría de las variables métricas.")
        st.dataframe(df.describe())
        
    with tab2:
        st.header("Diccionario de Variables")
        st.write("Descripción de cada columna según el dataset original:")
        st.dataframe(dic, use_container_width=True)
        
    with tab3:
        st.header("Análisis de Calidad de Datos")
        
        col_nulls, col_zeros = st.columns(2)
        
        with col_nulls:
            st.subheader("Valores Nulos (%)")
            nulls_pct = (df.isnull().sum() / len(df) * 100).round(2)
            st.dataframe(nulls_pct)
            st.success("Conclusión: No hay datos nulos en el dataset, por lo tanto no es necesario hacer un tratamiento de imputación.")
            
        with col_zeros:
            st.subheader("Valores Iguales a Cero (%)")
            st.write("Proporción de registros que son exactamente cero:")
            zeros_pct = ((df == 0).sum() / len(df) * 100).round(2)
            st.dataframe(zeros_pct)
            st.info("Variables como 'snow_1h' (98.09%) y 'rain_1h' (87.31%) tienen una alta concentración de ceros debido a su naturaleza estacional.")
            
    with tab4:
        st.header("Análisis de Distribución y Valores Atípicos")
        st.write("Análisis de la distribución de cada variable numérica para confirmar asimetrías y detectar outliers mediante boxplots.")
        
        # Seleccionar numéricas igual que en el notebook original
        numerical_cols_for_boxplot = df.select_dtypes(include=np.number).columns
        
        # Generar los boxplots dinámicamente
        fig = plt.figure(figsize=(25, 28))
        for i, col in enumerate(numerical_cols_for_boxplot):
            plt.subplot(5, 4, i + 1) # Usamos 5 filas x 4 columnas para acomodar 17 variables
            sns.boxplot(y=df[col], showfliers=True, color='skyblue')
            plt.title(f'Boxplot de {col.replace("_", " ").title()}')
            plt.ylabel('Valor')
            plt.grid(axis='y', linestyle='--', alpha=0.7)
            
        plt.tight_layout()
        st.pyplot(fig)

else:
    st.info("👈 Esperando a que subas el dataset desde la barra lateral para comenzar el análisis.")
    
    # Imagen de placeholder mientras no hay datos
    st.image("https://images.unsplash.com/photo-1509391366360-5256543b59eb?q=80&w=2070&auto=format&fit=crop", caption="Energía Solar", use_container_width=True)