#!/bin/bash
# acciones para referencia :)
#
# Requisitos: awk y bc instalados y accesibles en PATH (:)
# ==============================================================================

# Colores ANSI para una presentación agradable en terminales compatibles.
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BLANCO='\033[1;37m'
NEGRITA='\033[1m'
RESET='\033[0m'
FONDO_AZUL='\033[44m'

# Historial y precisión global. Se almacena como una lista de cadenas con
# descripciones de las operaciones y resultados. Por defecto se guardan
# hasta 20 operaciones recientes.
HISTORIAL=()
# Ruta del fichero de historial.  Este archivo se utilizará para
# almacenar de forma persistente todas las operaciones realizadas entre
# ejecuciones de la calculadora.  Se define aquí para que pueda ser
# modificado en tiempo de ejecución mediante las funciones de carga y
# guardado.
HIST_FILE="$HOME/.calc_ultra_history.log"
MAX_HISTORIAL=20

# Precisión para resultados numéricos. Este valor se pasa a printf en awk
# como número de cifras significativas. -1 implica usar el formato general
# (%g) que decide automáticamente la notación.
PRECISION=6

#
# MODO SCRIPT Y CARGA DE HISTORIAL
#
# Antes de definir cualquier función se provee un bloque que permite
# utilizar este mismo script como calculadora en línea de comandos: si el
# usuario invoca el script con argumentos (por ejemplo `./calc_ultra.sh
# "2+2"`), esos argumentos se consideran una expresión aritmética y se
# evalúan inmediatamente.  Esto facilita la automatización y evita
# iniciar la interfaz interactiva completa cuando no es necesario.  Se
# intenta usar `bc` para la evaluación; en su defecto se recurre a
# `python3`.  Si ninguna de estas utilidades está disponible, se
# notifica al usuario y se aborta.
if [ "$#" -gt 0 ]; then
    expr="$*"
    # Si `bc` está presente, emplearlo para la evaluación con
    # precisión arbitraria.  Redirigimos stderr para capturar errores de
    # sintaxis; cualquier salida en stderr se considerará un error.
    if command -v bc >/dev/null 2>&1; then
        if result=$(echo "$expr" | bc -l 2>/dev/null); then
            echo "$result"
            exit 0
        else
            echo "Error en la expresión: '$expr'" >&2
            exit 1
        fi
    # Si bc no está disponible, intentamos con python3.  Se exponen
    # módulos matemáticos para poder evaluar funciones estándar.  Los
    # argumentos se pasan a Python a través de una variable de entorno
    # para evitar problemas de escape.  Si la evaluación falla, el
    # proceso sale con código distinto de cero y el shell muestra un
    # mensaje de error.
    elif command -v python3 >/dev/null 2>&1; then
        EXPR_ENV="$expr" python3 - <<'PY'
import os, sys, math, cmath
expr = os.environ.get('EXPR_ENV', '')
try:
    res = eval(expr)
    # Representar números complejos como a+bj, similar a bash
    if isinstance(res, complex):
        print(f"{res.real}+{res.imag}j")
    else:
        print(res)
except Exception:
    sys.exit(1)
PY
        if [ $? -eq 0 ]; then
            exit 0
        else
            echo "Error en la expresión: '$expr'" >&2
            exit 1
        fi
    else
        echo "Error: no se encontró 'bc' ni 'python3' para evaluar la expresión." >&2
        exit 1
    fi
fi

