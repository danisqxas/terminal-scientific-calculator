# 🩎 Calculadora Aerthex — Edición Terminal

> “La elegancia no consiste en sumar; la elegancia es domar el caos numérico con un solo script.” – Aerthex

Esta calculadora científica avanzada está escrita 100 % en Bash. No se trata de un simple script improvisado, sino de un entorno matemático portátil y potente con una interfaz de líneas de comando agradable y colorida. Incluye validaciones detalladas, historial de operaciones y permite ajustar la precisión de los cálculos. El objetivo de Aerthex es poner en manos de cualquier usuario de terminal una herramienta completa para resolver problemas matemáticos complejos sin instalar grandes dependencias. Solo requiere `awk` y `bc`.

## 🎯 Funcionalidades

Aerthex agrupa sus capacidades en módulos que se acceden desde un menú interactivo:

- **Ecuaciones y Raíces**
  - Resolución de ecuaciones de segundo y tercer grado.
  - Método de Newton–Raphson para encontrar raíces de funciones arbitrarias.
  
- **Matrices**
  - Multiplicación de matrices (hasta 3×3).
  - Cálculo de determinantes, matrices adjuntas e inversas.
  - Resolución de sistemas lineales por regla de Cramer.

- **Números Complejos**
  - Operaciones básicas (suma, resta, multiplicación y división).
  - Cálculo de módulo, argumento, conjugado y exponencial compleja.
  - Funciones logarítmicas y potencias de números complejos.

- **Cálculo Numérico**
  - Derivación numérica de primer y segundo orden.
  - Integración mediante los métodos del trapecio y de Simpson.
  - Resolución de ecuaciones diferenciales ordinarias con el método de Euler.

- **Estadística y Combinatoria**
  - Cálculo de media, mediana, moda, desviación típica y varianza.
  - Operaciones combinatorias: factorial, permutaciones, combinaciones y coeficientes binomiales.

- **Transformada Discreta de Fourier (DFT)**
  - Computación de la DFT para series finitas de datos.

- **Teoría de Números y Conversiones**
  - Máximo común divisor, mínimo común múltiplo y prueba de primalidad.
  - Generación de números primos en un rango.
  - Conversión entre bases (binaria, octal, decimal y hexadecimal).

- **Otras utilidades**
  - Gestión del historial de operaciones con posibilidad de exportar y limpiar.
  - Ajuste dinámico de la precisión decimal.
  - Interfaz interactiva opcional con `fzf` o `gum` (si están instalados).

## 🚀 Instalación

1. Asegúrate de tener instalado Bash, `awk` y `bc`.
2. Clona este repositorio:

   ```bash
   git clone https://github.com/danisqxas/terminal-scientific-calculator.git
   cd terminal-scientific-calculator
   ```

3. Ejecuta la calculadora:

   ```bash
   bash src/calculadora.sh
   ```

   Si prefieres la interfaz fuzzy, instala `fzf` o `gum` y la calculadora lo detectará automáticamente.

## 📦 Paquetes

Este proyecto incluye scripts para generar paquetes listos para instalar:

- **Debian/Ubuntu**: ejecuta el objetivo de empaquetado para obtener un paquete `.deb` (`calc-aerthex`).
- **Arch/Manjaro**: genera un paquete `.pkg.tar.zst` compatible.

Consulta las funciones `crear_paquete_deb` y `crear_paquete_arch` en el código para más detalles.

## 🤔 Pruebas

En el directorio `tests` encontrarás ejemplos y guiones de prueba que ejercitan las diferentes funciones de la calculadora. Para ejecutarlos:

```bash
bash tests/test_calculadora.sh
```

(Adapta según el contenido real de tus pruebas.)

## 📚 Documentación

La carpeta `docs` contiene material adicional, como manuales de uso y ejemplos. También puedes consultar los comentarios exhaustivos incluidos en el código fuente (`src/calculadora.sh`) para comprender la implementación de cada módulo.

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras errores o deseas añadir nuevas funcionalidades, abre un *issue* o envía un *pull request*. Antes de enviar cambios, asegúrate de que tu código sigue el estilo del proyecto y está bien comentado.

## 📋 Licencia

Este proyecto se distribuye bajo la licencia MIT. Consulta el archivo `LICENSE` para más información.
