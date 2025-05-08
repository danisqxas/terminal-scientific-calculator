# 🏗️ Arquitectura del Script

## 🧩 Componentes Clave

- `main_menu()` → Muestra el menú principal con todas las opciones
- `handle_input()` → Valida entrada del usuario
- `execute_operation()` → Llama a las funciones de cálculo según opción elegida
- `utils/` → Funciones auxiliares como validaciones, formato de salida, etc.

## 🧠 Flujo

```bash
main_menu -> selecciona -> handle_input -> ejecuta -> resultado
```

## 🛠️ Tecnologías Utilizadas

- Bash 4+
- `bc` para precisión matemática
- `tput` para colores
- `awk`, `sed`, `grep` para análisis de texto

El script está modularizado, preparado para ser testeado y extendido.
