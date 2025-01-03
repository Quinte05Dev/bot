//+------------------------------------------------------------------+
//|                         Apertura_USDCAD_1.0.0                    |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#property copyright "Andrés Quintero"
#property link      "https://www.mql5.com"
#property version   "1.0.0"
#include <Trade\Trade.mqh>

// Variables input
input double riesgo_porcentaje = 1;         // Porcentaje de riesgo por operación
input double riesgo_beneficio = 2;          // Relación riesgo-beneficio
input double max_movimiento_pips = 20;      // Movimiento máximo en pips entre 7am y 9am para abrir operación

// Variables internas
double maximo = 0;
double minimo = 0;
double balance = 0;
double volumen = 0;
double stop_loss = 0;
double take_profit = 0;
CTrade trade;
bool operacion_abierta = false;
bool mensaje_mostrado_20_pips = false;      // Bandera para mensaje de 20 pips
bool mensaje_mostrado_30_min = false;       // Bandera para mensaje de 30 minutos
int dia_actual = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   MqlDateTime tiempo_actual;
   TimeToStruct(TimeCurrent(), tiempo_actual);
   dia_actual = tiempo_actual.day;
   Print("Bot Apertura_USDCAD_1.0.0 iniciado correctamente.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlDateTime tiempo_actual;
   TimeToStruct(TimeCurrent(), tiempo_actual);
   
   // Reset de las banderas a las 00:00 de cada nuevo día
   if (tiempo_actual.hour == 0 && tiempo_actual.min == 0 && tiempo_actual.sec == 0)
   {
      mensaje_mostrado_20_pips = false;
      mensaje_mostrado_30_min = false;
      operacion_abierta = false;
      maximo = 0;
      minimo = 0;
      dia_actual = tiempo_actual.day;
   }

   // Solo operar si es un nuevo día y dentro de la ventana horaria correcta (7am - 9am)
   if (tiempo_actual.hour >= 7 && tiempo_actual.hour < 9 && dia_actual == tiempo_actual.day)
   {
      // Calcular el máximo y mínimo entre las 7am y las 9am
      double precio_actual = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      if (maximo == 0 || precio_actual > maximo)
         maximo = precio_actual;
      if (minimo == 0 || precio_actual < minimo)
         minimo = precio_actual;

      // Mostrar el máximo y mínimo a las 9am
      if (tiempo_actual.hour == 9 && tiempo_actual.min == 0 && dia_actual == tiempo_actual.day)
      {
         Print("Máximo: ", maximo, " Mínimo: ", minimo);
      }
   }

   // A las 9am, tomar decisiones
   if (tiempo_actual.hour == 9 && tiempo_actual.min == 0 && !mensaje_mostrado_20_pips)
   {
      // Calcular el movimiento en pips entre el máximo y el mínimo
      double movimiento_pips = (maximo - minimo) / _Point;
      Print("Movimiento en pips: ", movimiento_pips);
      
      // Verificar si el movimiento supera el máximo permitido
      if (movimiento_pips > max_movimiento_pips)
      {
         Print("Movimiento mayor a ", max_movimiento_pips, " pips. No se abrirán operaciones.");
         mensaje_mostrado_20_pips = true;  // Marcar que se ha mostrado el mensaje
         return;
      }
   }

   // Intentar abrir una operación si el precio rompe el máximo o el mínimo
   if (tiempo_actual.hour == 9 && tiempo_actual.min == 0 && !operacion_abierta)
   {
      double precio_actual = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riesgo_dinero = balance * (riesgo_porcentaje / 100.0);
      volumen = calcularVolumen(riesgo_dinero, 10 * _Point); // SL fijo de 10 pips

      if (precio_actual > maximo)
      {
         // Rompió el máximo, abrir operación de compra
         stop_loss = maximo - 10 * _Point;
         take_profit = maximo + (10 * _Point * riesgo_beneficio);
         if (trade.Buy(volumen, Symbol(), precio_actual, stop_loss, take_profit))
         {
            Print("Orden de compra abierta. Precio: ", precio_actual, " SL: ", stop_loss, " TP: ", take_profit);
            operacion_abierta = true;
         }
         else
         {
            Print("Error al abrir orden de compra: ", GetLastError());
         }
      }
      else if (precio_actual < minimo)
      {
         // Rompió el mínimo, abrir operación de venta
         stop_loss = minimo + 10 * _Point;
         take_profit = minimo - (10 * _Point * riesgo_beneficio);
         if (trade.Sell(volumen, Symbol(), precio_actual, stop_loss, take_profit))
         {
            Print("Orden de venta abierta. Precio: ", precio_actual, " SL: ", stop_loss, " TP: ", take_profit);
            operacion_abierta = true;
         }
         else
         {
            Print("Error al abrir orden de venta: ", GetLastError());
         }
      }
   }

   // Comprobar si han pasado 30 minutos sin romper máximos o mínimos
   if (tiempo_actual.hour == 9 && tiempo_actual.min == 30 && !operacion_abierta && !mensaje_mostrado_30_min)
   {
      Print("Han pasado 30 minutos y no se rompió el máximo ni el mínimo. No se abrirán operaciones.");
      mensaje_mostrado_30_min = true;  // Marcar que se ha mostrado el mensaje
   }
}

//+------------------------------------------------------------------+
//| Función para calcular el volumen basado en el riesgo y el stop loss | 
//+------------------------------------------------------------------+
double calcularVolumen(double riesgo_dinero, double stop_loss)
{
   double valorPorPip = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double volumen_calculado = riesgo_dinero / (stop_loss / _Point * valorPorPip);
   return NormalizeDouble(volumen_calculado, 2); // Ajuste a dos decimales
}
