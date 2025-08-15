#!/bin/bash

echo "🔍 Ejecutando pruebas básicas de la calculadora..."

# Prueba de suma
resultado=$(echo "2+2" | bc)
[ "$resultado" -eq 4 ] && echo "✅ Suma correcta" || echo "❌ Suma falló"

# Prueba factorial de 5
fact=$(echo "x=1; for(i=1;i<=5;i++) x*=i; print x" | bc -l)
[ "$fact" -eq 120 ] && echo "✅ Factorial correcto" || echo "❌ Factorial falló"

# Prueba seno (0 radianes)
sin0=$(echo "s(0)" | bc -l)
[ "$sin0" == "0" ] && echo "✅ Seno correcto" || echo "⚠️ Seno dio $sin0"
