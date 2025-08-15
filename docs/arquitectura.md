# 🏗️ Arquitectura del Script

## 🧩 Componentes Clave

- `calculadora()` → bucle principal de interacción.
- `agregar_historial`, `cargar_historial`, `limpiar_historial` → manejo de historial persistente.
- `factorial`, `mcd`, `mcm`, `conversion_base` → operaciones auxiliares.

## 🧠 Flujo

1. `main` verifica dependencias y carga el historial desde `~/.calculadora_historial`.
2. Se muestra un banner de bienvenida.
3. `calculadora` procesa las operaciones hasta que el usuario decida salir.

## 🛠️ Tecnologías Utilizadas

- Bash 4+
- `awk` y `bc` para cálculos matemáticos
- Códigos ANSI para colores en la terminal

El script está modularizado y puede ser importado desde otros scripts para pruebas.
