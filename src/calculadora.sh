#!/bin/bash

# Colores y estilos avanzados
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

# Historial de operaciones
HISTORIAL=()
MAX_HISTORIAL=10

# Archivo para persistir historial
HISTORIAL_ARCHIVO="${HOME}/.calculadora_historial"

# Cargar historial desde disco
cargar_historial() {
    if [ -f "$HISTORIAL_ARCHIVO" ]; then
        mapfile -t HISTORIAL < "$HISTORIAL_ARCHIVO"
        if [ ${#HISTORIAL[@]} -gt $MAX_HISTORIAL ]; then
            HISTORIAL=("${HISTORIAL[@]: -$MAX_HISTORIAL}")
        fi
    fi
}

# Guardar historial en disco
guardar_historial() {
    printf "%s\n" "${HISTORIAL[@]}" > "$HISTORIAL_ARCHIVO"
}

# Agregar entrada al historial y mantener tamaño máximo
agregar_historial() {
    HISTORIAL+=("$1")
    if [ ${#HISTORIAL[@]} -gt $MAX_HISTORIAL ]; then
        HISTORIAL=("${HISTORIAL[@]:1}")
    fi
    guardar_historial
}

# Variables para modo científico
MODO_CIENTIFICO=false
PRECISION=4

# Función para configurar la precisión decimal
configurar_precision() {
    local precision_actual="$PRECISION"
    echo -e "\n${AMARILLO}CONFIGURACIÓN DE PRECISIÓN${RESET}"
    echo -e "Precisión decimal actual: ${VERDE}$precision_actual${RESET}"
    read -rp "Ingrese la nueva precisión (número de decimales): " nueva_precision
    if [[ "$nueva_precision" =~ ^[0-9]+$ ]] && [ "$nueva_precision" -ge 0 ]; then
        PRECISION="$nueva_precision"
        echo -e "\n${VERDE}✓ Precisión actualizada a $PRECISION decimales.${RESET}"
    else
        echo -e "\n${ROJO}✗ Valor no válido. Se mantiene la precisión actual.${RESET}"
    fi
}

# Función para calcular el factorial
factorial() {
    local num="$1"
    if [ "$num" -eq 0 ] || [ "$num" -eq 1 ]; then
        echo 1
    else
        local prev=$(factorial "$((num - 1))")
        echo "$((num * prev))"
    fi
}

# Función para calcular el MCD (Máximo Común Divisor)
mcd() {
    local a="$1"
    local b="$2"
    while [ "$b" -ne 0 ]; do
        local temp="$b"
        b=$((a % b))
        a="$temp"
    done
    echo "$a"
}

# Función para calcular el MCM (Mínimo Común Múltiplo)
mcm() {
    local a="$1"
    local b="$2"
    local producto=$((a * b))
    local divisor=$(mcd "$a" "$b")
    echo "$((producto / divisor))"
}

# Función para convertir entre sistemas numéricos
conversion_base() {
    echo -e "\n${AMARILLO}CONVERSIÓN ENTRE SISTEMAS NUMÉRICOS${RESET}"
    echo -e "1. Decimal a Binario"
    echo -e "2. Decimal a Hexadecimal"
    echo -e "3. Decimal a Octal"
    echo -e "4. Binario a Decimal"
    echo -e "5. Hexadecimal a Decimal"
    echo -e "6. Octal a Decimal"
    read -rp "Seleccione una opción (1-6): " opcion_base

    case "$opcion_base" in
        1)
            read -rp "Ingrese número decimal: " num
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                resultado=$(echo "obase=2; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en binario es: $resultado${RESET}"
                agregar_historial "Decimal a Binario: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        2)
            read -rp "Ingrese número decimal: " num
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                resultado=$(echo "obase=16; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en hexadecimal es: $resultado${RESET}"
                agregar_historial "Decimal a Hexadecimal: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        3)
            read -rp "Ingrese número decimal: " num
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                resultado=$(echo "obase=8; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en octal es: $resultado${RESET}"
                agregar_historial "Decimal a Octal: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        4)
            read -rp "Ingrese número binario: " num
            if [[ "$num" =~ ^[01]+$ ]]; then
                resultado=$(echo "ibase=2; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en decimal es: $resultado${RESET}"
                agregar_historial "Binario a Decimal: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        5)
            read -rp "Ingrese número hexadecimal: " num
            if [[ "$num" =~ ^[0-9A-Fa-f]+$ ]]; then
                num=$(echo "$num" | tr '[:lower:]' '[:upper:]')
                resultado=$(echo "ibase=16; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en decimal es: $resultado${RESET}"
                agregar_historial "Hexadecimal a Decimal: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        6)
            read -rp "Ingrese número octal: " num
            if [[ "$num" =~ ^[0-7]+$ ]]; then
                resultado=$(echo "ibase=8; $num" | bc)
                resultado="${resultado//$'\n'/}"
                echo -e "\n${VERDE}$num en decimal es: $resultado${RESET}"
                agregar_historial "Octal a Decimal: $num → $resultado"
            else
                echo -e "\n${ROJO}✗ Entrada no válida.${RESET}"
            fi
            ;;
        *)
            echo -e "\n${ROJO}✗ Opción no válida.${RESET}"
            ;;
    esac
}

# Función para mostrar el historial
mostrar_historial() {
    if [ ${#HISTORIAL[@]} -eq 0 ]; then
        echo -e "\n${AMARILLO}El historial está vacío.${RESET}"
        return
    fi

    echo -e "\n${AMARILLO}HISTORIAL DE OPERACIONES${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local contador=1
    # Mostrar de más reciente a más antiguo
    for ((i=${#HISTORIAL[@]}-1; i>=0; i--)); do
        echo -e "${CYAN}$contador.${RESET} ${HISTORIAL[$i]}"
        ((contador++))
    done

    echo -e "${CYAN}----------------------------------------${RESET}"
}

# Función para limpiar el historial
limpiar_historial() {
    HISTORIAL=()
    guardar_historial
    echo -e "\n${VERDE}✓ Historial limpiado correctamente.${RESET}"
}

# Función para mostrar ayuda
mostrar_ayuda() {
    echo -e "\n${FONDO_AZUL}${BLANCO}${NEGRITA} AYUDA DE LA CALCULADORA ${RESET}"
    echo -e "\n${NEGRITA}Operaciones básicas:${RESET}"
    echo -e "  ${VERDE}s${RESET} - Suma dos números"
    echo -e "  ${VERDE}m${RESET} - Multiplica dos números"
    echo -e "  ${VERDE}d${RESET} - Divide un número entre otro (división entera)"
    echo -e "  ${VERDE}p${RESET} - Calcula la potencia de un número elevado a otro"

    echo -e "\n${NEGRITA}Operaciones científicas:${RESET}"
    echo -e "  ${VERDE}r${RESET} - Raíz cuadrada de un número"
    echo -e "  ${VERDE}c${RESET} - Coseno de un ángulo (en radianes)"
    echo -e "  ${VERDE}t${RESET} - Tangente de un ángulo (en radianes)"
    echo -e "  ${VERDE}i${RESET} - Seno de un ángulo (en radianes)"
    echo -e "  ${VERDE}l${RESET} - Logaritmo natural de un número"
    echo -e "  ${VERDE}f${RESET} - Factorial de un número"

    echo -e "\n${NEGRITA}Funciones especiales:${RESET}"
    echo -e "  ${VERDE}g${RESET} - MCD (Máximo Común Divisor) de dos números"
    echo -e "  ${VERDE}n${RESET} - MCM (Mínimo Común Múltiplo) de dos números"
    echo -e "  ${VERDE}b${RESET} - Conversión entre sistemas numéricos"

    echo -e "\n${NEGRITA}Herramientas y configuración:${RESET}"
    echo -e "  ${VERDE}h${RESET} - Ver historial de operaciones"
    echo -e "  ${VERDE}x${RESET} - Limpiar historial"
    echo -e "  ${VERDE}z${RESET} - Cambiar entre modo básico y científico"
    echo -e "  ${VERDE}w${RESET} - Configurar precisión decimal"
    echo -e "  ${VERDE}?${RESET} - Mostrar esta ayuda"
    echo -e "  ${VERDE}q${RESET} - Salir de la calculadora"

    echo -e "\n${NEGRITA}Notas:${RESET}"
    echo -e "• En ${VERDE}modo científico${RESET} se muestran todas las operaciones disponibles."
    echo -e "• La ${VERDE}precisión decimal${RESET} afecta al número de decimales mostrados en los resultados."
    echo -e "• Se guardan las últimas $MAX_HISTORIAL operaciones en el historial."
}

# Función para mostrar el encabezado
mostrar_encabezado() {
    clear
    echo -e "${AZUL}╔══════════════════════════════════════════════════╗${RESET}"
    if $MODO_CIENTIFICO; then
        echo -e "${AZUL}║     ${MAGENTA}CALCULADORA CIENTÍFICA PREMIUM${AZUL}         ║${RESET}"
    else
        echo -e "${AZUL}║     ${MAGENTA}CALCULADORA ESTÁNDAR PREMIUM${AZUL}           ║${RESET}"
    fi
    echo -e "${AZUL}╠══════════════════════════════════════════════════╣${RESET}"
    echo -e "${AZUL}║ ${CYAN}Precisión:${RESET} $PRECISION decimal(es)                                  ║${RESET}"
    echo -e "${AZUL}╚══════════════════════════════════════════════════╝${RESET}"
}

# Función para mostrar el menú básico
mostrar_menu_basico() {
    echo -e "\n${AMARILLO}OPERACIONES DISPONIBLES:${RESET}"
    echo -e "${VERDE}s)${RESET} Suma         ${VERDE}m)${RESET} Multiplicación"
    echo -e "${VERDE}d)${RESET} División entera ${VERDE}p)${RESET} Potencia"
    echo -e "${VERDE}f)${RESET} Factorial     ${VERDE}r)${RESET} Raíz cuadrada"
    echo -e "${VERDE}h)${RESET} Historial     ${VERDE}z)${RESET} Modo científico"
    echo -e "${VERDE}?)${RESET} Ayuda         ${VERDE}q)${RESET} Salir"
}

# Función para mostrar el menú científico
mostrar_menu_cientifico() {
    echo -e "\n${AMARILLO}OPERACIONES BÁSICAS:${RESET}"
    echo -e "${VERDE}s)${RESET} Suma         ${VERDE}m)${RESET} Multiplicación"
    echo -e "${VERDE}d)${RESET} División entera ${VERDE}p)${RESET} Potencia"

    echo -e "\n${AMARILLO}OPERACIONES CIENTÍFICAS:${RESET}"
    echo -e "${VERDE}f)${RESET} Factorial     ${VERDE}r)${RESET} Raíz cuadrada"
    echo -e "${VERDE}c)${RESET} Coseno        ${VERDE}t)${RESET} Tangente"
    echo -e "${VERDE}i)${RESET} Seno          ${VERDE}l)${RESET} Logaritmo natural"
    echo -e "${VERDE}g)${RESET} MCD           ${VERDE}n)${RESET} MCM"
    echo -e "${VERDE}b)${RESET} Conversión bases ${VERDE}w)${RESET} Configurar precisión"

    echo -e "\n${AMARILLO}HERRAMIENTAS:${RESET}"
    echo -e "${VERDE}h)${RESET} Historial     ${VERDE}x)${RESET} Limpiar historial"
    echo -e "${VERDE}z)${RESET} Modo básico   ${VERDE}?)${RESET} Ayuda"
    echo -e "${VERDE}q)${RESET} Salir"
}

# Función principal de la calculadora
calculadora() {
    local ultima_operacion=""
    local ultimo_resultado=0

    while true; do
        mostrar_encabezado

        # Mostrar última operación si existe
        if [ -n "$ultima_operacion" ]; then
            echo -e "\n${CYAN}Última operación:${RESET} $ultima_operacion"
            echo -e "${CYAN}Resultado:${RESET} $ultimo_resultado"
        fi

        # Mostrar menú según el modo
        if $MODO_CIENTIFICO; then
            mostrar_menu_cientifico
        else
            mostrar_menu_basico
        fi

        echo -e "\n${AMARILLO}Elija una opción:${RESET}"
        read -rp "→ " op

        case "$op" in
            q|Q)
                echo -e "\n${VERDE}¡Gracias por usar la calculadora premium! Hasta pronto.${RESET}"
                guardar_historial
                sleep 1
                clear
                break
                ;;
            z|Z)
                MODO_CIENTIFICO=!$MODO_CIENTIFICO
                if $MODO_CIENTIFICO; then
                    echo -e "\n${VERDE}✓ Modo científico activado.${RESET}"
                else
                    echo -e "\n${VERDE}✓ Modo básico activado.${RESET}"
                fi
                sleep 1
                continue
                ;;
            \?|h|H|x|X|w|W)
                # Opciones de herramientas
                case "$op" in
                    \?)
                        mostrar_ayuda
                        ;;
                    h|H)
                        mostrar_historial
                        ;;
                    x|X)
                        limpiar_historial
                        ;;
                    w|W)
                        configurar_precision
                        ;;
                esac
                ;;
            b|B)
                if $MODO_CIENTIFICO; then
                    conversion_base
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            g|G)
                if $MODO_CIENTIFICO; then
                    echo -e "\n${AMARILLO}CÁLCULO DEL MÁXIMO COMÚN DIVISOR (MCD)${RESET}"
                    read -rp "Ingrese el primer número entero positivo: " n1
                    read -rp "Ingrese el segundo número entero positivo: " n2

                    if [[ "$n1" =~ ^[0-9]+$ ]] && [[ "$n2" =~ ^[0-9]+$ ]] && [ "$n1" -gt 0 ] && [ "$n2" -gt 0 ]; then
                        resultado=$(mcd "$n1" "$n2")
                        echo -e "\n${VERDE}El MCD de $n1 y $n2 es: $resultado${RESET}"
                        ultima_operacion="MCD($n1, $n2)"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                    else
                        echo -e "\n${ROJO}✗ Entrada no válida. Ingrese números enteros positivos.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            n|N)
                if $MODO_CIENTIFICO; then
                    echo -e "\n${AMARILLO}CÁLCULO DEL MÍNIMO COMÚN MÚLTIPLO (MCM)${RESET}"
                    read -rp "Ingrese el primer número entero positivo: " n1
                    read -rp "Ingrese el segundo número entero positivo: " n2

                    if [[ "$n1" =~ ^[0-9]+$ ]] && [[ "$n2" =~ ^[0-9]+$ ]] && [ "$n1" -gt 0 ] && [ "$n2" -gt 0 ]; then
                        resultado=$(mcm "$n1" "$n2")
                        echo -e "\n${VERDE}El MCM de $n1 y $n2 es: $resultado${RESET}"
                        ultima_operacion="MCM($n1, $n2)"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                    else
                        echo -e "\n${ROJO}✗ Entrada no válida. Ingrese números enteros positivos.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            f|F)
                echo -e "\n${AMARILLO}CÁLCULO DE FACTORIAL${RESET}"
                read -rp "Ingrese un número entero no negativo: " n1

                if [[ "$n1" =~ ^[0-9]+$ ]]; then
                    if [ "$n1" -gt 20 ]; then
                        echo -e "\n${ROJO}⚠ Advertencia: El cálculo puede desbordar con números grandes.${RESET}"
                        read -rp "¿Desea continuar? (s/n): " confirmar
                        if [[ "$confirmar" != "s" && "$confirmar" != "S" ]]; then
                            continue
                        fi
                    fi

                    resultado=$(factorial "$n1")
                    echo -e "\n${VERDE}El factorial de $n1 es: $resultado${RESET}"
                    ultima_operacion="$n1!"
                    ultimo_resultado="$resultado"
                    agregar_historial "$ultima_operacion = $ultimo_resultado"
                else
                    echo -e "\n${ROJO}✗ Error: Debe ingresar un número entero no negativo.${RESET}"
                fi
                ;;
            r|R)
                echo -e "\n${AMARILLO}CÁLCULO DE RAÍZ CUADRADA${RESET}"
                read -rp "Ingrese un número no negativo: " n1

                if [[ "$n1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    # Usamos awk para la raíz cuadrada
                    resultado=$(awk "BEGIN { printf \"%.${PRECISION}f\", sqrt($n1) }")
                    echo -e "\n${VERDE}La raíz cuadrada de $n1 es: $resultado${RESET}"
                    ultima_operacion="√$n1"
                    ultimo_resultado="$resultado"
                    agregar_historial "$ultima_operacion = $ultimo_resultado"
                else
                    echo -e "\n${ROJO}✗ Error: Debe ingresar un número no negativo.${RESET}"
                fi
                ;;
            c|C)
                if $MODO_CIENTIFICO || [ "$op" = "c" ] || [ "$op" = "C" ]; then
                    echo -e "\n${AMARILLO}CÁLCULO DE COSENO${RESET}"
                    read -rp "Ingrese un ángulo en radianes: " n1

                    if [[ "$n1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                        # Usamos awk para el coseno
                        resultado=$(awk "BEGIN { printf \"%.${PRECISION}f\", cos($n1) }")
                        echo -e "\n${VERDE}El coseno de $n1 radianes es: $resultado${RESET}"
                        ultima_operacion="cos($n1)"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                    else
                        echo -e "\n${ROJO}✗ Error: Debe ingresar un número válido.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            t|T)
                if $MODO_CIENTIFICO || [ "$op" = "t" ] || [ "$op" = "T" ]; then
                    echo -e "\n${AMARILLO}CÁLCULO DE TANGENTE${RESET}"
                    read -rp "Ingrese un ángulo en radianes: " n1

                    if [[ "$n1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                        # Usamos awk para la tangente (con manejo de división por cero)
                        resultado=$(awk "BEGIN { if (cos($n1) == 0) { print \"Error: Tangente indefinida\" } else { printf \"%.${PRECISION}f\", sin($n1)/cos($n1) } }")
                        if [[ "$resultado" == "Error: Tangente indefinida" ]]; then
                            echo -e "\n${ROJO}✗ Error: La tangente no está definida para este ángulo.${RESET}"
                        else
                            echo -e "\n${VERDE}La tangente de $n1 radianes es: $resultado${RESET}"
                            ultima_operacion="tan($n1)"
                            ultimo_resultado="$resultado"
                            agregar_historial "$ultima_operacion = $ultimo_resultado"
                        fi
                    else
                        echo -e "\n${ROJO}✗ Error: Debe ingresar un número válido.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            i|I)
                if $MODO_CIENTIFICO; then
                    echo -e "\n${AMARILLO}CÁLCULO DE SENO${RESET}"
                    read -rp "Ingrese un ángulo en radianes: " n1

                    if [[ "$n1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                        # Usamos awk para el seno
                        resultado=$(awk "BEGIN { printf \"%.${PRECISION}f\", sin($n1) }")
                        echo -e "\n${VERDE}El seno de $n1 radianes es: $resultado${RESET}"
                        ultima_operacion="sin($n1)"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                    else
                        echo -e "\n${ROJO}✗ Error: Debe ingresar un número válido.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            l|L)
                if $MODO_CIENTIFICO || [ "$op" = "l" ] || [ "$op" = "L" ]; then
                    echo -e "\n${AMARILLO}CÁLCULO DE LOGARITMO NATURAL${RESET}"
                    read -rp "Ingrese un número positivo: " n1

                    if [[ "$n1" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$n1 > 0" | bc -l) )); then
                        # Usamos awk para el logaritmo natural
                        resultado=$(awk "BEGIN { printf \"%.${PRECISION}f\", log($n1) }")
                        echo -e "\n${VERDE}El logaritmo natural de $n1 es: $resultado${RESET}"
                        ultima_operacion="ln($n1)"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                    else
                        echo -e "\n${ROJO}✗ Error: Debe ingresar un número positivo.${RESET}"
                    fi
                else
                    echo -e "\n${ROJO}✗ Opción disponible solo en modo científico.${RESET}"
                fi
                ;;
            s|S|m|M|d|D|p|P)
                case "$op" in
                    s|S) operacion="SUMA"; simbolo="+";;
                    m|M) operacion="MULTIPLICACIÓN"; simbolo="×";;
                    d|D) operacion="DIVISIÓN"; simbolo="÷";;
                    p|P) operacion="POTENCIA"; simbolo="^";;
                esac

                echo -e "\n${AMARILLO}CÁLCULO DE $operacion${RESET}"
                read -rp "Ingrese el primer número: " n1
                read -rp "Ingrese el segundo número: " n2

                # Validación de entrada
                if ! [[ "$n1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$n2" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                    echo -e "\n${ROJO}✗ Error: Debe ingresar números válidos.${RESET}"
                    continue
                fi

                case "$op" in
                    s|S)
                        # Usamos awk para la suma
                        resultado=$(awk "BEGIN { printf \"%g\", $n1 + $n2 }")
                        echo -e "\n${VERDE}$n1 $simbolo $n2 = $resultado${RESET}"
                        ultima_operacion="$n1 + $n2"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                        ;;
                    m|M)
                        # Usamos awk para la multiplicación
                        resultado=$(awk "BEGIN { printf \"%g\", $n1 * $n2 }")
                        echo -e "\n${VERDE}$n1 $simbolo $n2 = $resultado${RESET}"
                        ultima_operacion="$n1 × $n2"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                        ;;
                    d|D)
                        if (( $(echo "$n2 == 0" | bc -l) )); then
                            echo -e "\n${ROJO}✗ Error: No se puede dividir por cero.${RESET}"
                        else
                            # Usamos awk para la división
                            resultado=$(awk "BEGIN { printf \"%g\", $n1 / $n2 }")
                            echo -e "\n${VERDE}$n1 $simbolo $n2 = $resultado${RESET}"
                            ultima_operacion="$n1 ÷ $n2"
                            ultimo_resultado="$resultado"
                            agregar_historial "$ultima_operacion = $ultimo_resultado"
                        fi
                        ;;
                    p|P)
                        # Usamos awk para la potencia
                        resultado=$(awk "BEGIN { printf \"%g\", $n1 ^ $n2 }")
                        echo -e "\n${VERDE}$n1 $simbolo $n2 = $resultado${RESET}"
                        ultima_operacion="$n1 ^ $n2"
                        ultimo_resultado="$resultado"
                        agregar_historial "$ultima_operacion = $ultimo_resultado"
                        ;;
                esac
                ;;
            *)
                echo -e "\n${ROJO}✗ Opción no válida. Utilice '?' para ver la ayuda.${RESET}"
                ;;
        esac


        echo ""
        read -rp "Presione ENTER para continuar..."
    done
}

# Verificar si awk está instalado
if ! command -v awk &> /dev/null; then
    echo -e "${ROJO}Error: Esta calculadora requiere el programa 'awk'.${RESET}"
    echo "Asegúrese de que esté instalado en su sistema."
    exit 1
fi

# Mostrar banner de inicio
cargar_historial
clear
echo -e "${CYAN}"
echo "  ██████╗ █████╗ ██╗  ██╗███████╗███████╗██████╗  ██████╗ ██████╗ "
echo " ██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗"
echo " ██║   ██║███████║█████╔╝ ██████╗ ██████╗ ██████╔╝██║   ██║██████╔╝"
echo " ██║   ██║██╔══██║██╔═██╗ ╚════██╗╚════██╗██╔══██╗██║   ██║██╔══██╗"
echo " ╚██████╔╝██║  ██║██║  ██╗███████║███████║██║  ██║╚██████╔╝██║  ██║"
echo "  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
echo "${RESET}"

calculadora
