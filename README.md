# 🧮 Terminal Scientific Calculator — Bash Edition

Calculadora científica para terminal con historial persistente y colorido.

## ✨ Características

### Operaciones básicas
- `s` Suma
- `r` Resta
- `m` Multiplicación
- `d` División
- `p` Potenciación
- `f` Factorial

### Trigonometría y logaritmos
- `i` Seno
- `c` Coseno
- `t` Tangente
- `l` Logaritmo natural

### Utilidades adicionales
- `g` MCD y `n` MCM
- `b` Conversión entre bases (decimal, binario, octal, hexadecimal)
- Precisión configurable (`w`)
- Historial de operaciones con persistencia en `~/.calculadora_historial` y opción de limpieza (`x`)

## 📁 Estructura del proyecto
```
.
├── .github/workflows/ci.yml   # Linter y pruebas automatizadas
├── docs/                      # Documentación adicional
├── src/calculadora.sh         # Script principal
├── tests/                     # Scripts de prueba
└── README.md                  # Este archivo
```

## 🚀 Uso
```bash
git clone https://github.com/danisqxas/terminal-scientific-calculator.git
cd terminal-scientific-calculator
chmod +x src/calculadora.sh
./src/calculadora.sh
```

## 🧪 Pruebas
```bash
bash tests/test_operaciones.sh
bash tests/test_historial.sh
```

## 📜 Licencia

MIT License
