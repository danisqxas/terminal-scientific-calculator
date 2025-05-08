# 🧮 Terminal Scientific Calculator — Bash Edition v2.0

> “Elegancia no es sumar. Elegancia es resolver el caos numérico con un solo script.” – aerthex

Una calculadora científica avanzada hecha 100% en Bash, con una interfaz visual rica en colores, validaciones detalladas y más de 25 funciones incorporadas. Este no es un script improvisado. Es un entorno matemático portátil, rápido y potente creado por [@danisqxas](https://github.com/danisqxas) para usuarios exigentes del terminal.

---

## 🧠 ¿Qué es esto?

Un archivo `.sh` que no solo suma y resta. Este script:
- Evalúa expresiones científicas con precisión
- Valida la entrada con controles estrictos
- Almacena resultados y memoria con acceso rápido
- Presenta todo en una UI colorida, centrada y organizada

---

## 🚀 Funciones Incluidas

### 🧮 Operaciones Básicas
- `s` → Suma
- `r` → Resta
- `m` → Multiplicación
- `d` → División
- `p` → Potenciación
- `√` → Raíz cuadrada

### 📐 Funciones Trigonométricas
- `sin(x)` → Seno (radianes)
- `cos(x)` → Coseno
- `tan(x)` → Tangente
- Precisión configurable

### 🧪 Logaritmos y Exponenciales
- `ln(x)` → Logaritmo natural
- `log10(x)` → Logaritmo base 10
- `exp(x)` → Exponencial (e^x)

### 📊 Estadística
- `avg` → Promedio
- `sum` → Sumatoria
- `prod` → Productoria
- `stddev` → Desviación estándar
- `var` → Varianza

### 💰 Finanzas
- `simple_interest(p, r, t)`
- `compound_interest(p, r, t, n)`
- `VPN` con múltiples flujos de caja

### 🔁 Conversiones de Base
- Decimal ⇄ Binario
- Decimal ⇄ Octal
- Decimal ⇄ Hexadecimal

### 🔧 Utilidades Extra
- `!` → Factorial
- MCD y MCM
- Evaluador directo: `=3+5*7`
- Cambio de precisión (`w`)
- Modo silencioso / verbose (`z`)
- Borrar historial (`x`)

---

## 📁 Estructura del Proyecto

```
terminal-scientific-calculator/
├── src/
│   └── calculadora.sh         # Script principal
├── assets/
│   └── banner.png             # Banner visual (opcional)
├── docs/
│   └── funciones_avanzadas.md # Documentación detallada (opcional)
├── tests/
│   └── test_operaciones.sh    # Casos de prueba (futuros)
├── setup.sh                   # Script de instalación automática
├── requirements.txt           # Dependencias (bc, awk, etc.)
├── LICENSE                    # Licencia MIT
└── README.md                  # Este documento
```

---

## ⚙️ Instalación

```bash
git clone https://github.com/danisqxas/terminal-scientific-calculator.git
cd terminal-scientific-calculator
chmod +x setup.sh
./setup.sh
```

Y luego:

```bash
./src/calculadora.sh
```

---

## 🧰 Requisitos

- Bash 4+
- `bc`, `awk`, `grep`, `sed`, `tput`
- Funciona en: Linux, macOS, WSL, Alpine

---

## 💡 Ejemplo Visual

```text
╔════════════════════════════════════════════╗
║       TERMINAL SCIENTIFIC CALCULATOR      ║
╚════════════════════════════════════════════╝

Selecciona una opción:

[s] Sumar      [r] Restar     [m] Multiplicar
[d] Dividir   [p] Potencia   [!] Factorial
[i] Seno      [c] Coseno     [t] Tangente
[l] Log Nat   [q] Salir      [?] Ayuda
```

---

## 🏷️ Versión Actual

```
v2.0.0 – “Precision in Shell”
```

---

## 🔮 Roadmap Futuro

- Exportar historial a CSV o Markdown
- Agregar regresión lineal y funciones estadísticas avanzadas
- Interfaz visual usando `dialog` o `whiptail`
- Autocompletado en terminal y soporte para `fzf`
- Configuración persistente por archivo `.conf`

---

## 🧪 ¿Por qué usar esto?

Porque no es una simple calculadora.  
Es una suite de análisis numérico escrita para terminalistas serios, que valoran:
- Velocidad
- Precisión
- Estilo visual sin depender de GUI
- Portabilidad extrema (funciona en cualquier shell moderno)

Y porque no todo en la vida es abrir Python o Excel para sacar una raíz cuadrada.

---

## 📜 Licencia

MIT License — Este proyecto es libre para usar, mejorar y compartir.

---

## ✍️ Autoría

**Desarrollado desde cero por [@danisqxas](https://github.com/danisqxas)**  
Optimizado bajo el alias **aerthex** — donde cada script está pensado para destacar por encima del promedio.

---

## 🔥 Frase Final

> Si hiciste todo esto con Bash, imaginate lo que podés hacer con Go, Rust o C.  
> Esta calculadora no solo resuelve cuentas...  
> **Resuelve la duda de si sabés o no escribir buen código.**

**– aerthex**