#
# Carga automática de historial persistente.
#
# Si existe un archivo de historial previo en la ruta definida por
# HIST_FILE, sus líneas se cargan en la matriz HISTORIAL.  Esto
# garantiza que al iniciar la calculadora se conserve la memoria de
# operaciones anteriores.  Después de cargar, se utiliza
# `limitar_historial` para recortar el historial a las últimas
# MAX_HISTORIAL entradas si fuera necesario.
if [ -f "$HIST_FILE" ]; then
    while IFS= read -r __line; do
        HISTORIAL+=("$__line")
    done < "$HIST_FILE"
    # Asegurar que el historial no exceda el máximo configurado
    while [ ${#HISTORIAL[@]} -gt "$MAX_HISTORIAL" ]; do
        HISTORIAL=("${HISTORIAL[@]:1}")
    done
fi

# ============================================================================
# Funciones auxiliares generales
# ============================================================================

# Limita el tamaño del historial para que no crezca indefinidamente.
limitar_historial() {
    while [ ${#HISTORIAL[@]} -gt "$MAX_HISTORIAL" ]; do
        HISTORIAL=("${HISTORIAL[@]:1}")
    done
}

# Pausa entre operaciones para que el usuario pueda leer la salida.
esperar_para_continuar() {
    echo ""
    read -rp "Presione ENTER para continuar..." _
}

# Verifica si un comando está disponible. Si no lo está, aborta el script.
validar_dependencia() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${ROJO}Error:${RESET} Se requiere el comando '${cmd}', pero no está instalado."
        exit 1
    fi
}

# Configura la precisión de las operaciones. Acepta enteros >= -1.
configurar_precision() {
    echo -e "\n${AMARILLO}CONFIGURACIÓN DE PRECISIÓN${RESET}"
    echo -e "Precisión actual: ${VERDE}${PRECISION}${RESET}"
    read -rp "Introduzca un entero ≥ -1 (−1 para formato general %g): " nueva
    if [[ ! "$nueva" =~ ^-?[0-9]+$ ]] || [ "$nueva" -lt -1 ]; then
        echo -e "\n${ROJO}✗ Valor no válido. La precisión no se ha modificado.${RESET}"
        return
    fi
    PRECISION="$nueva"
    if [ "$PRECISION" -eq -1 ]; then
        echo -e "\n${VERDE}✓ Precisión establecida al formato general (%g).${RESET}"
    else
        echo -e "\n${VERDE}✓ Precisión establecida a ${PRECISION} cifra(s) significativas.${RESET}"
    fi
}

# Muestra el encabezado principal de la calculadora. Se llama en cada
# iteración del bucle principal para refrescar la pantalla.
mostrar_encabezado() {
    clear
    echo -e "${AZUL}╔═══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${AZUL}║    ${MAGENTA}CALCULADORA ULTRA By Aerthex${AZUL}              ║${RESET}"
    echo -e "${AZUL}╠═══════════════════════════════════════════════════════╣${RESET}"
    if [ "$PRECISION" -eq -1 ]; then
        echo -e "${AZUL}║ ${CYAN}Precisión:${RESET} general (%g)                                        ║${RESET}"
    else
        printf "${AZUL}║ ${CYAN}Precisión:${RESET} %2s cifra(s) significativas (%g)              ║${RESET}\n" "$PRECISION"
    fi
    echo -e "${AZUL}╚═══════════════════════════════════════════════════════╝${RESET}"
}

# Añade una entrada al historial y lo recorta si es necesario.
agregar_historial() {
    local entrada="$1"
    # Añadir la nueva operación a la estructura en memoria.  Se
    # utiliza la sintaxis de Bash para agregar elementos al final de un
    # array asociativo.
    HISTORIAL+=("$entrada")
    # Guardar también la entrada en el fichero de historial para que
    # persista entre ejecuciones.  Se utiliza printf en lugar de echo
    # para evitar interpretaciones de caracteres especiales.
    if [ -n "$HIST_FILE" ]; then
        printf '%s\n' "$entrada" >> "$HIST_FILE"
    fi
    # Limitar el tamaño del historial en memoria a MAX_HISTORIAL
    while [ ${#HISTORIAL[@]} -gt "$MAX_HISTORIAL" ]; do
        HISTORIAL=("${HISTORIAL[@]:1}")
    done
}

# Muestra las entradas del historial del más reciente al más antiguo.
mostrar_historial() {
    if [ ${#HISTORIAL[@]} -eq 0 ]; then
        echo -e "\n${AMARILLO}El historial está vacío.${RESET}"
    else
        echo -e "\n${AMARILLO}HISTORIAL DE OPERACIONES (recientes primero)${RESET}"
        echo -e "${CYAN}-----------------------------------------------${RESET}"
        local idx=${#HISTORIAL[@]}
        for (( i=${#HISTORIAL[@]}-1; i>=0; i-- )); do
            printf "%2d. %s\n" "$((idx-i))" "${HISTORIAL[$i]}"
        done
        echo -e "${CYAN}-----------------------------------------------${RESET}"
    fi
    esperar_para_continuar
}

# Limpia todas las entradas del historial.
limpiar_historial() {
    HISTORIAL=()
    echo -e "\n${VERDE}✓ Historial limpiado.${RESET}"
    esperar_para_continuar
}

# ============================================================================
# Funciones de solvers de ecuaciones
# ============================================================================

# Resuelve una ecuación cuadrática ax^2 + bx + c = 0. Maneja raíces
# reales y complejas. Formatea la salida según la precisión configurada.
resolver_cuadratica() {
    echo -e "\n${AMARILLO}RESOLUCIÓN DE ECUACIONES CUADRÁTICAS${RESET}"
    read -rp "Ingrese a: " a
    read -rp "Ingrese b: " b
    read -rp "Ingrese c: " c
    # Validar que a sea diferente de 0
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$c" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Error: Los coeficientes deben ser números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    if (( $(echo "$a == 0" | bc -l) )); then
        echo -e "\n${ROJO}✗ Error: 'a' no puede ser cero en una ecuación cuadrática.${RESET}"
        esperar_para_continuar
        return
    fi
    # Calcular discriminante
    local disc
    disc=$(awk "BEGIN { printf \"%g\", ($b*$b) - 4*$a*$c }")
    local two_a
    two_a=$(awk "BEGIN { printf \"%g\", 2*$a }")
    if (( $(echo "$disc >= 0" | bc -l) )); then
        # Raíces reales
        local sqrt_disc
        sqrt_disc=$(awk "BEGIN { printf \"%g\", sqrt($disc) }")
        local r1 r2
        r1=$(awk -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", (-$b + $sqrt_disc)/$two_a; else printf \"%.${PRECISION}g\", (-$b + $sqrt_disc)/$two_a }")
        r2=$(awk -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", (-$b - $sqrt_disc)/$two_a; else printf \"%.${PRECISION}g\", (-$b - $sqrt_disc)/$two_a }")
        echo -e "\n${VERDE}Raíces reales:${RESET}"
        echo -e "x₁ = $r1"
        echo -e "x₂ = $r2"
        agregar_historial "Cuadrática: a=$a, b=$b, c=$c → x1=$r1, x2=$r2"
    else
        # Raíces complejas
        local abs_disc
        abs_disc=$(awk "BEGIN { printf \"%g\", sqrt(-$disc) }")
        local real_part imag_part
        real_part=$(awk -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", -$b/$two_a; else printf \"%.${PRECISION}g\", -$b/$two_a }")
        imag_part=$(awk -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", $abs_disc/$two_a; else printf \"%.${PRECISION}g\", $abs_disc/$two_a }")
        echo -e "\n${VERDE}Raíces complejas:${RESET}"
        echo -e "x₁ = ${real_part} + ${imag_part}i"
        echo -e "x₂ = ${real_part} - ${imag_part}i"
        agregar_historial "Cuadrática: a=$a, b=$b, c=$c → x1=${real_part}+${imag_part}i, x2=${real_part}-${imag_part}i"
    fi
    esperar_para_continuar
}

# Resuelve una ecuación cúbica de la forma ax^3 + bx^2 + cx + d = 0. Usa una
# combinación de reducción mediante Newton para encontrar una raíz real y
# luego factoriza el polinomio a una cuadrática. Maneja raíces complejas.
resolver_cubica() {
    echo -e "\n${AMARILLO}RESOLUCIÓN DE ECUACIONES CÚBICAS${RESET}"
    read -rp "Ingrese a: " a
    read -rp "Ingrese b: " b
    read -rp "Ingrese c: " c
    read -rp "Ingrese d: " d
    # Validaciones básicas
    for coef in "$a" "$b" "$c" "$d"; do
        if [[ ! "$coef" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Error: Todos los coeficientes deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    if (( $(echo "$a == 0" | bc -l) )); then
        echo -e "\n${ROJO}✗ Error: 'a' no puede ser cero en una ecuación cúbica.${RESET}"
        esperar_para_continuar
        return
    fi
    # Normalizar coeficientes (dividir por a)
    local b1 c1 d1
    b1=$(awk "BEGIN { print $b/$a }")
    c1=$(awk "BEGIN { print $c/$a }")
    d1=$(awk "BEGIN { print $d/$a }")
    # Derivada del polinomio
    # Newton para encontrar una raíz real
    local x guess=0
    # Empieza con una suposición (cero). Realiza hasta 50 iteraciones.
    x=0
    for ((iter=0; iter<50; iter++)); do
        local fx dfx
        fx=$(awk -v x="$x" -v b="$b1" -v c="$c1" -v d="$d1" "BEGIN { print x*x*x + b*x*x + c*x + d }")
        dfx=$(awk -v x="$x" -v b="$b1" -v c="$c1" "BEGIN { print 3*x*x + 2*b*x + c }")
        if (( $(echo "sqrt(($dfx)^2) < 1e-12" | bc -l) )); then
            return
        fi
        local xnew
        xnew=$(awk "BEGIN { print $x - $fx / $dfx }")
        # Comprobar convergencia
        if (( $(echo "sqrt(($xnew-$x)^2) < 1e-12" | bc -l) )); then
            x=$xnew
            break
        fi
        x=$xnew
    done
    local real_root
    real_root=$x
    # Reducción a una cuadrática: dividir el polinomio (monico) entre (x - real_root)
    # Coeficientes de la división sintética
    local q2 q1 q0
    q2=1
    q1=$(awk -v b="$b1" -v r="$real_root" "BEGIN { print b + r }")
    q0=$(awk -v c="$c1" -v b="$b1" -v r="$real_root" "BEGIN { print c + b*r + r*r }")
    local q_const
    q_const=$(awk -v d="$d1" -v c="$c1" -v b="$b1" -v r="$real_root" "BEGIN { print d + c*r + b*r*r + r*r*r }")
    # Resolver la cuadrática q2*x^2 + q1*x + q0 = 0
    local disc
    disc=$(awk "BEGIN { print $q1*$q1 - 4*$q2*$q0 }")
    local roots=()
    # Guardar la raíz real encontrada
    roots+=("$real_root")
    if (( $(echo "$disc >= 0" | bc -l) )); then
        # Dos raíces reales adicionales
        local sqrt_disc
        sqrt_disc=$(awk "BEGIN { print sqrt($disc) }")
        local r2 r3
        r2=$(awk -v q2="$q2" -v q1="$q1" -v sqrt_disc="$sqrt_disc" -v prec="$PRECISION" "BEGIN { denom=2*q2; if (prec==-1) printf \"%g\", (-q1 + sqrt_disc)/denom; else printf \"%.${PRECISION}g\", (-q1 + sqrt_disc)/denom }")
        r3=$(awk -v q2="$q2" -v q1="$q1" -v sqrt_disc="$sqrt_disc" -v prec="$PRECISION" "BEGIN { denom=2*q2; if (prec==-1) printf \"%g\", (-q1 - sqrt_disc)/denom; else printf \"%.${PRECISION}g\", (-q1 - sqrt_disc)/denom }")
        roots+=("$r2" "$r3")
        echo -e "\n${VERDE}Raíces reales encontradas:${RESET}"
        for r in "${roots[@]}"; do
            echo "x = $r"
        done
        agregar_historial "Cúbica: a=$a,b=$b,c=$c,d=$d → raíces reales: ${roots[*]}"
    else
        # Dos raíces complejas conjugadas
        local abs_disc
        abs_disc=$(awk "BEGIN { print sqrt(-$disc) }")
        local real_part imag_part
        real_part=$(awk -v q2="$q2" -v q1="$q1" -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", (-q1)/(2*q2); else printf \"%.${PRECISION}g\", (-q1)/(2*q2) }")
        imag_part=$(awk -v q2="$q2" -v abs_disc="$abs_disc" -v prec="$PRECISION" "BEGIN { if (prec==-1) printf \"%g\", abs_disc/(2*q2); else printf \"%.${PRECISION}g\", abs_disc/(2*q2) }")
        echo -e "\n${VERDE}Raíz real:${RESET} x = $real_root"
        echo -e "${VERDE}Par de raíces complejas:${RESET}"
        echo -e "x = ${real_part} + ${imag_part}i"
        echo -e "x = ${real_part} - ${imag_part}i"
        agregar_historial "Cúbica: a=$a,b=$b,c=$c,d=$d → raíz real $real_root; complejas: ${real_part}±${imag_part}i"
    fi
    esperar_para_continuar
}

# Encuentra una raíz de una función f(x) mediante el método de Newton-
# Raphson. Solicita la expresión de f(x), su derivada f'(x), un valor
# inicial, una tolerancia y un número máximo de iteraciones.
resolver_raiz_newton() {
    echo -e "\n${AMARILLO}BÚSQUEDA DE RAÍZ POR NEWTON-RAPHSON${RESET}"
    echo -e "Ingrese la función f(x) usando 'x' como variable (por ejemplo, x^3 - 2*x - 5):"
    read -rp "f(x) = " fexpr
    echo -e "Ingrese la derivada f'(x) de la función anterior (por ejemplo, 3*x^2 - 2):"
    read -rp "f'(x) = " fprime
    read -rp "Valor inicial para x: " x0
    read -rp "Tolerancia (por ejemplo 1e-7): " tol
    read -rp "Iteraciones máximas: " max_iter
    # Validaciones mínimas (sólo verificar que números sean válidos para x0, tol y max_iter)
    if [[ ! "$x0" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$tol" =~ ^[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$ ]] || [[ ! "$max_iter" =~ ^[0-9]+$ ]]; then
        echo -e "\n${ROJO}✗ Error: Ingrese valores numéricos válidos para el valor inicial, tolerancia e iteraciones.${RESET}"
        esperar_para_continuar
        return
    fi
    local x="$x0"
    local i
    local converged=0
    for ((i=0; i<max_iter; i++)); do
        # Evaluar f(x) y f'(x) usando awk. Se usa eval seguro con variable x.
        local fx dfx
        fx=$(awk -v x="$x" "BEGIN { print $fexpr }")
        dfx=$(awk -v x="$x" "BEGIN { print $fprime }")
        if (( $(echo "sqrt(($dfx)^2) < 1e-14" | bc -l) )); then
            echo -e "\n${ROJO}✗ La derivada se anuló; el método no puede continuar.${RESET}"
            esperar_para_continuar
            return
        fi
        local x_new
        x_new=$(awk "BEGIN { print $x - $fx/$dfx }")
        # Comprobar convergencia
        if (( $(echo "sqrt(($x_new - $x)^2) < $tol" | bc -l) )); then
            x=$x_new
            converged=1
            break
        fi
        x=$x_new
    done
    if [ "$converged" -eq 1 ]; then
        local res
        if [ "$PRECISION" -eq -1 ]; then
            res=$(awk -v x="$x" "BEGIN { printf \"%g\", x }")
        else
            res=$(awk -v x="$x" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", x }")
        fi
        echo -e "\n${VERDE}Raíz aproximada:${RESET} x ≈ $res"
        agregar_historial "Newton-Raphson en f(x)=$fexpr con x0=$x0 → raíz ≈ $res"
    else
        echo -e "\n${ROJO}✗ No se alcanzó la convergencia en las $max_iter iteraciones.${RESET}"
    fi
    esperar_para_continuar
}

# ============================================================================
# Funciones de matrices (2x2 y 3x3)
# ============================================================================

# Multiplica dos matrices de dimensión 2x2 o 3x3. Solicita los valores
# separados por espacios. Devuelve la matriz resultante en formato 2D.
matriz_multiplicar() {
    echo -e "\n${AMARILLO}PRODUCTO DE MATRICES${RESET}"
    read -rp "Elija dimensión (2 para 2x2, 3 para 3x3): " dim
    if [[ "$dim" != "2" && "$dim" != "3" ]]; then
        echo -e "\n${ROJO}✗ Dimensión no válida. Solo se soportan 2 o 3.${RESET}"
        esperar_para_continuar
        return
    fi
    local total=$((dim * dim))
    echo "Ingrese los elementos de la primera matriz (fila por fila, separados por espacios):"
    read -ra matA
    if [ "${#matA[@]}" -ne "$total" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $total valores para la primera matriz.${RESET}"
        esperar_para_continuar
        return
    fi
    echo "Ingrese los elementos de la segunda matriz (fila por fila, separados por espacios):"
    read -ra matB
    if [ "${#matB[@]}" -ne "$total" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $total valores para la segunda matriz.${RESET}"
        esperar_para_continuar
        return
    fi
    # Realizar el producto C = A * B
    local result=( )
    local i j k
    for ((i=0; i<dim; i++)); do
        for ((j=0; j<dim; j++)); do
            local sum=0
            for ((k=0; k<dim; k++)); do
                local aVal bVal prod
                aVal=${matA[$((i*dim + k))]}
                bVal=${matB[$((k*dim + j))]}
                prod=$(awk -v a="$aVal" -v b="$bVal" "BEGIN { print a*b }")
                sum=$(awk -v s="$sum" -v p="$prod" "BEGIN { print s+p }")
            done
            result+=("$sum")
        done
    done
    echo -e "\n${VERDE}Matriz resultante:${RESET}"
    for ((i=0; i<dim; i++)); do
        local line=""
        for ((j=0; j<dim; j++)); do
            local val=${result[$((i*dim + j))]}
            # Formatear según precisión
            local fval
            if [ "$PRECISION" -eq -1 ]; then
                fval=$(awk -v v="$val" "BEGIN { printf \"%g\", v }")
            else
                fval=$(awk -v v="$val" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            line+="$fval\t"
        done
        echo -e "$line"
    done
    agregar_historial "Producto de matrices ${dim}x${dim} realizado."
    esperar_para_continuar
}

# Calcula el determinante de una matriz 2x2 o 3x3. Solicita los valores y
# muestra el resultado.
matriz_determinante() {
    echo -e "\n${AMARILLO}DETERMINANTE DE MATRICES${RESET}"
    read -rp "Elija dimensión (2 para 2x2, 3 para 3x3): " dim
    if [[ "$dim" != "2" && "$dim" != "3" ]]; then
        echo -e "\n${ROJO}✗ Solo se permiten dimensiones 2 o 3.${RESET}"
        esperar_para_continuar
        return
    fi
    local total=$((dim * dim))
    echo "Ingrese los elementos de la matriz (fila por fila, separados por espacios):"
    read -ra mat
    if [ "${#mat[@]}" -ne "$total" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $total valores.${RESET}"
        esperar_para_continuar
        return
    fi
    local det
    if [ "$dim" -eq 2 ]; then
        local a b c d
        a=${mat[0]}; b=${mat[1]}; c=${mat[2]}; d=${mat[3]}
        det=$(awk "BEGIN { print $a*$d - $b*$c }")
    else
        # 3x3: Regla de Sarrus
        local a b c d e f g h i
        a=${mat[0]}; b=${mat[1]}; c=${mat[2]}
        d=${mat[3]}; e=${mat[4]}; f=${mat[5]}
        g=${mat[6]}; h=${mat[7]}; i=${mat[8]}
        det=$(awk "BEGIN { print $a*$e*$i + $b*$f*$g + $c*$d*$h - $c*$e*$g - $b*$d*$i - $a*$f*$h }")
    fi
    local det_f
    if [ "$PRECISION" -eq -1 ]; then
        det_f=$(awk -v d="$det" "BEGIN { printf \"%g\", d }")
    else
        det_f=$(awk -v d="$det" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", d }")
    fi
    echo -e "\n${VERDE}Determinante:${RESET} $det_f"
    agregar_historial "Determinante de matriz ${dim}x${dim} calculado: $det_f"
    esperar_para_continuar
}

# Calcula la inversa de una matriz 2x2 o 3x3. Si la matriz no es
# invertible (det=0) se muestra un mensaje de error.
matriz_inversa() {
    echo -e "\n${AMARILLO}INVERSA DE MATRICES${RESET}"
    read -rp "Elija dimensión (2 para 2x2, 3 para 3x3): " dim
    if [[ "$dim" != "2" && "$dim" != "3" ]]; then
        echo -e "\n${ROJO}✗ Solo se permiten dimensiones 2 o 3.${RESET}"
        esperar_para_continuar
        return
    fi
    local total=$((dim * dim))
    echo "Ingrese los elementos de la matriz (fila por fila, separados por espacios):"
    read -ra m
    if [ "${#m[@]}" -ne "$total" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $total valores.${RESET}"
        esperar_para_continuar
        return
    fi
    if [ "$dim" -eq 2 ]; then
        local a b c d
        a=${m[0]}; b=${m[1]}; c=${m[2]}; d=${m[3]}
        local det
        det=$(awk "BEGIN { print $a*$d - $b*$c }")
        if (( $(echo "sqrt(($det)^2) < 1e-14" | bc -l) )); then
            echo -e "\n${ROJO}✗ La matriz no es invertible (det=0).${RESET}"
            esperar_para_continuar
            return
        fi
        # Inversa: 1/det * [d -b; -c a]
        local inv=( )
        inv[0]=$(awk -v d="$d" -v det="$det" "BEGIN { print d/det }")
        inv[1]=$(awk -v b="$b" -v det="$det" "BEGIN { print -b/det }")
        inv[2]=$(awk -v c="$c" -v det="$det" "BEGIN { print -c/det }")
        inv[3]=$(awk -v a="$a" -v det="$det" "BEGIN { print a/det }")
        echo -e "\n${VERDE}Matriz inversa:${RESET}"
        local i
        for ((i=0; i<4; i++)); do
            local val=${inv[$i]}
            local fval
            if [ "$PRECISION" -eq -1 ]; then
                fval=$(awk -v v="$val" "BEGIN { printf \"%g\", v }")
            else
                fval=$(awk -v v="$val" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            printf "%s\t" "$fval"
            if [ $(( (i+1)%2 )) -eq 0 ]; then
                echo ""
            fi
        done
        agregar_historial "Inversa de matriz 2x2 calculada."
    else
        # 3x3 inversa mediante cofactores y determinante
        # Asignación de elementos
        local a b c d e f g h i
        a=${m[0]}; b=${m[1]}; c=${m[2]}
        d=${m[3]}; e=${m[4]}; f=${m[5]}
        g=${m[6]}; h=${m[7]}; i=${m[8]}
        # Calcular determinante
        local det
        det=$(awk "BEGIN { print $a*$e*$i + $b*$f*$g + $c*$d*$h - $c*$e*$g - $b*$d*$i - $a*$f*$h }")
        if (( $(echo "sqrt(($det)^2) < 1e-14" | bc -l) )); then
            echo -e "\n${ROJO}✗ La matriz no es invertible (det=0).${RESET}"
            esperar_para_continuar
            return
        fi
        # Cofactores (matriz adjunta transpuesta)
        local A00 A01 A02 A10 A11 A12 A20 A21 A22
        A00=$(awk "BEGIN { print  ($e*$i - $f*$h) }")
        A01=$(awk "BEGIN { print -($d*$i - $f*$g) }")
        A02=$(awk "BEGIN { print  ($d*$h - $e*$g) }")
        A10=$(awk "BEGIN { print -($b*$i - $c*$h) }")
        A11=$(awk "BEGIN { print  ($a*$i - $c*$g) }")
        A12=$(awk "BEGIN { print -($a*$h - $b*$g) }")
        A20=$(awk "BEGIN { print  ($b*$f - $c*$e) }")
        A21=$(awk "BEGIN { print -($a*$f - $c*$d) }")
        A22=$(awk "BEGIN { print  ($a*$e - $b*$d) }")
        # Construir matriz inversa: (1/det) * adjunta
        local inv=( )
        inv[0]=$(awk -v val="$A00" -v det="$det" "BEGIN { print val/det }")
        inv[1]=$(awk -v val="$A10" -v det="$det" "BEGIN { print val/det }")
        inv[2]=$(awk -v val="$A20" -v det="$det" "BEGIN { print val/det }")
        inv[3]=$(awk -v val="$A01" -v det="$det" "BEGIN { print val/det }")
        inv[4]=$(awk -v val="$A11" -v det="$det" "BEGIN { print val/det }")
        inv[5]=$(awk -v val="$A21" -v det="$det" "BEGIN { print val/det }")
        inv[6]=$(awk -v val="$A02" -v det="$det" "BEGIN { print val/det }")
        inv[7]=$(awk -v val="$A12" -v det="$det" "BEGIN { print val/det }")
        inv[8]=$(awk -v val="$A22" -v det="$det" "BEGIN { print val/det }")
        echo -e "\n${VERDE}Matriz inversa:${RESET}"
        for ((row=0; row<3; row++)); do
            local line=""
            for ((col=0; col<3; col++)); do
                local val=${inv[$((row*3 + col))]}
                local fval
                if [ "$PRECISION" -eq -1 ]; then
                    fval=$(awk -v v="$val" "BEGIN { printf \"%g\", v }")
                else
                    fval=$(awk -v v="$val" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
                fi
                line+="$fval\t"
            done
            echo -e "$line"
        done
        agregar_historial "Inversa de matriz 3x3 calculada."
    fi
    esperar_para_continuar
}

# Resuelve sistemas lineales 2x2 o 3x3 mediante la regla de Cramer. Pide
# coeficientes y términos independientes y calcula la solución única.
resolver_sistema() {
    echo -e "\n${AMARILLO}RESOLUCIÓN DE SISTEMAS LINEALES${RESET}"
    read -rp "Dimensión del sistema (2 o 3): " dim
    if [[ "$dim" != "2" && "$dim" != "3" ]]; then
        echo -e "\n${ROJO}✗ Solo se admiten dimensiones 2 o 3.${RESET}"
        esperar_para_continuar
        return
    fi
    local total=$((dim * dim))
    echo "Ingrese los coeficientes de la matriz A (fila por fila, separados por espacios):"
    read -ra A
    if [ "${#A[@]}" -ne "$total" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $total coeficientes.${RESET}"
        esperar_para_continuar
        return
    fi
    echo "Ingrese los términos independientes (separados por espacios):"
    read -ra b
    if [ "${#b[@]}" -ne "$dim" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $dim valores para los términos independientes.${RESET}"
        esperar_para_continuar
        return
    fi
    # Determinante principal
    local detA
    if [ "$dim" -eq 2 ]; then
        local a11=${A[0]}; a12=${A[1]}; a21=${A[2]}; a22=${A[3]}
        detA=$(awk "BEGIN { print $a11*$a22 - $a12*$a21 }")
    else
        local a11=${A[0]}; a12=${A[1]}; a13=${A[2]}
        local a21=${A[3]}; a22=${A[4]}; a23=${A[5]}
        local a31=${A[6]}; a32=${A[7]}; a33=${A[8]}
        detA=$(awk "BEGIN { print $a11*$a22*$a33 + $a12*$a23*$a31 + $a13*$a21*$a32 - $a13*$a22*$a31 - $a12*$a21*$a33 - $a11*$a23*$a32 }")
    fi
    if (( $(echo "sqrt(($detA)^2) < 1e-14" | bc -l) )); then
        echo -e "\n${ROJO}✗ El sistema no tiene solución única (det(A)=0).${RESET}"
        esperar_para_continuar
        return
    fi
    local soluciones=( )
    if [ "$dim" -eq 2 ]; then
        # Determinantes Dx y Dy
        local Dx Dy
        # Dx: reemplazar columna 1 con b
        Dx=$(awk -v b1="${b[0]}" -v b2="${b[1]}" -v a12="$a12" -v a22="$a22" "BEGIN { print b1*a22 - a12*b2 }")
        Dy=$(awk -v a11="$a11" -v a21="$a21" -v b1="${b[0]}" -v b2="${b[1]}" "BEGIN { print a11*b2 - b1*a21 }")
        local x y
        x=$(awk "BEGIN { print $Dx/$detA }")
        y=$(awk "BEGIN { print $Dy/$detA }")
        soluciones+=("$x" "$y")
    else
        # Dx, Dy, Dz para 3x3
        local Dx Dy Dz
        # Matrices con columnas reemplazadas
        # Dx: reemplazar columna 1 por b
        Dx=$(awk -v b1="${b[0]}" -v b2="${b[1]}" -v b3="${b[2]}" \
                      -v a12="$a12" -v a13="$a13" -v a22="$a22" -v a23="$a23" -v a32="$a32" -v a33="$a33" \
                      -v a12p="$a12" -v a13p="$a13" "BEGIN { print b1*$a22*$a33 + $a12*$a23*$b3 + $a13*$b2*$a32 - $a13*$a22*$b3 - $a12*$b2*$a33 - b1*$a23*$a32 }")
        # Wait; building determinants by expansions is messy; compute directly by constructing matrix columns replaced
        # We'll compute determinantes using general formula: substitute columns for b
        # For readability we compute using bc or awk loops
        # We'll build each determinant using direct substitution and then formula
        # Build matrices for Dx, Dy, Dz
        # Dx matrix columns: b, original col2, original col3
        local d11 d12 d13 d21 d22 d23 d31 d32 d33
        # Dx matrix
        d11=${b[0]}; d12=$a12; d13=$a13
        d21=${b[1]}; d22=$a22; d23=$a23
        d31=${b[2]}; d32=$a32; d33=$a33
        Dx=$(awk -v d11="$d11" -v d12="$d12" -v d13="$d13" -v d21="$d21" -v d22="$d22" -v d23="$d23" -v d31="$d31" -v d32="$d32" -v d33="$d33" \
                "BEGIN { print d11*d22*d33 + d12*d23*d31 + d13*d21*d32 - d13*d22*d31 - d12*d21*d33 - d11*d23*d32 }")
        # Dy matrix: replace column 2 with b
        d11=$a11; d12=${b[0]}; d13=$a13
        d21=$a21; d22=${b[1]}; d23=$a23
        d31=$a31; d32=${b[2]}; d33=$a33
        Dy=$(awk -v d11="$d11" -v d12="$d12" -v d13="$d13" -v d21="$d21" -v d22="$d22" -v d23="$d23" -v d31="$d31" -v d32="$d32" -v d33="$d33" \
                "BEGIN { print d11*d22*d33 + d12*d23*d31 + d13*d21*d32 - d13*d22*d31 - d12*d21*d33 - d11*d23*d32 }")
        # Dz matrix: replace column 3 with b
        d11=$a11; d12=$a12; d13=${b[0]}
        d21=$a21; d22=$a22; d23=${b[1]}
        d31=$a31; d32=$a32; d33=${b[2]}
        Dz=$(awk -v d11="$d11" -v d12="$d12" -v d13="$d13" -v d21="$d21" -v d22="$d22" -v d23="$d23" -v d31="$d31" -v d32="$d32" -v d33="$d33" \
                "BEGIN { print d11*d22*d33 + d12*d23*d31 + d13*d21*d32 - d13*d22*d31 - d12*d21*d33 - d11*d23*d32 }")
        local x y z
        x=$(awk "BEGIN { print $Dx/$detA }")
        y=$(awk "BEGIN { print $Dy/$detA }")
        z=$(awk "BEGIN { print $Dz/$detA }")
        soluciones+=("$x" "$y" "$z")
    fi
    # Mostrar soluciones
    echo -e "\n${VERDE}Solución:${RESET}"
    local labels
    if [ "$dim" -eq 2 ]; then
        labels=("x" "y")
    else
        labels=("x" "y" "z")
    fi
    for ((i=0; i<${#soluciones[@]}; i++)); do
        local val=${soluciones[$i]}
        local fval
        if [ "$PRECISION" -eq -1 ]; then
            fval=$(awk -v v="$val" "BEGIN { printf \"%g\", v }")
        else
            fval=$(awk -v v="$val" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "${labels[$i]} = $fval"
    done
    agregar_historial "Sistema ${dim}x${dim} resuelto."
    esperar_para_continuar
}

# ============================================================================
# Funciones de números complejos
# ============================================================================

# Suma de dos números complejos
complejo_sumar() {
    echo -e "\n${AMARILLO}SUMA DE NÚMEROS COMPLEJOS${RESET}"
    read -rp "Ingrese la parte real de z1: " a1
    read -rp "Ingrese la parte imaginaria de z1: " b1
    read -rp "Ingrese la parte real de z2: " a2
    read -rp "Ingrese la parte imaginaria de z2: " b2
    for v in "$a1" "$b1" "$a2" "$b2"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Error: Todos los valores deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    local real imag
    real=$(awk -v a1="$a1" -v a2="$a2" "BEGIN { print a1 + a2 }")
    imag=$(awk -v b1="$b1" -v b2="$b2" "BEGIN { print b1 + b2 }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}Resultado:${RESET} $fr + $fi i"
    agregar_historial "($a1+$b1 i) + ($a2+$b2 i) = $fr+$fi i"
    esperar_para_continuar
}

# Producto de dos números complejos
complejo_multiplicar() {
    echo -e "\n${AMARILLO}PRODUCTO DE NÚMEROS COMPLEJOS${RESET}"
    read -rp "Parte real de z1: " a1
    read -rp "Parte imaginaria de z1: " b1
    read -rp "Parte real de z2: " a2
    read -rp "Parte imaginaria de z2: " b2
    for v in "$a1" "$b1" "$a2" "$b2"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los valores deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    local real imag
    real=$(awk -v a1="$a1" -v b1="$b1" -v a2="$a2" -v b2="$b2" "BEGIN { print a1*a2 - b1*b2 }")
    imag=$(awk -v a1="$a1" -v b1="$b1" -v a2="$a2" -v b2="$b2" "BEGIN { print a1*b2 + a2*b1 }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}Resultado:${RESET} $fr + $fi i"
    agregar_historial "($a1+$b1 i) * ($a2+$b2 i) = $fr+$fi i"
    esperar_para_continuar
}

# División de dos números complejos (z1 / z2). Verifica que z2 ≠ 0.
complejo_dividir() {
    echo -e "\n${AMARILLO}DIVISIÓN DE NÚMEROS COMPLEJOS${RESET}"
    read -rp "Parte real de z1: " a1
    read -rp "Parte imaginaria de z1: " b1
    read -rp "Parte real de z2: " a2
    read -rp "Parte imaginaria de z2: " b2
    for v in "$a1" "$b1" "$a2" "$b2"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los valores deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    # Denominador c^2 + d^2
    local denom
    denom=$(awk -v a="$a2" -v b="$b2" "BEGIN { print a*a + b*b }")
    if (( $(echo "sqrt(($denom)^2) < 1e-14" | bc -l) )); then
        echo -e "\n${ROJO}✗ División por cero: z2 = 0.${RESET}"
        esperar_para_continuar
        return
    fi
    local real imag
    real=$(awk -v a1="$a1" -v b1="$b1" -v a2="$a2" -v b2="$b2" -v denom="$denom" "BEGIN { print (a1*a2 + b1*b2)/denom }")
    imag=$(awk -v a1="$a1" -v b1="$b1" -v a2="$a2" -v b2="$b2" -v denom="$denom" "BEGIN { print (b1*a2 - a1*b2)/denom }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}Resultado:${RESET} $fr + $fi i"
    agregar_historial "($a1+$b1 i) / ($a2+$b2 i) = $fr+$fi i"
    esperar_para_continuar
}

# Módulo de un número complejo
complejo_modulo() {
    echo -e "\n${AMARILLO}MÓDULO DE UN NÚMERO COMPLEJO${RESET}"
    read -rp "Parte real: " a
    read -rp "Parte imaginaria: " b
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    local mod
    mod=$(awk -v a="$a" -v b="$b" "BEGIN { print sqrt(a*a + b*b) }")
    local fmod
    if [ "$PRECISION" -eq -1 ]; then
        fmod=$(awk -v v="$mod" "BEGIN { printf \"%g\", v }")
    else
        fmod=$(awk -v v="$mod" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}|$a + ${b}i| = $fmod${RESET}"
    agregar_historial "|$a+$b i| = $fmod"
    esperar_para_continuar
}

# Argumento de un número complejo
complejo_argumento() {
    echo -e "\n${AMARILLO}ARGUMENTO DE UN NÚMERO COMPLEJO${RESET}"
    read -rp "Parte real: " a
    read -rp "Parte imaginaria: " b
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    local arg
    # atan2 retorna [-pi, pi], usamos awk
    arg=$(awk -v a="$a" -v b="$b" "BEGIN { print atan2(b,a) }")
    local farg
    if [ "$PRECISION" -eq -1 ]; then
        farg=$(awk -v v="$arg" "BEGIN { printf \"%g\", v }")
    else
        farg=$(awk -v v="$arg" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}arg($a + ${b}i) = $farg rad${RESET}"
    agregar_historial "arg($a+$b i) = $farg"
    esperar_para_continuar
}

# Conjugado de un número complejo
complejo_conjugado() {
    echo -e "\n${AMARILLO}CONJUGADO DE UN NÚMERO COMPLEJO${RESET}"
    read -rp "Parte real: " a
    read -rp "Parte imaginaria: " b
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    local fr fi
    fr=$a
    fi=$(awk -v b="$b" "BEGIN { print -b }")
    echo -e "\n${VERDE}Conjugado:${RESET} $fr + $fi i"
    agregar_historial "Conjugado de $a+$b i = $fr+$fi i"
    esperar_para_continuar
}

# Exponencial de un número complejo: e^(a+bi) = e^a (cos b + i sin b)
complejo_exponencial() {
    echo -e "\n${AMARILLO}EXPONENCIAL DE UN NÚMERO COMPLEJO${RESET}"
    read -rp "Parte real (a): " a
    read -rp "Parte imaginaria (b): " b
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    # Calcular e^a y cos b, sin b
    local ea cosb sinb
    ea=$(awk -v a="$a" "BEGIN { print exp(a) }")
    cosb=$(awk -v b="$b" "BEGIN { print cos(b) }")
    sinb=$(awk -v b="$b" "BEGIN { print sin(b) }")
    local real imag
    real=$(awk -v ea="$ea" -v cosb="$cosb" "BEGIN { print ea*cosb }")
    imag=$(awk -v ea="$ea" -v sinb="$sinb" "BEGIN { print ea*sinb }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}e^($a + ${b}i) = $fr + $fi i${RESET}"
    agregar_historial "exp($a+$b i) = $fr+$fi i"
    esperar_para_continuar
}

# Logaritmo natural de un número complejo: ln(z) = ln|z| + i arg(z)
complejo_logaritmo() {
    echo -e "\n${AMARILLO}LOGARITMO NATURAL DE UN NÚMERO COMPLEJO${RESET}"
    read -rp "Parte real: " a
    read -rp "Parte imaginaria: " b
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar números reales.${RESET}"
        esperar_para_continuar
        return
    fi
    local mod arg lnmod
    mod=$(awk -v a="$a" -v b="$b" "BEGIN { print sqrt(a*a + b*b) }")
    lnmod=$(awk -v m="$mod" "BEGIN { print log(m) }")
    arg=$(awk -v a="$a" -v b="$b" "BEGIN { print atan2(b,a) }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$lnmod" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$arg" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$lnmod" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$arg" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}ln($a + ${b}i) = $fr + $fi i${RESET}"
    agregar_historial "ln($a+$b i) = $fr+$fi i"
    esperar_para_continuar
}

# Potencia de número complejo: z^w = e^{w ln(z)} donde z = a+bi y w = c+di
complejo_potencia() {
    echo -e "\n${AMARILLO}POTENCIA COMPLEJA z^w${RESET}"
    echo "Ingrese z = a + bi"
    read -rp "a (parte real de z): " a
    read -rp "b (parte imaginaria de z): " b
    echo "Ingrese w = c + di"
    read -rp "c (parte real de w): " c
    read -rp "d (parte imaginaria de w): " d
    # Validaciones
    for v in "$a" "$b" "$c" "$d"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los valores deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    # Calcular ln(z)
    local mod arg lnmod
    mod=$(awk -v a="$a" -v b="$b" "BEGIN { print sqrt(a*a + b*b) }")
    if (( $(echo "sqrt(($mod)^2) < 1e-14" | bc -l) )); then
        if (( $(echo "sqrt(($c)^2 + ($d)^2) < 1e-14" | bc -l) )); then
            echo -e "\n${VERDE}z^w = 1${RESET} (0^0 interpretado como 1)"
            agregar_historial "($a+$b i)^($c+$d i) = 1 (por definición)"
            esperar_para_continuar
            return
        else
            echo -e "\n${ROJO}✗ 0 elevado a potencia no trivial es indefinido.${RESET}"
            esperar_para_continuar
            return
        fi
    fi
    lnmod=$(awk -v m="$mod" "BEGIN { print log(m) }")
    arg=$(awk -v a="$a" -v b="$b" "BEGIN { print atan2(b,a) }")
    # w ln(z) = (c+di)*(lnmod + i arg) = (c*lnmod - d*arg) + i(d*lnmod + c*arg)
    local A B
    A=$(awk -v c="$c" -v d="$d" -v lnmod="$lnmod" -v arg="$arg" "BEGIN { print c*lnmod - d*arg }")
    B=$(awk -v c="$c" -v d="$d" -v lnmod="$lnmod" -v arg="$arg" "BEGIN { print d*lnmod + c*arg }")
    # e^{A + iB} = e^A (cos B + i sin B)
    local ea cosB sinB
    ea=$(awk -v A="$A" "BEGIN { print exp(A) }")
    cosB=$(awk -v B="$B" "BEGIN { print cos(B) }")
    sinB=$(awk -v B="$B" "BEGIN { print sin(B) }")
    local real imag
    real=$(awk -v ea="$ea" -v cosB="$cosB" "BEGIN { print ea*cosB }")
    imag=$(awk -v ea="$ea" -v sinB="$sinB" "BEGIN { print ea*sinB }")
    local fr fi
    if [ "$PRECISION" -eq -1 ]; then
        fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
        fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
    else
        fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}($a + ${b}i)^($c + ${d}i) = $fr + $fi i${RESET}"
    agregar_historial "($a+$b i)^($c+$d i) = $fr+$fi i"
    esperar_para_continuar
}

# ============================================================================
# Funciones de simulación cuántica
# ============================================================================

# Aplica una puerta de un único qubit a un estado (a+bi, c+di). Soporta
# Pauli-X, Pauli-Y, Pauli-Z, Hadamard, fase S, fase T y rotaciones Rx, Ry, Rz.
quantum_single() {
    echo -e "\n${AMARILLO}SIMULADOR DE UN QUBIT${RESET}"
    echo "Ingrese el estado inicial (α |0> + β |1>) como partes reales e imaginarias."
    read -rp "Re(α): " ra
    read -rp "Im(α): " ia
    read -rp "Re(β): " rb
    read -rp "Im(β): " ib
    for v in "$ra" "$ia" "$rb" "$ib"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los coeficientes deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    echo "Seleccione la puerta a aplicar:"
    echo " 1) Pauli-X"
    echo " 2) Pauli-Y"
    echo " 3) Pauli-Z"
    echo " 4) Hadamard"
    echo " 5) Fase S (π/2)"
    echo " 6) Fase T (π/4)"
    echo " 7) Rotación Rx(θ)"
    echo " 8) Rotación Ry(θ)"
    echo " 9) Rotación Rz(θ)"
    read -rp "Opción: " gate
    # Variables para resultado
    local a0r a0i a1r a1i
    a0r="$ra"; a0i="$ia"; a1r="$rb"; a1i="$ib"
    case "$gate" in
        1) # X gate: |0>↦|1>, |1>↦|0>
            local t0r t0i
            t0r="$a0r"; t0i="$a0i"
            a0r="$a1r"; a0i="$a1i"
            a1r="$t0r"; a1i="$t0i"
            ;;
        2) # Y gate: [0 -i; i 0]
            # α' = -i β = -(i)(β_r + i β_i) = β_i - i β_r
            # β' = i α = i(a_r + i a_i) = -a_i + i a_r
            local na0r na0i na1r na1i
            na0r=$(awk -v br="$a1r" -v bi="$a1i" "BEGIN { print bi }")
            na0i=$(awk -v br="$a1r" -v bi="$a1i" "BEGIN { print -br }")
            na1r=$(awk -v ar="$a0r" -v ai="$a0i" "BEGIN { print -ai }")
            na1i=$(awk -v ar="$a0r" -v ai="$a0i" "BEGIN { print ar }")
            a0r="$na0r"; a0i="$na0i"; a1r="$na1r"; a1i="$na1i"
            ;;
        3) # Z gate: [1 0; 0 -1]
            a1r=$(awk -v br="$a1r" "BEGIN { print -br }")
            a1i=$(awk -v bi="$a1i" "BEGIN { print -bi }")
            ;;
        4) # Hadamard: 1/sqrt2 [1  1; 1 -1]
            local invsqrt2
            invsqrt2=$(awk "BEGIN { print 1/sqrt(2) }")
            local na0r na0i na1r na1i
            # α' = (α + β)/√2
            na0r=$(awk -v ar="$a0r" -v br="$a1r" -v inv="$invsqrt2" "BEGIN { print (ar + br)*inv }")
            na0i=$(awk -v ai="$a0i" -v bi="$a1i" -v inv="$invsqrt2" "BEGIN { print (ai + bi)*inv }")
            # β' = (α - β)/√2
            na1r=$(awk -v ar="$a0r" -v br="$a1r" -v inv="$invsqrt2" "BEGIN { print (ar - br)*inv }")
            na1i=$(awk -v ai="$a0i" -v bi="$a1i" -v inv="$invsqrt2" "BEGIN { print (ai - bi)*inv }")
            a0r="$na0r"; a0i="$na0i"; a1r="$na1r"; a1i="$na1i"
            ;;
        5) # S gate: [1 0; 0 i]
            local nb1r nb1i
            nb1r=$(awk -v br="$a1r" -v bi="$a1i" "BEGIN { print -bi }")
            nb1i=$(awk -v br="$a1r" -v bi="$a1i" "BEGIN { print br }")
            a1r="$nb1r"; a1i="$nb1i"
            ;;
        6) # T gate: [1 0; 0 e^{iπ/4}] = [1 0; 0 (cos π/4 + i sin π/4)]
            local cosT sinT
            cosT=$(awk "BEGIN { print cos(0.7853981633974483) }")
            sinT=$(awk "BEGIN { print sin(0.7853981633974483) }")
            # Multiply β by cosT + i sinT
            local nb1r nb1i
            nb1r=$(awk -v br="$a1r" -v bi="$a1i" -v cosT="$cosT" -v sinT="$sinT" "BEGIN { print br*cosT - bi*sinT }")
            nb1i=$(awk -v br="$a1r" -v bi="$a1i" -v cosT="$cosT" -v sinT="$sinT" "BEGIN { print br*sinT + bi*cosT }")
            a1r="$nb1r"; a1i="$nb1i"
            ;;
        7|8|9)
            # Rotación Rx,Ry,Rz: se requiere un ángulo
            read -rp "Ingrese ángulo θ en radianes: " theta
            if [[ ! "$theta" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "\n${ROJO}✗ El ángulo debe ser un número real.${RESET}"
                esperar_para_continuar
                return
            fi
            local half
            half=$(awk -v th="$theta" "BEGIN { print th/2 }")
            local cosh sinh
            # For Rx: U = cos(θ/2) I - i sin(θ/2) X
            if [ "$gate" -eq 7 ]; then
                cosh=$(awk -v h="$half" "BEGIN { print cos(h) }")
                sinh=$(awk -v h="$half" "BEGIN { print sin(h) }")
                # α' = cos(θ/2)*α - i sin(θ/2)*β
                # β' = cos(θ/2)*β - i sin(θ/2)*α
                local na0r na0i na1r na1i
                # For α': multiply β by -i*sin(θ/2) -> -i*(β_r + i β_i) = β_i - i β_r times sin value
                na0r=$(awk -v ar="$a0r" -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ar + s*bi }")
                na0i=$(awk -v ai="$a0i" -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ai - s*br }")
                na1r=$(awk -v br="$a1r" -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*br + s*ai }")
                na1i=$(awk -v bi="$a1i" -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*bi - s*ar }")
                a0r="$na0r"; a0i="$na0i"; a1r="$na1r"; a1i="$na1i"
            elif [ "$gate" -eq 8 ]; then
                # Ry: cos(θ/2) I - i sin(θ/2) Y
                cosh=$(awk -v h="$half" "BEGIN { print cos(h) }")
                sinh=$(awk -v h="$half" "BEGIN { print sin(h) }")
                # α' = cos*h α - i sin*h ( -i β ) = cos*α - sin*( iβ ) = cos*α - i sin*β_i + sin*β_r ??? Wait.
                # We'll derive: U = cos(h)*I - i sin(h)*Y. Y = [[0,-i],[i,0]]. So -i sin(h)*Y = -i sin(h) * Y.
                # Multiply β by -i sin(h)*Y:
                # Y acting on (α,β): α' = -i sin(h) * (-i β) + cos(h)*α = sin(h)*β + cos(h)*α
                # β' = -i sin(h) * (i α) + cos(h)*β = -sin(h)*α + cos(h)*β
                local na0r na0i na1r na1i
                na0r=$(awk -v ar="$a0r" -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ar + s*br }")
                na0i=$(awk -v ai="$a0i" -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ai + s*bi }")
                na1r=$(awk -v br="$a1r" -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*br - s*ar }")
                na1i=$(awk -v bi="$a1i" -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*bi - s*ai }")
                a0r="$na0r"; a0i="$na0i"; a1r="$na1r"; a1i="$na1i"
            else
                # Rz: cos(θ/2) I - i sin(θ/2) Z -> acts as phase
                cosh=$(awk -v h="$half" "BEGIN { print cos(h) }")
                sinh=$(awk -v h="$half" "BEGIN { print sin(h) }")
                # α' = (cos(h) - i sin(h)) α; β' = (cos(h) + i sin(h)) β
                local na0r na0i na1r na1i
                na0r=$(awk -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ar + s*ai }")
                na0i=$(awk -v ar="$a0r" -v ai="$a0i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*ai - s*ar }")
                na1r=$(awk -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*br - s*bi }")
                na1i=$(awk -v br="$a1r" -v bi="$a1i" -v c="$cosh" -v s="$sinh" "BEGIN { return c*bi + s*br }")
                a0r="$na0r"; a0i="$na0i"; a1r="$na1r"; a1i="$na1i"
            fi
            ;;
        *)
            echo -e "\n${ROJO}✗ Opción no válida.${RESET}"
            esperar_para_continuar
            return
            ;;
    esac
    # Mostrar resultado
    local out0r out0i out1r out1i
    if [ "$PRECISION" -eq -1 ]; then
        out0r=$(awk -v v="$a0r" "BEGIN { printf \"%g\", v }")
        out0i=$(awk -v v="$a0i" "BEGIN { printf \"%g\", v }")
        out1r=$(awk -v v="$a1r" "BEGIN { printf \"%g\", v }")
        out1i=$(awk -v v="$a1i" "BEGIN { printf \"%g\", v }")
    else
        out0r=$(awk -v v="$a0r" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        out0i=$(awk -v v="$a0i" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        out1r=$(awk -v v="$a1r" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        out1i=$(awk -v v="$a1i" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}Estado resultante:${RESET}"
    echo -e "α' = $out0r + $out0i i"
    echo -e "β' = $out1r + $out1i i"
    agregar_historial "Puerta un qubit aplicada, nuevo estado: α'=$out0r+$out0i i, β'=$out1r+$out1i i"
    esperar_para_continuar
}

# Simulación de dos qubits con puertas de uno o dos qubits (CNOT, SWAP). El
# estado se representa como (ψ00, ψ01, ψ10, ψ11). Para simplicidad se
# permiten solo puertas X,Y,Z,H,S,T en cada qubit y CNOT.
quantum_two() {
    echo -e "\n${AMARILLO}SIMULADOR DE DOS QUBITS${RESET}"
    echo "Ingrese el estado inicial como cuatro pares (Re, Im) para |00>, |01>, |10>, |11>:"
    local reals=() imags=()
    for basis in "|00>" "|01>" "|10>" "|11>"; do
        read -rp "Re $basis: " r
        read -rp "Im $basis: " i
        if [[ ! "$r" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$i" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los valores deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
        reals+=("$r"); imags+=("$i")
    done
    echo "Seleccione la operación:"
    echo " 1) Puerta en qubit 1 (más significativo)"
    echo " 2) Puerta en qubit 2 (menos significativo)"
    echo " 3) CNOT (control=1, target=2)"
    echo " 4) CNOT (control=2, target=1)"
    echo " 5) SWAP"
    read -rp "Opción: " op
    if [[ "$op" == "1" || "$op" == "2" ]]; then
        local target
        if [ "$op" -eq 1 ]; then
            target=1
        else
            target=2
        fi
        echo "Seleccione la puerta para el qubit $target:"
        echo " 1) X"
        echo " 2) Y"
        echo " 3) Z"
        echo " 4) H"
        echo " 5) S"
        echo " 6) T"
        read -rp "Puerta: " g
        # Aplica la puerta a cada par de amplitudes correspondientes al qubit seleccionado
        # Indices: para qubit1 (msb) actúa sobre pares (0,2) y (1,3). Para qubit2 actúa sobre (0,1) y (2,3).
        local pairs=()
        if [ "$target" -eq 1 ]; then
            pairs=("0 2" "1 3")
        else
            pairs=("0 1" "2 3")
        fi
        local idx
        for pr in "${pairs[@]}"; do
            set -- $pr
            local i1=$1; local i2=$2
            local ar0=${reals[$i1]}; local ai0=${imags[$i1]}
            local ar1=${reals[$i2]}; local ai1=${imags[$i2]}
            # aplicar como en qubit único
            case "$g" in
                1) # X
                    # swap
                    local tmp_r tmp_i
                    tmp_r="$ar0"; tmp_i="$ai0"
                    ar0="$ar1"; ai0="$ai1"
                    ar1="$tmp_r"; ai1="$tmp_i"
                    ;;
                2) # Y
                    # α' = β_i - i β_r; β' = -α_i + i α_r
                    local na0r na0i na1r na1i
                    na0r=$(awk -v br="$ar1" -v bi="$ai1" "BEGIN { print bi }")
                    na0i=$(awk -v br="$ar1" -v bi="$ai1" "BEGIN { print -br }")
                    na1r=$(awk -v ar="$ar0" -v ai="$ai0" "BEGIN { print -ai }")
                    na1i=$(awk -v ar="$ar0" -v ai="$ai0" "BEGIN { print ar }")
                    ar0="$na0r"; ai0="$na0i"; ar1="$na1r"; ai1="$na1i"
                    ;;
                3) # Z
                    ar1=$(awk -v v="$ar1" "BEGIN { print -v }")
                    ai1=$(awk -v v="$ai1" "BEGIN { print -v }")
                    ;;
                4) # H
                    local invsqrt2
                    invsqrt2=$(awk "BEGIN { print 1/sqrt(2) }")
                    local na0r na0i na1r na1i
                    na0r=$(awk -v ar0="$ar0" -v ar1="$ar1" -v inv="$invsqrt2" "BEGIN { print (ar0 + ar1)*inv }")
                    na0i=$(awk -v ai0="$ai0" -v ai1="$ai1" -v inv="$invsqrt2" "BEGIN { print (ai0 + ai1)*inv }")
                    na1r=$(awk -v ar0="$ar0" -v ar1="$ar1" -v inv="$invsqrt2" "BEGIN { print (ar0 - ar1)*inv }")
                    na1i=$(awk -v ai0="$ai0" -v ai1="$ai1" -v inv="$invsqrt2" "BEGIN { print (ai0 - ai1)*inv }")
                    ar0="$na0r"; ai0="$na0i"; ar1="$na1r"; ai1="$na1i"
                    ;;
                5) # S
                    # multiply second amplitude by i
                    local nb1r nb1i
                    nb1r=$(awk -v br="$ar1" -v bi="$ai1" "BEGIN { print -bi }")
                    nb1i=$(awk -v br="$ar1" -v bi="$ai1" "BEGIN { print br }")
                    ar1="$nb1r"; ai1="$nb1i"
                    ;;
                6) # T
                    local cosT sinT
                    cosT=$(awk "BEGIN { print cos(0.7853981633974483) }")
                    sinT=$(awk "BEGIN { print sin(0.7853981633974483) }")
                    local nb1r nb1i
                    nb1r=$(awk -v br="$ar1" -v bi="$ai1" -v cosT="$cosT" -v sinT="$sinT" "BEGIN { print br*cosT - bi*sinT }")
                    nb1i=$(awk -v br="$ar1" -v bi="$ai1" -v cosT="$cosT" -v sinT="$sinT" "BEGIN { print br*sinT + bi*cosT }")
                    ar1="$nb1r"; ai1="$nb1i"
                    ;;
                *)
                    echo -e "\n${ROJO}✗ Puerta no válida.${RESET}"
                    esperar_para_continuar
                    return
                    ;;
            esac
            # Actualizar los arreglos globales
            reals[$i1]="$ar0"; imags[$i1]="$ai0"; reals[$i2]="$ar1"; imags[$i2]="$ai1"
        done
        echo -e "\n${VERDE}Estado resultante:${RESET}"
        local basis_labels=("|00>" "|01>" "|10>" "|11>")
        for ((idx=0; idx<4; idx++)); do
            local rr=${reals[$idx]}; local ii=${imags[$idx]}
            local fr fi
            if [ "$PRECISION" -eq -1 ]; then
                fr=$(awk -v v="$rr" "BEGIN { printf \"%g\", v }")
                fi=$(awk -v v="$ii" "BEGIN { printf \"%g\", v }")
            else
                fr=$(awk -v v="$rr" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
                fi=$(awk -v v="$ii" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            printf "%s: %s + %s i\n" "${basis_labels[$idx]}" "$fr" "$fi"
        done
        agregar_historial "Dos qubits: puerta aplicada en qubit $target"
        esperar_para_continuar
        return
    elif [ "$op" -eq 3 ] || [ "$op" -eq 4 ]; then
        # CNOT
        local control target
        if [ "$op" -eq 3 ]; then
            control=1; target=2
        else
            control=2; target=1
        fi
        # Represent the indices; if control bit is 1, swap amplitudes of target qubit
        # For two qubits: indices 0:00,1:01,2:10,3:11 (bits: [q1 q2])
        local newR=("${reals[@]}"); local newI=("${imags[@]}")
        if [ "$control" -eq 1 ]; then
            # control=qubit1 (msb): when msb=1, swap states for q2
            # i.e., swap index2 (10) with index3 (11)
            newR[2]="${reals[3]}"; newI[2]="${imags[3]}"
            newR[3]="${reals[2]}"; newI[3]="${imags[2]}"
        else
            # control=qubit2 (lsb): when lsb=1, swap states for q1
            # swap index1 (01) with index3 (11)
            newR[1]="${reals[3]}"; newI[1]="${imags[3]}"
            newR[3]="${reals[1]}"; newI[3]="${imags[1]}"
        fi
        reals=("${newR[@]}"); imags=("${newI[@]}")
        echo -e "\n${VERDE}Estado resultante tras CNOT:${RESET}"
        local labels=("|00>" "|01>" "|10>" "|11>")
        for ((idx=0; idx<4; idx++)); do
            local fr fi
            if [ "$PRECISION" -eq -1 ]; then
                fr=$(awk -v v="${reals[$idx]}" "BEGIN { printf \"%g\", v }")
                fi=$(awk -v v="${imags[$idx]}" "BEGIN { printf \"%g\", v }")
            else
                fr=$(awk -v v="${reals[$idx]}" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
                fi=$(awk -v v="${imags[$idx]}" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            printf "%s: %s + %s i\n" "${labels[$idx]}" "$fr" "$fi"
        done
        agregar_historial "Dos qubits: CNOT control=$control, target=$target"
        esperar_para_continuar
        return
    elif [ "$op" -eq 5 ]; then
        # SWAP qubits: swap |01> with |10>
        local tmpR tmpI
        tmpR="${reals[1]}"; tmpI="${imags[1]}"
        reals[1]="${reals[2]}"; imags[1]="${imags[2]}"
        reals[2]="$tmpR"; imags[2]="$tmpI"
        echo -e "\n${VERDE}Estado resultante tras SWAP:${RESET}"
        local labels=("|00>" "|01>" "|10>" "|11>")
        for ((idx=0; idx<4; idx++)); do
            local fr fi
            if [ "$PRECISION" -eq -1 ]; then
                fr=$(awk -v v="${reals[$idx]}" "BEGIN { printf \"%g\", v }")
                fi=$(awk -v v="${imags[$idx]}" "BEGIN { printf \"%g\", v }")
            else
                fr=$(awk -v v="${reals[$idx]}" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
                fi=$(awk -v v="${imags[$idx]}" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            printf "%s: %s + %s i\n" "${labels[$idx]}" "$fr" "$fi"
        done
        agregar_historial "Dos qubits: SWAP"
        esperar_para_continuar
        return
    else
        echo -e "\n${ROJO}✗ Opción no válida.${RESET}"
        esperar_para_continuar
        return
    fi
}

# Muestra probabilidades de cada base state dado un conjunto de amplitudes
quantum_medicion() {
    echo -e "\n${AMARILLO}PROBABILIDADES DE ESTADO CUÁNTICO${RESET}"
    echo "Esta función calcula la probabilidad de cada estado base dado un vector de amplitudes."
    echo "Indique el número de qubits (1 o 2):"
    read -rp "N: " n
    if [[ "$n" != "1" && "$n" != "2" ]]; then
        echo -e "\n${ROJO}✗ Solo se soportan 1 o 2 qubits para esta medición.${RESET}"
        esperar_para_continuar
        return
    fi
    if [ "$n" -eq 1 ]; then
        read -rp "Re(α): " a0r
        read -rp "Im(α): " a0i
        read -rp "Re(β): " a1r
        read -rp "Im(β): " a1i
        for v in "$a0r" "$a0i" "$a1r" "$a1i"; do
            if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "\n${ROJO}✗ Todos los valores deben ser reales.${RESET}"
                esperar_para_continuar
                return
            fi
        done
        local p0 p1
        p0=$(awk -v ar="$a0r" -v ai="$a0i" "BEGIN { print ar*ar + ai*ai }")
        p1=$(awk -v br="$a1r" -v bi="$a1i" "BEGIN { print br*br + bi*bi }")
        # Normalizar si sum != 1
        local sum
        sum=$(awk -v p0="$p0" -v p1="$p1" "BEGIN { print p0+p1 }")
        if (( $(echo "sqrt(($sum-1)^2) > 1e-6" | bc -l) )); then
            # renormalizar
            p0=$(awk -v p="$p0" -v s="$sum" "BEGIN { print p/s }")
            p1=$(awk -v p="$p1" -v s="$sum" "BEGIN { print p/s }")
        fi
        local fp0 fp1
        if [ "$PRECISION" -eq -1 ]; then
            fp0=$(awk -v v="$p0" "BEGIN { printf \"%g\", v }")
            fp1=$(awk -v v="$p1" "BEGIN { printf \"%g\", v }")
        else
            fp0=$(awk -v v="$p0" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fp1=$(awk -v v="$p1" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "\n${VERDE}Probabilidad |0> = $fp0${RESET}"
        echo -e "${VERDE}Probabilidad |1> = $fp1${RESET}"
        agregar_historial "Medición 1 qubit: p(|0>)=$fp0, p(|1>)=$fp1"
    else
        local basis=("|00>" "|01>" "|10>" "|11>")
        local reals=() imags=()
        for b in "${basis[@]}"; do
            read -rp "Re($b): " r
            read -rp "Im($b): " i
            if [[ ! "$r" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$i" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "\n${ROJO}✗ Todos los valores deben ser reales.${RESET}"
                esperar_para_continuar
                return
            fi
            reals+=("$r"); imags+=("$i")
        done
        local probs=( )
        local sum=0
        local idx
        for ((idx=0; idx<4; idx++)); do
            local p
            p=$(awk -v r="${reals[$idx]}" -v i="${imags[$idx]}" "BEGIN { print r*r + i*i }")
            probs+=("$p")
            sum=$(awk -v s="$sum" -v p="$p" "BEGIN { print s+p }")
        done
        echo -e "\n${VERDE}Probabilidades:${RESET}"
        for ((idx=0; idx<4; idx++)); do
            local prob=${probs[$idx]}
            if (( $(echo "sqrt(($sum-1)^2) > 1e-6" | bc -l) )); then
                prob=$(awk -v p="$prob" -v s="$sum" "BEGIN { print p/s }")
            fi
            local fp
            if [ "$PRECISION" -eq -1 ]; then
                fp=$(awk -v v="$prob" "BEGIN { printf \"%g\", v }")
            else
                fp=$(awk -v v="$prob" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi
            printf "%s: %s\n" "${basis[$idx]}" "$fp"
        done
        agregar_historial "Medición 2 qubits realizada"
    fi
    esperar_para_continuar
}

# ============================================================================
# Funciones de cálculo: integración, derivación y EDO
# ============================================================================

# Integración numérica por regla del trapecio o Simpson. Pide una expresión
# f(x), límites de integración y número de subintervalos. Para Simpson el
# número debe ser par.
integracion_numerica() {
    echo -e "\n${AMARILLO}INTEGRACIÓN NUMÉRICA${RESET}"
    echo "Ingrese la función f(x) a integrar (por ejemplo sin(x) + x^2):"
    read -rp "f(x) = " expr
    read -rp "Límite inferior a: " a
    read -rp "Límite superior b: " b
    read -rp "Número de subintervalos n: " n
    echo "Seleccione el método: 1) Trapecio  2) Simpson"
    read -rp "Método: " metodo
    if [[ ! "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$b" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$n" =~ ^[0-9]+$ ]]; then
        echo -e "\n${ROJO}✗ Los límites deben ser numéricos y n un entero positivo.${RESET}"
        esperar_para_continuar
        return
    fi
    if (( n <= 0 )); then
        echo -e "\n${ROJO}✗ n debe ser mayor que cero.${RESET}"
        esperar_para_continuar
        return
    fi
    local h
    h=$(awk -v a="$a" -v b="$b" -v n="$n" "BEGIN { print (b-a)/n }")
    local sum
    sum=0
    if [ "$metodo" -eq 1 ]; then
        # Método del trapecio
        # sum = 0.5*f(a) + sum_{i=1}^{n-1} f(a+i*h) + 0.5*f(b)
        local i
        for ((i=0; i<=n; i++)); do
            local x
            x=$(awk -v a="$a" -v h="$h" -v i="$i" "BEGIN { print a + i*h }")
            local fx
            fx=$(awk -v x="$x" "BEGIN { print $expr }")
            if [ $i -eq 0 ] || [ $i -eq $n ]; then
                sum=$(awk -v s="$sum" -v fx="$fx" "BEGIN { print s + 0.5*fx }")
            else
                sum=$(awk -v s="$sum" -v fx="$fx" "BEGIN { print s + fx }")
            fi
        done
        local integral
        integral=$(awk -v h="$h" -v sum="$sum" "BEGIN { print h*sum }")
        local fint
        if [ "$PRECISION" -eq -1 ]; then
            fint=$(awk -v v="$integral" "BEGIN { printf \"%g\", v }")
        else
            fint=$(awk -v v="$integral" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "\n${VERDE}∫_${a}^${b} f(x) dx ≈ $fint${RESET} (Trapecio)"
        agregar_historial "Trapecio: ∫[$a,$b] ≈ $fint"
    elif [ "$metodo" -eq 2 ]; then
        if (( n % 2 != 0 )); then
            echo -e "\n${ROJO}✗ n debe ser par para Simpson.${RESET}"
            esperar_para_continuar
            return
        fi
        local i
        for ((i=0; i<=n; i++)); do
            local x
            x=$(awk -v a="$a" -v h="$h" -v i="$i" "BEGIN { print a + i*h }")
            local fx
            fx=$(awk -v x="$x" "BEGIN { print $expr }")
            if [ $i -eq 0 ] || [ $i -eq $n ]; then
                sum=$(awk -v s="$sum" -v fx="$fx" "BEGIN { print s + fx }")
            elif (( i % 2 == 1 )); then
                sum=$(awk -v s="$sum" -v fx="$fx" "BEGIN { print s + 4*fx }")
            else
                sum=$(awk -v s="$sum" -v fx="$fx" "BEGIN { print s + 2*fx }")
            fi
        done
        local integral
        integral=$(awk -v h="$h" -v sum="$sum" "BEGIN { print (h/3)*sum }")
        local fint
        if [ "$PRECISION" -eq -1 ]; then
            fint=$(awk -v v="$integral" "BEGIN { printf \"%g\", v }")
        else
            fint=$(awk -v v="$integral" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "\n${VERDE}∫_${a}^${b} f(x) dx ≈ $fint${RESET} (Simpson)"
        agregar_historial "Simpson: ∫[$a,$b] ≈ $fint"
    else
        echo -e "\n${ROJO}✗ Método no válido.${RESET}"
    fi
    esperar_para_continuar
}

# Derivación numérica de primer o segundo orden usando fórmula de diferencias
# centradas. Solicita f(x), punto x0, y paso h.
derivada_numerica() {
    echo -e "\n${AMARILLO}DERIVADA NUMÉRICA${RESET}"
    echo "Ingrese la función f(x) a derivar:"
    read -rp "f(x) = " expr
    read -rp "Punto x0: " x0
    read -rp "Paso h: " h
    echo "Elija el orden de la derivada: 1) Primera  2) Segunda"
    read -rp "Orden: " orden
    if [[ ! "$x0" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$h" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "\n${ROJO}✗ x0 y h deben ser valores numéricos, con h>0.${RESET}"
        esperar_para_continuar
        return
    fi
    if (( $(echo "$h <= 0" | bc -l) )); then
        echo -e "\n${ROJO}✗ h debe ser mayor que 0.${RESET}"
        esperar_para_continuar
        return
    fi
    local deriv
    if [ "$orden" -eq 1 ]; then
        # f'(x0) ≈ [f(x0+h) - f(x0-h)] / (2h)
        local xph xmh fph fmh
        xph=$(awk -v x="$x0" -v h="$h" "BEGIN { print x + h }")
        xmh=$(awk -v x="$x0" -v h="$h" "BEGIN { print x - h }")
        fph=$(awk -v x="$xph" "BEGIN { print $expr }")
        fmh=$(awk -v x="$xmh" "BEGIN { print $expr }")
        deriv=$(awk -v fph="$fph" -v fmh="$fmh" -v h="$h" "BEGIN { print (fph - fmh)/(2*h) }")
        local dval
        if [ "$PRECISION" -eq -1 ]; then
            dval=$(awk -v v="$deriv" "BEGIN { printf \"%g\", v }")
        else
            dval=$(awk -v v="$deriv" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "\n${VERDE}f'($x0) ≈ $dval${RESET}"
        agregar_historial "Derivada 1ª: f'($x0) ≈ $dval"
    elif [ "$orden" -eq 2 ]; then
        # f''(x0) ≈ [f(x0+h) - 2f(x0) + f(x0-h)] / h^2
        local xph x0_f xmh fph f0 fmh
        xph=$(awk -v x="$x0" -v h="$h" "BEGIN { print x + h }")
        xmh=$(awk -v x="$x0" -v h="$h" "BEGIN { print x - h }")
        fph=$(awk -v x="$xph" "BEGIN { print $expr }")
        fmh=$(awk -v x="$xmh" "BEGIN { print $expr }")
        f0=$(awk -v x="$x0" "BEGIN { print $expr }")
        deriv=$(awk -v fph="$fph" -v f0="$f0" -v fmh="$fmh" -v h="$h" "BEGIN { print (fph - 2*f0 + fmh)/(h*h) }")
        local dval
        if [ "$PRECISION" -eq -1 ]; then
            dval=$(awk -v v="$deriv" "BEGIN { printf \"%g\", v }")
        else
            dval=$(awk -v v="$deriv" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "\n${VERDE}f''($x0) ≈ $dval${RESET}"
        agregar_historial "Derivada 2ª: f''($x0) ≈ $dval"
    else
        echo -e "\n${ROJO}✗ Orden no válido. Solo 1 o 2.${RESET}"
    fi
    esperar_para_continuar
}

# Resuelve una ecuación diferencial ordinaria de primer orden y'=f(x,y)
# mediante el método de Euler. Pide f(x,y), intervalo, paso y valor inicial.
resolver_ode() {
    echo -e "\n${AMARILLO}SOLUCIÓN DE EDO PRIMER ORDEN (MÉTODO DE EULER)${RESET}"
    echo "Ingrese la función f(x,y) de la forma dy/dx = f(x,y). Use variables 'x' y 'y'."
    read -rp "f(x,y) = " expr
    read -rp "x0 (inicio del intervalo): " x0
    read -rp "y0 (valor inicial): " y0
    read -rp "x_final: " xf
    read -rp "Número de pasos n: " n
    if [[ ! "$x0" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$y0" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$xf" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || [[ ! "$n" =~ ^[0-9]+$ ]]; then
        echo -e "\n${ROJO}✗ Todos los parámetros deben ser numéricos, con n entero.${RESET}"
        esperar_para_continuar
        return
    fi
    if (( n <= 0 )); then
        echo -e "\n${ROJO}✗ n debe ser mayor que cero.${RESET}"
        esperar_para_continuar
        return
    fi
    # Paso h
    local h
    h=$(awk -v x0="$x0" -v xf="$xf" -v n="$n" "BEGIN { print (xf-x0)/n }")
    local x="$x0" y="$y0"
    echo -e "\n${VERDE}Resultados aproximados:${RESET}"
    echo -e "Paso\t x\t y"
    local i
    for ((i=0; i<=n; i++)); do
        # Formatear y
        local fy
        if [ "$PRECISION" -eq -1 ]; then
            fy=$(awk -v v="$y" "BEGIN { printf \"%g\", v }")
        else
            fy=$(awk -v v="$y" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        local fx
        if [ "$PRECISION" -eq -1 ]; then
            fx=$(awk -v v="$x" "BEGIN { printf \"%g\", v }")
        else
            fx=$(awk -v v="$x" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        printf "%d\t %s\t %s\n" "$i" "$fx" "$fy"
        if [ $i -lt $n ]; then
            # Calcular derivada en (x,y)
            local deriv
            deriv=$(awk -v x="$x" -v y="$y" "BEGIN { print $expr }")
            # Euler: y_{n+1} = y_n + h*f(x_n,y_n)
            local ynew
            ynew=$(awk -v y="$y" -v h="$h" -v d="$deriv" "BEGIN { print y + h*d }")
            x=$(awk -v x="$x" -v h="$h" "BEGIN { print x + h }")
            y="$ynew"
        fi
    done
    agregar_historial "EDO: solución aproximada de y'=$expr desde x=$x0 a $xf"
    esperar_para_continuar
}

# ============================================================================
# Funciones de estadística y combinatoria
# ============================================================================

# Calcula estadísticas descriptivas: media, mediana, moda, varianza y desviación estándar.
estadisticas() {
    echo -e "\n${AMARILLO}ESTADÍSTICAS DESCRIPTIVAS${RESET}"
    echo "Ingrese una lista de números separados por espacios:"
    read -ra datos
    if [ ${#datos[@]} -eq 0 ]; then
        echo -e "\n${ROJO}✗ Debe ingresar al menos un número.${RESET}"
        esperar_para_continuar
        return
    fi
    # Verificar que todos son números
    for v in "${datos[@]}"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los datos deben ser números reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    local count=${#datos[@]}
    local sum=0
    local x
    # Ordenar copia para mediana y moda
    local sorted=("${datos[@]}")
    IFS=$'\n' sorted=($(printf '%s\n' "${sorted[@]}" | sort -n))
    unset IFS
    for x in "${datos[@]}"; do
        sum=$(awk -v s="$sum" -v x="$x" "BEGIN { print s + x }")
    done
    local mean
    mean=$(awk -v s="$sum" -v n="$count" "BEGIN { print s/n }")
    # Mediana
    local med
    if (( count % 2 == 1 )); then
        med="${sorted[$((count/2))]}"
    else
        local m1="${sorted[$((count/2 - 1))]}"
        local m2="${sorted[$((count/2))]}"
        med=$(awk -v a="$m1" -v b="$m2" "BEGIN { print (a + b)/2 }")
    fi
    # Moda: elemento con mayor frecuencia
    local mode=""
    local maxfreq=0
    local current=""
    local freq
    # Using associative array in awk
    read -r mode maxfreq <<<$(awk '{for(i=1;i<=NF;i++){a[$i]++} for(k in a){if(a[k]>max){max=a[k];mode=k}} print mode, max}' <<< "${datos[@]}")
    # Varianza y desviación estándar
    local var=0
    for x in "${datos[@]}"; do
        var=$(awk -v v="$var" -v x="$x" -v mean="$mean" "BEGIN { print v + (x-mean)*(x-mean) }")
    done
    var=$(awk -v v="$var" -v n="$count" "BEGIN { print v/n }")
    local stddev
    stddev=$(awk -v v="$var" "BEGIN { print sqrt(v) }")
    # Formatear
    local fmean fmed fvar fstd
    if [ "$PRECISION" -eq -1 ]; then
        fmean=$(awk -v v="$mean" "BEGIN { printf \"%g\", v }")
        fmed=$(awk -v v="$med" "BEGIN { printf \"%g\", v }")
        fvar=$(awk -v v="$var" "BEGIN { printf \"%g\", v }")
        fstd=$(awk -v v="$stddev" "BEGIN { printf \"%g\", v }")
    else
        fmean=$(awk -v v="$mean" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fmed=$(awk -v v="$med" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fvar=$(awk -v v="$var" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fstd=$(awk -v v="$stddev" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}Media:${RESET} $fmean"
    echo -e "${VERDE}Mediana:${RESET} $fmed"
    echo -e "${VERDE}Moda:${RESET} $mode (freq $maxfreq)"
    echo -e "${VERDE}Varianza:${RESET} $fvar"
    echo -e "${VERDE}Desv. estándar:${RESET} $fstd"
    agregar_historial "Estadísticas: mean=$fmean, median=$fmed, mode=$mode, var=$fvar, std=$fstd"
    esperar_para_continuar
}

# Combinaciones y permutaciones: nCk y nPk
combinatoria() {
    echo -e "\n${AMARILLO}COMBINACIONES Y PERMUTACIONES${RESET}"
    read -rp "n (entero no negativo): " n
    read -rp "k (entero no negativo): " k
    if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ ! "$k" =~ ^[0-9]+$ ]] || [ "$k" -gt "$n" ]; then
        echo -e "\n${ROJO}✗ Se requiere 0 ≤ k ≤ n y ambos enteros.${RESET}"
        esperar_para_continuar
        return
    fi
    # Función factorial usando bc; para valores grandes puede ser lento
    factorial() {
        local num="$1"
        local res=1
        for ((i=2; i<=num; i++)); do
            res=$(echo "$res * $i" | bc)
        done
        echo "$res"
    }
    local fact_n fact_k fact_nk
    fact_n=$(factorial "$n")
    fact_k=$(factorial "$k")
    local nk
    nk=$((n-k))
    fact_nk=$(factorial "$nk")
    local comb perm
    # nCk = n! / (k! (n-k)!)
    comb=$(echo "$fact_n / ($fact_k * $fact_nk)" | bc)
    # nPk = n! / (n-k)!
    perm=$(echo "$fact_n / $fact_nk" | bc)
    echo -e "\n${VERDE}nCk (combinaciones):${RESET} $comb"
    echo -e "${VERDE}nPk (permutaciones):${RESET} $perm"
    agregar_historial "Combinatoria: n=$n, k=$k → nCk=$comb, nPk=$perm"
    esperar_para_continuar
}

# Distribución binomial: P(X=k) = nCk p^k (1-p)^(n-k)
binomial() {
    echo -e "\n${AMARILLO}DISTRIBUCIÓN BINOMIAL${RESET}"
    read -rp "Número de ensayos n: " n
    read -rp "Éxitos k: " k
    read -rp "Probabilidad de éxito p (0≤p≤1): " p
    if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ ! "$k" =~ ^[0-9]+$ ]] || (( k>n )) || [[ ! "$p" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]]; then
        echo -e "\n${ROJO}✗ Datos inválidos. Asegure que n y k sean enteros, k ≤ n y 0≤p≤1.${RESET}"
        esperar_para_continuar
        return
    fi
    # Combinaciones nCk usando factorial sencillo (puede ser grande)
    factorial() {
        local num="$1"
        local res=1
        for ((i=2; i<=num; i++)); do
            res=$(echo "$res * $i" | bc)
        done
        echo "$res"
    }
    local fact_n fact_k fact_nk
    fact_n=$(factorial "$n")
    fact_k=$(factorial "$k")
    local nk=$((n-k))
    fact_nk=$(factorial "$nk")
    local comb
    comb=$(echo "$fact_n / ($fact_k * $fact_nk)" | bc)
    local term1 term2 term3
    term1="$comb"
    # p^k
    term2=$(awk -v p="$p" -v k="$k" "BEGIN { print p^k }")
    # (1-p)^(n-k)
    term3=$(awk -v p="$p" -v nk="$nk" "BEGIN { print (1-p)^nk }")
    local prob
    prob=$(awk -v t1="$term1" -v t2="$term2" -v t3="$term3" "BEGIN { print t1*t2*t3 }")
    local fprob
    if [ "$PRECISION" -eq -1 ]; then
        fprob=$(awk -v v="$prob" "BEGIN { printf \"%g\", v }")
    else
        fprob=$(awk -v v="$prob" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
    fi
    echo -e "\n${VERDE}P(X=$k) = $fprob${RESET}"
    agregar_historial "Binomial: n=$n,k=$k,p=$p → P=$fprob"
    esperar_para_continuar
}

# ============================================================================
# Funciones de transformada discreta de Fourier
# ============================================================================

# Calcula la transformada discreta de Fourier (DFT) de una secuencia de
# longitud N (N≤8 recomendado). Devuelve los N valores transformados.
dft() {
    echo -e "\n${AMARILLO}TRANSFORMADA DISCRETA DE FOURIER (DFT)${RESET}"
    read -rp "Longitud de la secuencia N (≤8): " N
    if [[ ! "$N" =~ ^[0-9]+$ ]] || (( N<1 )) || (( N>8 )); then
        echo -e "\n${ROJO}✗ N debe ser un entero entre 1 y 8.${RESET}"
        esperar_para_continuar
        return
    fi
    echo "Ingrese los $N valores de la secuencia (reales, separados por espacios):"
    read -ra seq
    if [ "${#seq[@]}" -ne "$N" ]; then
        echo -e "\n${ROJO}✗ Se esperaban $N valores.${RESET}"
        esperar_para_continuar
        return
    fi
    # Verificar numericos
    local v
    for v in "${seq[@]}"; do
        if [[ ! "$v" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            echo -e "\n${ROJO}✗ Todos los elementos deben ser reales.${RESET}"
            esperar_para_continuar
            return
        fi
    done
    echo -e "\n${VERDE}Resultado DFT:${RESET}"
    local k n
    for ((k=0; k<N; k++)); do
        local real=0 imag=0
        for ((n=0; n<N; n++)); do
            local angle
            # angle = -2*pi*k*n/N
            angle=$(awk -v k="$k" -v n="$n" -v N="$N" "BEGIN { print -2*atan2(1,0)*k*n/N }")
            local cosv sinv
            cosv=$(awk -v a="$angle" "BEGIN { print cos(a) }")
            sinv=$(awk -v a="$angle" "BEGIN { print sin(a) }")
            # Multiply seq[n] by e^{i angle}
            real=$(awk -v r="$real" -v xn="${seq[$n]}" -v c="$cosv" -v s="$sinv" "BEGIN { print r + xn*c }")
            imag=$(awk -v im="$imag" -v xn="${seq[$n]}" -v c="$cosv" -v s="$sinv" "BEGIN { print im + xn*s }")
        done
        local fr fi
        if [ "$PRECISION" -eq -1 ]; then
            fr=$(awk -v v="$real" "BEGIN { printf \"%g\", v }")
            fi=$(awk -v v="$imag" "BEGIN { printf \"%g\", v }")
        else
            fr=$(awk -v v="$real" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
            fi=$(awk -v v="$imag" -v p="$PRECISION" "BEGIN { printf \"%." p "g\", v }")
        fi
        echo -e "X[$k] = $fr + $fi i"
    done
    agregar_historial "DFT de tamaño $N calculada"
    esperar_para_continuar
}

# ============================================================================
# Funciones de teoría de números y conversión de bases
# ============================================================================

# Factoriza un entero positivo en sus factores primos
factorizar() {
    echo -e "\n${AMARILLO}FACTORIZACIÓN PRIMA${RESET}"
    read -rp "Ingrese un entero positivo: " n
    if [[ ! "$n" =~ ^[0-9]+$ ]] || (( n < 2 )); then
        echo -e "\n${ROJO}✗ Debe ingresar un entero ≥ 2.${RESET}"
        esperar_para_continuar
        return
    fi
    local num=$n
    local factors=()
    local p=2
    while (( p*p <= num )); do
        while (( num % p == 0 )); do
            factors+=("$p")
            num=$((num/p))
        done
        p=$((p+1))
    done
    if (( num > 1 )); then
        factors+=("$num")
    fi
    echo -e "\n${VERDE}Factores primos:${RESET} ${factors[*]}"
    agregar_historial "Factorizar $n → ${factors[*]}"
    esperar_para_continuar
}

# Conversión entre bases arbitrarias 2≤b≤36
conversion_bases() {
    echo -e "\n${AMARILLO}CONVERSIÓN ENTRE BASES (2-36)${RESET}"
    read -rp "Ingrese el número a convertir: " num
    read -rp "Base de origen (2-36): " base_in
    read -rp "Base de destino (2-36): " base_out
    if [[ ! "$base_in" =~ ^[0-9]+$ ]] || [[ ! "$base_out" =~ ^[0-9]+$ ]] || (( base_in < 2 )) || (( base_in > 36 )) || (( base_out < 2 )) || (( base_out > 36 )); then
        echo -e "\n${ROJO}✗ Las bases deben estar entre 2 y 36.${RESET}"
        esperar_para_continuar
        return
    fi
    # Convertir número de base_in a decimal
    # bc interpreta los dígitos en base hasta 16; para bases mayores se usan letras. Convertimos a mayúsculas.
    local num_upper
    num_upper=$(echo "$num" | tr '[:lower:]' '[:upper:]')
    # Configurar ibase y obase
    # Primero convertir a decimal
    # bc requiere obase antes de ibase, pero usaremos una segunda invocación para claridad
    local decimal
    # Some bc implementations treat ibase differently for digits > A. We'll rely on bc's ability up to base 36.
    decimal=$(echo "ibase=$base_in; $num_upper" | bc)
    # Luego de decimal a base_out
    local converted
    converted=$(echo "obase=$base_out; $decimal" | bc)
    # bc en mayúsculas; convert to uppercase for digits beyond 9
    echo -e "\n${VERDE}$num (base $base_in) = $converted (base $base_out)${RESET}"
    agregar_historial "Convertir $num base $base_in → $converted base $base_out"
    esperar_para_continuar
}

# ============================================================================
# Funciones adicionales: factorial extendido, MCD/MCM, gestión de
# historial persistente y empaquetado.  Estas funciones amplían las
# capacidades básicas de la calculadora y se agrupan en un submenú
# accesible desde el menú principal.  Cada una está ampliamente
# comentada para que se comprenda su propósito y funcionamiento.

###############################################################################
# factorial_extendido
#
# Calcula el factorial de un entero no negativo n (0 ≤ n ≤ 1000) de forma
# iterativa.  Para valores grandes, el resultado puede tener miles de
# dígitos; en ese caso se muestra una advertencia para que el usuario sea
# consciente de la magnitud.  Se admite un máximo de 1000 para evitar
# excesos de memoria y tiempos de cálculo prohibitivos en entornos
# restringidos como Git Bash.  Cuando está disponible, se utiliza `bc`
# para realizar los productos con precisión arbitraria; en caso contrario
# se recurre a `awk` que soporta aritmética de coma flotante, útil para
# valores moderados.
#
# Entradas: ninguna directa; la función solicita al usuario el valor de n.
# Salidas: imprime en pantalla n! y registra la operación en el historial.
factorial_extendido() {
    echo -e "\n${AMARILLO}FACTORIAL EXTENDIDO${RESET}"
    read -rp "Ingrese un entero n (0 ≤ n ≤ 1000): " n
    # Validación de entrada: solo números enteros no negativos
    if [[ ! "$n" =~ ^[0-9]+$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar un entero no negativo.${RESET}"
        esperar_para_continuar
        return
    fi
    if (( n > 1000 )); then
        echo -e "\n${ROJO}✗ El valor máximo soportado es 1000 para evitar desbordes y tiempos excesivos.${RESET}"
        esperar_para_continuar
        return
    fi
    # Inicializar acumulador
    local res=1
    local i
    # Elegir herramienta de cálculo en función de las dependencias
    if command -v bc >/dev/null 2>&1; then
        for (( i=2; i<=n; i++ )); do
            res=$(echo "$res * $i" | bc)
        done
    else
        for (( i=2; i<=n; i++ )); do
            res=$(awk -v r="$res" -v i="$i" 'BEGIN { print r*i }')
        done
    fi
    # Advertir al usuario si el resultado es demasiado largo
    local len=${#res}
    if (( len > 100 )); then
        echo -e "\n${AMARILLO}⚠ Advertencia:${RESET} el resultado tiene $len dígitos. Puede ser muy grande para algunas aplicaciones."
    fi
    echo -e "\n${VERDE}$n! = $res${RESET}"
    agregar_historial "Factorial: $n! = $res"
    esperar_para_continuar
}

###############################################################################
# mcd_mcm
#
# Calcula el máximo común divisor (MCD) y el mínimo común múltiplo (MCM) de
# dos números enteros utilizando el algoritmo de Euclides.  Se admiten
# valores negativos pero se trabaja con sus valores absolutos internamente.
# Para el cálculo del MCM se utiliza aritmética entera nativa o `bc` si
# estuviera disponible para mayor precisión.  Se valida la entrada para
# evitar que ambos números sean cero, ya que el MCD no estaría definido.
#
# Entradas: el usuario introduce dos enteros separados.
# Salidas: se muestran y registran el MCD y el MCM calculados.
mcd_mcm() {
    echo -e "\n${AMARILLO}MÁXIMO COMÚN DIVISOR Y MÍNIMO COMÚN MÚLTIPLO${RESET}"
    read -rp "Ingrese el primer entero: " a
    read -rp "Ingrese el segundo entero: " b
    if [[ ! "$a" =~ ^-?[0-9]+$ ]] || [[ ! "$b" =~ ^-?[0-9]+$ ]]; then
        echo -e "\n${ROJO}✗ Debe ingresar dos enteros válidos.${RESET}"
        esperar_para_continuar
        return
    fi
    # Convertir a valores absolutos para el cálculo
    local x=${a#-}
    local y=${b#-}
    if [[ "$x" == "0" && "$y" == "0" ]]; then
        echo -e "\n${ROJO}✗ El MCD no está definido para 0 y 0 simultáneamente.${RESET}"
        esperar_para_continuar
        return
    fi
    # Algoritmo de Euclides iterativo para hallar el MCD
    local m=$x
    local n=$y
    while [ "$n" -ne 0 ]; do
        local temp=$n
        local r=$(( m % n ))
        m=$n
        n=$r
    done
    local gcd=$m
    # Cálculo del MCM utilizando el MCD.  Evitamos desbordes con bc si
    # está disponible, de lo contrario usamos aritmética de Bash.
    local lcm
    if command -v bc >/dev/null 2>&1; then
        lcm=$(echo "($x * $y) / $gcd" | bc)
    else
        lcm=$(( x / gcd * y ))
    fi
    echo -e "\n${VERDE}MCD($a,$b) = $gcd${RESET}"
    echo -e "${VERDE}MCM($a,$b) = $lcm${RESET}"
    agregar_historial "MCD/MCM: a=$a, b=$b → MCD=$gcd, MCM=$lcm"
    esperar_para_continuar
}

###############################################################################
# guardar_historial_archivo
#
# Permite al usuario volcar el contenido del historial en memoria a un
# archivo especificado.  Si no se proporciona ninguna ruta, se utiliza
# el archivo predeterminado (HIST_FILE).  El contenido existente en el
# destino se sobrescribe, de modo que el archivo refleje únicamente el
# historial actual.  Tras guardar, se registra la acción en el historial.
guardar_historial_archivo() {
    echo -e "\n${AMARILLO}GUARDAR HISTORIAL${RESET}"
    read -rp "Ruta de archivo para guardar (ENTER para predeterminado: $HIST_FILE): " ruta
    # Usar archivo por defecto si no se especifica otro
    if [ -z "$ruta" ]; then
        ruta="$HIST_FILE"
    fi
    # Truncar el archivo antes de escribir
    : > "$ruta"
    local item
    for item in "${HISTORIAL[@]}"; do
        printf '%s\n' "$item" >> "$ruta"
    done
    echo -e "\n${VERDE}✓ Historial guardado en $ruta.${RESET}"
    agregar_historial "Historial guardado en $ruta"
    esperar_para_continuar
}

###############################################################################
# cargar_historial_archivo
#
# Permite cargar un historial desde un archivo externo, reemplazando el
# historial en memoria.  Si el archivo no existe o no es legible, se
# informa al usuario.  Además se actualiza la variable HIST_FILE para que
# las futuras operaciones persistan en ese nuevo archivo.
cargar_historial_archivo() {
    echo -e "\n${AMARILLO}CARGAR HISTORIAL${RESET}"
    read -rp "Ruta de archivo a cargar: " ruta
    if [ -z "$ruta" ] || [ ! -f "$ruta" ]; then
        echo -e "\n${ROJO}✗ Archivo no válido o inexistente.${RESET}"
        esperar_para_continuar
        return
    fi
    HISTORIAL=()
    while IFS= read -r line; do
        HISTORIAL+=("$line")
    done < "$ruta"
    # Limitar tamaño en memoria
    while [ ${#HISTORIAL[@]} -gt "$MAX_HISTORIAL" ]; do
        HISTORIAL=("${HISTORIAL[@]:1}")
    done
    HIST_FILE="$ruta"
    echo -e "\n${VERDE}✓ Historial cargado desde $ruta.${RESET}"
    agregar_historial "Historial cargado desde $ruta"
    esperar_para_continuar
}

###############################################################################
# crear_paquete_deb
#
# Genera un paquete Debian (.deb) básico que contiene este script.  El
# paquete instala la calculadora en /usr/local/bin/calc-ultra con
# permisos de ejecución.  Se emplea dpkg-deb para construir el paquete.
# Se crea un directorio temporal con la estructura de un paquete Debian y
# un archivo de control sencillo.  Tras construir el paquete, el
# directorio temporal se elimina.  La ubicación resultante del paquete
# se muestra al usuario y se añade al historial.
crear_paquete_deb() {
    echo -e "\n${AMARILLO}CREAR PAQUETE .DEB${RESET}"
    local version="1.0"
    local pkgname="calc-ultra"
    local builddir
    builddir=$(mktemp -d -t calc-deb-XXXX)
    mkdir -p "$builddir/DEBIAN" "$builddir/usr/local/bin"
    cp "$0" "$builddir/usr/local/bin/$pkgname"
    chmod 755 "$builddir/usr/local/bin/$pkgname"
    cat > "$builddir/DEBIAN/control" <<EOF
Package: $pkgname
Version: $version
Section: utils
Priority: optional
Architecture: all
Maintainer: $(whoami) <$(whoami)@localhost>
Description: Calculadora Ultra en Bash con múltiples utilidades matemáticas.
EOF
    local output="$(pwd)/${pkgname}_${version}.deb"
    # Construir el paquete.  Suprimir salida de dpkg-deb para no ensuciar
    # la interfaz.
    dpkg-deb --build "$builddir" "$output" >/dev/null 2>&1
    rm -rf "$builddir"
    echo -e "\n${VERDE}✓ Paquete .deb creado en $output${RESET}"
    agregar_historial "Paquete .deb creado en $output"
    esperar_para_continuar
}

###############################################################################
# crear_paquete_arch
#
# Genera un paquete estilo Arch Linux (.pkg.tar.zst) para distribuir la
# calculadora en sistemas basados en pacman.  El paquete resultante
# contiene el script en /usr/local/bin/calc-ultra y un archivo
# .PKGINFO mínimo con metadatos.  Se comprime la estructura con tar
# usando el soporte integrado para Zstandard.  El paquete se genera en
# el directorio de trabajo actual y se comunica al usuario su ruta.
crear_paquete_arch() {
    echo -e "\n${AMARILLO}CREAR PAQUETE .PKG.TAR.ZST (ARCH)${RESET}"
    local version="1.0-1"
    local pkgname="calc-ultra"
    local builddir
    builddir=$(mktemp -d -t calc-arch-XXXX)
    mkdir -p "$builddir/usr/local/bin"
    cp "$0" "$builddir/usr/local/bin/$pkgname"
    chmod 755 "$builddir/usr/local/bin/$pkgname"
    cat > "$builddir/.PKGINFO" <<EOF
pkgname = $pkgname
pkgver = $version
pkgdesc = Calculadora Ultra en Bash con múltiples utilidades matemáticas
packager = $(whoami)
builddate = $(date +%s)
size = $(du -sk "$builddir" | awk '{print $1*1024}')
EOF
    local output="$(pwd)/${pkgname}-${version}-any.pkg.tar.zst"
    tar --zstd -cf "$output" -C "$builddir" . >/dev/null 2>&1
    rm -rf "$builddir"
    echo -e "\n${VERDE}✓ Paquete .pkg.tar.zst creado en $output${RESET}"
    agregar_historial "Paquete Arch creado en $output"
    esperar_para_continuar
}

###############################################################################
# interfaz_interactiva
#
# Proporciona un menú interactivo usando `fzf` o `gum` para seleccionar
# acciones mediante búsqueda difusa.  Si ninguna de estas utilidades está
# instalada, se informa al usuario y se vuelve al menú principal.  Las
# opciones presentadas son equivalentes a las del menú principal.  Tras
# seleccionar una opción, se invoca la función correspondiente.
interfaz_interactiva() {
    if command -v fzf >/dev/null 2>&1; then
        local opciones=(
            "1) Ecuación cuadrática"
            "2) Ecuación cúbica"
            "3) Raíz por Newton-Raphson"
            "4) Operaciones con matrices"
            "5) Números complejos"
            "6) Simulación cuántica"
            "7) Cálculo numérico"
            "8) Estadística y combinatoria"
            "9) Transformada discreta de Fourier"
            "10) Teoría de números y bases"
            "11) Mostrar historial"
            "12) Limpiar historial"
            "13) Configurar precisión"
            "14) Otras utilidades"
            "q) Salir"
        )
        local seleccion
        seleccion=$(printf '%s\n' "${opciones[@]}" | fzf --prompt="Seleccione opción: " --height=40% --border --header="Menú interactivo")
        local codigo
        codigo=$(echo "$seleccion" | awk '{print $1}')
        case "$codigo" in
            1) resolver_cuadratica ;;
            2) resolver_cubica ;;
            3) resolver_raiz_newton ;;
            4) calcular_matrices ;;
            5) calcular_complejos ;;
            6) calcular_cuantico ;;
            7) calculo_numerico ;;
            8) estadistica_combinatoria ;;
            9) dft ;;
            10) numero_y_base ;;
            11) mostrar_historial ;;
            12) limpiar_historial ;;
            13) configurar_precision ;;
            14) otras_utilidades ;;
            q|Q) echo -e "\n${VERDE}Hasta pronto.${RESET}"; exit 0 ;;
            *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
        esac
    elif command -v gum >/dev/null 2>&1; then
        local opciones=("1) Ecuación cuadrática" "2) Ecuación cúbica" "3) Raíz por Newton-Raphson" "4) Operaciones con matrices" "5) Números complejos" "6) Simulación cuántica" "7) Cálculo numérico" "8) Estadística y combinatoria" "9) Transformada discreta de Fourier" "10) Teoría de números y bases" "11) Mostrar historial" "12) Limpiar historial" "13) Configurar precisión" "14) Otras utilidades" "q) Salir")
        local seleccion
        seleccion=$(printf '%s\n' "${opciones[@]}" | gum choose --header="Seleccione opción:" || true)
        local codigo
        codigo=$(echo "$seleccion" | awk '{print $1}')
        case "$codigo" in
            1) resolver_cuadratica ;;
            2) resolver_cubica ;;
            3) resolver_raiz_newton ;;
            4) calcular_matrices ;;
            5) calcular_complejos ;;
            6) calcular_cuantico ;;
            7) calculo_numerico ;;
            8) estadistica_combinatoria ;;
            9) dft ;;
            10) numero_y_base ;;
            11) mostrar_historial ;;
            12) limpiar_historial ;;
            13) configurar_precision ;;
            14) otras_utilidades ;;
            q|Q) echo -e "\n${VERDE}Hasta pronto.${RESET}"; exit 0 ;;
            *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
        esac
    else
        echo -e "\n${ROJO}✗ Ni fzf ni gum están instalados. Instálelos para usar la interfaz interactiva adicional.${RESET}"
        esperar_para_continuar
    fi
}

###############################################################################
# otras_utilidades
#
# Presenta un submenú con utilidades adicionales: cálculo de factorial,
# MCD/MCM, operaciones de persistencia del historial y creación de
# paquetes.  Permite también acceder a la interfaz interactiva de búsqueda
# difusa mediante fzf/gum.  El menú se repite hasta que el usuario
# elija volver (opción 'b').
otras_utilidades() {
    while true; do
        echo -e "\n${AMARILLO}OTRAS UTILIDADES${RESET}"
        echo "1) Factorial extendido"
        echo "2) MCD y MCM"
        echo "3) Guardar historial en archivo"
        echo "4) Cargar historial desde archivo"
        echo "5) Crear paquete .deb"
        echo "6) Crear paquete .pkg.tar.zst (Arch)"
        echo "7) Menú interactivo (fzf/gum)"
        echo "b) Volver"
        read -rp "Opción: " __op
        case "$__op" in
            1) factorial_extendido ;;
            2) mcd_mcm ;;
            3) guardar_historial_archivo ;;
            4) cargar_historial_archivo ;;
            5) crear_paquete_deb ;;
            6) crear_paquete_arch ;;
            7) interfaz_interactiva ;;
            b|B) return ;;
            *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
        esac
    done
}

# ============================================================================
# Menú principal y control
# ============================================================================

mostrar_menu() {
    echo -e "\n${AMARILLO}MENÚ PRINCIPAL${RESET}"
    echo "1) Resolver ecuación cuadrática"
    echo "2) Resolver ecuación cúbica"
    echo "3) Buscar raíz por Newton-Raphson"
    echo "4) Operaciones con matrices"
    echo "5) Operaciones con números complejos"
    echo "6) Simulación cuántica"
    echo "7) Cálculo numérico (integración, derivación, EDO)"
    echo "8) Estadística y combinatoria"
    echo "9) Transformada discreta de Fourier"
    echo "10) Teoría de números y bases"
    echo "11) Mostrar historial"
    echo "12) Limpiar historial"
    echo "13) Configurar precisión"
    echo "14) Otras utilidades"
    echo "q) Salir"
}

calcular_matrices() {
    echo -e "\n${AMARILLO}OPERACIONES CON MATRICES${RESET}"
    echo "1) Producto de matrices"
    echo "2) Determinante"
    echo "3) Inversa"
    echo "4) Resolver sistema lineal"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) matriz_multiplicar ;;
        2) matriz_determinante ;;
        3) matriz_inversa ;;
        4) resolver_sistema ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

calcular_complejos() {
    echo -e "\n${AMARILLO}OPERACIONES CON COMPLEJOS${RESET}"
    echo "1) Suma"
    echo "2) Producto"
    echo "3) División"
    echo "4) Módulo"
    echo "5) Argumento"
    echo "6) Conjugado"
    echo "7) Exponencial"
    echo "8) Logaritmo"
    echo "9) Potencia z^w"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) complejo_sumar ;;
        2) complejo_multiplicar ;;
        3) complejo_dividir ;;
        4) complejo_modulo ;;
        5) complejo_argumento ;;
        6) complejo_conjugado ;;
        7) complejo_exponencial ;;
        8) complejo_logaritmo ;;
        9) complejo_potencia ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

calcular_cuantico() {
    echo -e "\n${AMARILLO}MÓDULO CUÁNTICO${RESET}"
    echo "1) Qubit único"
    echo "2) Dos qubits"
    echo "3) Medición de amplitudes"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) quantum_single ;;
        2) quantum_two ;;
        3) quantum_medicion ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

calculo_numerico() {
    echo -e "\n${AMARILLO}CÁLCULO NUMÉRICO${RESET}"
    echo "1) Integración numérica"
    echo "2) Derivada numérica"
    echo "3) Resolver EDO (Euler)"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) integracion_numerica ;;
        2) derivada_numerica ;;
        3) resolver_ode ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

estadistica_combinatoria() {
    echo -e "\n${AMARILLO}ESTADÍSTICA Y COMBINATORIA${RESET}"
    echo "1) Estadísticas descriptivas"
    echo "2) Combinaciones y permutaciones"
    echo "3) Distribución binomial"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) estadisticas ;;
        2) combinatoria ;;
        3) binomial ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

numero_y_base() {
    echo -e "\n${AMARILLO}TEORÍA DE NÚMEROS Y BASES${RESET}"
    echo "1) Factorización prima"
    echo "2) Conversión entre bases"
    echo "b) Volver"
    read -rp "Opción: " op
    case "$op" in
        1) factorizar ;;
        2) conversion_bases ;;
        b|B) return ;;
        *) echo -e "\n${ROJO}✗ Opción no válida.${RESET}"; esperar_para_continuar ;;
    esac
}

main() {
    # Validar dependencias
    validar_dependencia awk
    validar_dependencia bc
    # Bucle principal
    while true; do
        mostrar_encabezado
        mostrar_menu
        read -rp "Seleccione una opción: " opcion
        case "$opcion" in
            1) resolver_cuadratica ;;
            2) resolver_cubica ;;
            3) resolver_raiz_newton ;;
            4) calcular_matrices ;;
            5) calcular_complejos ;;
            6) calcular_cuantico ;;
            7) calculo_numerico ;;
            8) estadistica_combinatoria ;;
            9) dft ;;
            10) numero_y_base ;;
            11) mostrar_historial ;;
            12) limpiar_historial ;;
            13) configurar_precision ;;
            14) otras_utilidades ;;
            q|Q) echo -e "\n${VERDE}Hasta pronto.¡Gracias por usar la calculadora ultra!${RESET}"; exit 0 ;;
            *) echo -e "\n${ROJO}✗ Opción no reconocida.${RESET}"; esperar_para_continuar ;;
        esac
    done
}

main "$@"