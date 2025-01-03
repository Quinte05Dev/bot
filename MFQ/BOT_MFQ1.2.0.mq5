//+------------------------------------------------------------------+
//|                         MovimientoFuerteBTC1.2.0.mq5             |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#property copyright "Andrés Quintero"
#property link      "https://www.tp.com"
#property version   "1.2.0"
#include <Trade\Trade.mqh>

// Variables input
input string licencia = "";                  // Licencia 
input double pips_sl = 10;                   // Stop loss en pips
input double riesgo_porcentaje = 1;          // Porcentaje de riesgo por operación
input double riesgo_beneficio = 2;           // Relación riesgo-beneficio
input double fuerza_minima = 0.0001;         // Movimiento mínimo en pips para considerar fuerza
input double pips_activacion_trailing = 100; // Pips para activar el trailing stop
input double pips_distancia_trailing = 30;   // Pips de distancia para el trailing stop
input double pips_repeticion = 5;            // Pips para permitir la repetición de operaciones
input double riesgo_diario_porcentaje = 5;   // Porcentaje de riesgo diario

// Variables internas
double balance = 0;                         // Balance de la cuenta
double riesgo_dinero = 0;                   // Dinero en riesgo por operación
double volumen = 0;                         // Volumen de la operación
double stop_loss = 0;                       // Stop loss calculado en precio
double take_profit = 0;                     // Take profit calculado en precio
CTrade trade;                               // Objeto para ejecutar operaciones
bool operacion_abierta = false;             // Bandera para indicar si hay operación abierta
double precio_ultima_operacion = 0;         // Precio de la última operación
double perdidas_diarias = 0;                // Pérdidas acumuladas del día
int dia_actual = 0;                         // Día actual para resetear pérdidas diarias
double fuerza_actual = 0;                   // Variable para almacenar la fuerza del movimiento
int fuerza_objeto_id;                       // ID del objeto de texto para la fuerza

// Lista de licencias válidas (local)
string licencias_validas[] = {
    "EENDJSASSSFSASM", 
    "SADT", 
    "AFQG"
};

// Función para validar la licencia
bool validarLicencia(string licencia_usuario)
{
    for(int i = 0; i < ArraySize(licencias_validas); i++)
    {
        if(licencia_usuario == licencias_validas[i])
        {
            return true;  // Licencia válida
        }
    }
    return false;  // Licencia no válida
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

//+------------------------------------------------------------------+
//| Función para verificar si hemos alcanzado el límite diario        |
//+------------------------------------------------------------------+
bool riesgoDiarioAlcanzado()
{
    MqlDateTime tiempo_actual;
    TimeToStruct(TimeCurrent(), tiempo_actual); // Descomponer la fecha actual

    if (dia_actual != tiempo_actual.day) { // Comparar solo el día
        // Si es un nuevo día, reiniciamos las pérdidas diarias
        dia_actual = tiempo_actual.day;
        perdidas_diarias = 0;
    }

    double balance_actual = AccountInfoDouble(ACCOUNT_BALANCE);
    double perdida_permitida = balance_actual * (riesgo_diario_porcentaje / 100.0);
    return perdidas_diarias >= perdida_permitida;
}

//+------------------------------------------------------------------+
//| Función para mostrar la fuerza del movimiento en el gráfico       |
//+------------------------------------------------------------------+
void mostrarFuerzaMovimiento(double fuerza)
{
    // Si el objeto no existe, lo creamos
    if (fuerza_objeto_id == 0) {
        fuerza_objeto_id = ObjectCreate(0, "FuerzaMovimiento", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_XSIZE, 200);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_YSIZE, 20);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_XDISTANCE, 10);  // Distancia desde la izquierda
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_YDISTANCE, 30);  // Distancia desde la parte superior
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_COLOR, clrBlack);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_FONTSIZE, 14);   // Tamaño de fuente aumentado
        ObjectSetString(0, "FuerzaMovimiento", OBJPROP_FONT, "Arial");   // Fuente del texto
    }

    string texto_fuerza = StringFormat("Fuerza del Movimiento: %.2f", fuerza);
    ObjectSetString(0, "FuerzaMovimiento", OBJPROP_TEXT, texto_fuerza);
}

