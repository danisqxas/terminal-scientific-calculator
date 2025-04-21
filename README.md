# 🧮 Terminal Scientific Calculator

**Terminal Scientific Calculator** es una herramienta avanzada escrita completamente en Bash, diseñada para ofrecer una experiencia de cálculo científica directamente desde el terminal. Este script es mucho más que una simple calculadora de línea de comandos: es un laboratorio matemático interactivo, visual y eficiente, ideal para entornos Unix-like y especialmente optimizado para su uso en **Git Bash** en Windows.

> ✅ Pensada para estudiantes, entusiastas del terminal, usuarios Linux avanzados y desarrolladores que valoran soluciones funcionales, eficientes y bien diseñadas sin depender de interfaces gráficas.

---

## 🎯 Características destacadas

- ✔️ Modo **básico** y **científico** conmutable dinámicamente
- 🎨 Interfaz visual con colores ANSI para una mejor experiencia en consola
- 📚 Historial automático de las últimas operaciones realizadas
- 🧮 Funciones matemáticas:
  - Suma, multiplicación, división, potencia
  - Raíz cuadrada, seno, coseno, tangente, logaritmo natural
  - Factorial, MCD (máximo común divisor), MCM (mínimo común múltiplo)
- 🔢 Conversión entre sistemas numéricos:
  - Decimal ⇄ Binario / Octal / Hexadecimal
- ⚙️ Configuración de la precisión decimal en tiempo real
- ✅ Validación robusta de entradas y manejo de errores
- 📐 Basado en herramientas estándar (`awk`, `bc`, `bash`) — sin dependencias externas

---

## 💻 Cómo ejecutar (especialmente en Git Bash)

1. Cloná el repositorio o mové el script a tu máquina local.

2. Desde Git Bash, navegá a la carpeta donde se encuentra el script.  
   Por ejemplo:

   ```bash
   cd /c/Users/mcdwd/Downloads
   ```

3. Dale permisos de ejecución al script:

   ```bash
   chmod +x src/calculadora.sh
   ```

4. Ejecutalo:

   ```bash
   ./src/calculadora.sh
   ```

> 🧠 Si estás usando Linux o WSL, los pasos son idénticos. Solo cambia la ruta del directorio.

---

## 📦 Estructura del proyecto

```plaintext
terminal-scientific-calculator/
├── src/
│   └── calculadora.sh        # Script principal con toda la lógica funcional
│
├── assets/
│   └── preview.gif           # (Opcional) Captura o demo animada del menú de la calculadora
│
├── README.md                 # Documentación completa y profesional del proyecto
├── LICENSE                   # Licencia MIT de uso libre y respetuoso
└── .gitignore                # (Opcional) Exclusiones para mantener el repositorio limpio
```

---

## 🧠 Requisitos

Este script está diseñado para ser completamente portable. Solo requiere herramientas que ya están disponibles en cualquier sistema moderno basado en Unix:

- `bash`
- `awk`
- `bc`

> En Windows se recomienda **Git Bash** o **WSL** para garantizar compatibilidad y experiencia visual completa.

---

## 🧪 Casos de uso recomendados

- 👨‍🎓 **Estudiantes**: Ideal para practicar operaciones matemáticas y lógica desde la terminal
- 💻 **Desarrolladores**: Como herramienta auxiliar rápida o ejemplo de scripting estructurado en Bash
- 🧰 **Sysadmins y DevOps**: Cálculos rápidos sin salir de la terminal
- 🔬 **Curiosos del terminal**: Para explorar cómo construir interfaces interactivas sin GUI

---

## 🧩 Diseño técnico y filosofía del proyecto

El script ha sido cuidadosamente organizado en funciones independientes, con menús visuales limpios, colores para mejorar la experiencia del usuario y validaciones sólidas para evitar errores comunes. Cada sección del código fue escrita con el objetivo de mantener legibilidad, modularidad y facilidad de mantenimiento.

Este proyecto no busca solo ser útil: busca **demostrar que Bash también puede producir interfaces amigables, completas y poderosas**, desafiando la noción de que la terminal es solo para tareas básicas.

---

## ✍️ Autor

Desarrollado con dedicación por [aerthex (Dani)](https://github.com/danisqxas)  
📬 Contacto: [@daniiwnet](https://x.com/daniiwnet?s=21)

> *Apasionado por la ciberseguridad, el desarrollo con propósito y las herramientas bien hechas.*

---

## 📜 Licencia

Distribuido bajo la **Licencia MIT**.  
Podés usarlo, adaptarlo o compartirlo libremente. Solo se solicita reconocimiento a la autoría original.

---

## 🚀 Reflexión final

**Terminal Scientific Calculator** no es solo un ejercicio de scripting — es una prueba de que Bash puede ser visual, modular, preciso y elegante. Está pensado para resolver cálculos, sí, pero también para demostrar que en las manos correctas, incluso una terminal puede ser un entorno de usuario poderoso.

> Porque lo importante no es qué tan gráfica es tu herramienta, sino qué tan bien está construida.
