#!/bin/bash

set -e

# Archivo temporal para pruebas de historial
TMPFILE=$(mktemp)

# Cargar funciones sin ejecutar el bucle principal
source src/calculadora.sh > /dev/null 2>&1

# Redefinir ubicación y límites del historial para la prueba
HISTORIAL_ARCHIVO="$TMPFILE"
MAX_HISTORIAL=5
HISTORIAL=()

# Agregar entradas de historial y verificar límite
for i in {1..7}; do
  agregar_historial "op $i"
done

lineas=$(wc -l < "$HISTORIAL_ARCHIVO")
if [ "$lineas" -eq 5 ]; then
  echo "✅ Límite de historial respetado"
else
  echo "❌ Límite de historial incorrecto: $lineas entradas"
fi

# Limpiar historial y comprobar archivo vacío
limpiar_historial > /dev/null
if [ -s "$HISTORIAL_ARCHIVO" ]; then
  echo "❌ Historial no se limpió"
else
  echo "✅ Historial limpiado"
fi

rm -f "$TMPFILE"