//+------------------------------------------------------------------+
//| Función para mostrar el estado de la licencia en el gráfico       |
//+------------------------------------------------------------------+
void mostrarEstadoLicencia(string estado)
{
    string nombre_objeto_licencia = "EstadoLicencia";
    
    // Si el objeto no existe, lo creamos
    if (ObjectFind(0, nombre_objeto_licencia) == -1) {
        ObjectCreate(0, nombre_objeto_licencia, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_XSIZE, 300);
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_YSIZE, 20);
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_XDISTANCE, 10);   // Distancia desde la izquierda
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_YDISTANCE, 50);   // Distancia desde la parte superior
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_COLOR, clrGreen); // Color verde para licencia válida
        ObjectSetInteger(0, nombre_objeto_licencia, OBJPROP_FONTSIZE, 12);    // Tamaño de fuente
        ObjectSetString(0, nombre_objeto_licencia, OBJPROP_FONT, "Arial");    // Fuente del texto
    }

    ObjectSetString(0, nombre_objeto_licencia, OBJPROP_TEXT, estado);         // Establecer el texto del estado de licencia
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Validar la licencia ingresada por el usuario
    if (!validarLicencia(licencia)) {
        Print("Licencia no válida. El bot no funcionará.");
        Comment("Licencia no válida. Ingrese una licencia válida en las propiedades del EA.");
        return(INIT_FAILED);  // Detener la ejecución del EA
    }
    
    // Si la licencia es válida, el EA continúa con la ejecución
    Print("Licencia válida. El bot está funcionando.");
    mostrarEstadoLicencia("Licencia válida.");
    
    MqlDateTime tiempo_actual;
    TimeToStruct(TimeCurrent(), tiempo_actual);
    dia_actual = tiempo_actual.day; // Inicializamos el día actual
    Print("Bot iniciado correctamente.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Verificar si el riesgo diario ha sido alcanzado
    if (riesgoDiarioAlcanzado()) {
        Print("Riesgo diario alcanzado, el bot dejará de operar por hoy.");
        return; // Salimos si hemos alcanzado el riesgo diario
    }

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
    fuerza_actual = cambio_precio_actual;

    // Mostrar la fuerza del movimiento en el gráfico
    mostrarFuerzaMovimiento(fuerza_actual);

    // Verificar si el movimiento actual supera el umbral de fuerza
    if (cambio_precio_actual >= fuerza_minima) {
        // Solo imprimir el mensaje si no hay operaciones abiertas
        if (!operacion_abierta) {
            Print("Cambio de precio actual: ", cambio_precio_actual, ", Fuerza mínima: ", fuerza_minima);
        }

        // Si el precio sube y la última operación fue una venta
        if (precio_actual > precio_anterior && (precio_ultima_operacion == 0 || precio_ultima_operacion <= precio_actual - pips_repeticion * _Point)) {
            double entry = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            take_profit = entry + (stop_loss * riesgo_beneficio);
            
            // Ejecutar la orden de compra
            if (trade.Buy(volumen, Symbol(), NormalizeDouble(entry, _Digits), 
                          NormalizeDouble(entry - stop_loss, _Digits), 
                          NormalizeDouble(take_profit, _Digits), "Compra a favor de la tendencia")) {
                Print("Orden de compra ejecutada.");
                operacion_abierta = true;
                precio_ultima_operacion = entry; // Guardar el precio de la última operación
            }
        } 
        // Si el precio baja y la última operación fue una compra
        else if (precio_actual < precio_anterior && (precio_ultima_operacion == 0 || precio_ultima_operacion >= precio_actual + pips_repeticion * _Point)) {
            double entry = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            take_profit = entry - (stop_loss * riesgo_beneficio);
            
            // Ejecutar la orden de venta
            if (trade.Sell(volumen, Symbol(), NormalizeDouble(entry, _Digits), 
                           NormalizeDouble(entry + stop_loss, _Digits), 
                           NormalizeDouble(take_profit, _Digits), "Venta a favor de la tendencia")) {
                Print("Orden de venta ejecutada.");
                operacion_abierta = true;
                precio_ultima_operacion = entry; // Guardar el precio de la última operación
            }
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
            double nuevo_stop;

            // Si es una compra y el precio se ha movido a favor
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
                (precio_actual - precio_entrada) >= pips_activacion_trailing * _Point) {
                
                nuevo_stop = precio_actual - pips_distancia_trailing * _Point;
                if (nuevo_stop > stop_actual) {
                    if (trade.PositionModify(PositionGetInteger(POSITION_TICKET), NormalizeDouble(nuevo_stop, _Digits), PositionGetDouble(POSITION_TP))) {
                        Print("Trailing stop actualizado para la operación de compra.");
                    } else {
                        Print("Error al modificar el stop loss: ", GetLastError());
                    }
                }
            }

            // Si es una venta y el precio se ha movido a favor
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
                     (precio_entrada - precio_actual) >= pips_activacion_trailing * _Point) {
                
                nuevo_stop = precio_actual + pips_distancia_trailing * _Point;
                if (nuevo_stop < stop_actual) {
                    if (trade.PositionModify(PositionGetInteger(POSITION_TICKET), NormalizeDouble(nuevo_stop, _Digits), PositionGetDouble(POSITION_TP))) {
                        Print("Trailing stop actualizado para la operación de venta.");
                    } else {
                        Print("Error al modificar el stop loss: ", GetLastError());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
