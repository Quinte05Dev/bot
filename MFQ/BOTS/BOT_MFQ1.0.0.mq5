//+------------------------------------------------------------------+
//|                         botMovimientosFuertesEURUSD.mq5          |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#property copyright "Andrés Quintero"
#property link      "https://www.mql5.com"
#property version   "1.03"
#include <Trade\Trade.mqh>

// Variables input
input double pips_sl = 10;                // Stop loss en pips
input double riesgo_porcentaje = 1;        // Porcentaje de riesgo por operación
input double riesgo_beneficio = 2;         // Relación riesgo-beneficio
input double fuerza_minima = 0.0001;       // Movimiento mínimo en pips para considerar fuerza
input double pips_activacion_trailing = 15; // Pips para activar el trailing stop
input double pips_distancia_trailing = 5;  // Pips de distancia para el trailing stop
input double pips_repeticion = 5;          // Pips para permitir la repetición de operaciones

// Variables internas
double balance = 0;                    // Balance de la cuenta
double riesgo_dinero = 0;              // Dinero en riesgo por operación
double volumen = 0;                    // Volumen de la operación
double stop_loss = 0;                  // Stop loss calculado en precio
double take_profit = 0;                // Take profit calculado en precio
CTrade trade;                          // Objeto para ejecutar operaciones
bool operacion_abierta = false;        // Bandera para indicar si hay operación abierta
double precio_ultima_operacion = 0;   // Precio de la última operación

//+------------------------------------------------------------------+
//| Función para calcular el volumen basado en el riesgo y el stop loss |
//+------------------------------------------------------------------+
double calcularVolumen(double riesgo_dinero, double stop_loss)
{
   double valorPorPip = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double volumen_calculado = riesgo_dinero / (stop_loss / _Point * valorPorPip);
   return NormalizeDouble(volumen_calculado, 2); // Ajuste a dos decimales
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Bot iniciado correctamente.");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Aquí puedes limpiar recursos si es necesario
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Si ya hay una operación abierta, aplicamos trailing stop
   if (operacion_abierta) {
      aplicarTrailingStop();
   }

   // Calcular el balance de la cuenta y el riesgo a tomar
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   riesgo_dinero = balance * (riesgo_porcentaje / 100.0);

   // Calcular el volumen con base en el riesgo y el stop loss en pips
   stop_loss = pips_sl * _Point;
   volumen = calcularVolumen(riesgo_dinero, stop_loss);

   // Obtener el precio actual y el precio anterior
   double precio_actual = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double precio_anterior = iClose(Symbol(), PERIOD_M5, 1); // Precio de cierre de la vela anterior

   // Calcular el cambio de precio actual
   double cambio_precio_actual = MathAbs(precio_actual - precio_anterior);

   // Verificar si el movimiento actual supera el umbral de fuerza
   if (cambio_precio_actual >= fuerza_minima) {
      // Log para ver el cambio de precio
      Print("Cambio de precio actual: ", cambio_precio_actual, ", Fuerza mínima: ", fuerza_minima);

      // Si el precio sube y la última operación fue una venta
      if (precio_actual > precio_anterior && (precio_ultima_operacion == 0 || precio_ultima_operacion <= precio_actual - pips_repeticion * _Point)) {
         double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         take_profit = entry + (stop_loss * riesgo_beneficio);
         
         // Ejecutar la orden de compra
         trade.Buy(volumen, Symbol(), NormalizeDouble(entry, _Digits), 
                   NormalizeDouble(entry - stop_loss, _Digits), 
                   NormalizeDouble(take_profit, _Digits), "Compra a favor de la tendencia");
         Print("Orden de compra ejecutada.");
         operacion_abierta = true;
         precio_ultima_operacion = entry; // Guardar el precio de la última operación
      } 
      // Si el precio baja y la última operación fue una compra
      else if (precio_actual < precio_anterior && (precio_ultima_operacion == 0 || precio_ultima_operacion >= precio_actual + pips_repeticion * _Point)) {
         double entry = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         take_profit = entry - (stop_loss * riesgo_beneficio);
         
         // Ejecutar la orden de venta
         trade.Sell(volumen, Symbol(), NormalizeDouble(entry, _Digits), 
                    NormalizeDouble(entry + stop_loss, _Digits), 
                    NormalizeDouble(take_profit, _Digits), "Venta a favor de la tendencia");
         Print("Orden de venta ejecutada.");
         operacion_abierta = true;
         precio_ultima_operacion = entry; // Guardar el precio de la última operación
      }
   }
}

//+------------------------------------------------------------------+
//| Función para aplicar trailing stop                               |
//+------------------------------------------------------------------+
void aplicarTrailingStop()
{
   // Iterar a través de todas las posiciones abiertas
   for (int i = 0; i < PositionsTotal(); i++) {
      if (PositionSelect(Symbol())) { // Seleccionar la posición por símbolo
         double precio_actual = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double precio_entrada = PositionGetDouble(POSITION_PRICE_OPEN);
         double stop_actual = PositionGetDouble(POSITION_SL);

         // Si es una compra y el precio se ha movido a favor
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
             (precio_actual - precio_entrada) >= pips_activacion_trailing * _Point) {
            
            double nuevo_stop = precio_actual - pips_distancia_trailing * _Point;
            if (nuevo_stop > stop_actual) {
               trade.PositionModify(PositionGetSymbol(i), NormalizeDouble(nuevo_stop, _Digits), PositionGetDouble(POSITION_TP));
               Print("Trailing stop actualizado para la operación de compra.");
            }
         }

         // Si es una venta y el precio se ha movido a favor
         else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
                  (precio_entrada - precio_actual) >= pips_activacion_trailing * _Point) {
            
            double nuevo_stop = precio_actual + pips_distancia_trailing * _Point;
            if (nuevo_stop < stop_actual) {
               trade.PositionModify(PositionGetSymbol(i), NormalizeDouble(nuevo_stop, _Digits), PositionGetDouble(POSITION_TP));
               Print("Trailing stop actualizado para la operación de venta.");
            }
         }
      }
   }
}
