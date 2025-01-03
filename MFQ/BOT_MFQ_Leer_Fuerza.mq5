//+------------------------------------------------------------------+
//|                         MovimientoFuerteBTC_Leer_Fuerza.mq5             |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#property copyright "Andrés Quintero"
#property link "https://www.tp.com"
#property version "1.000"
#include <Trade\Trade.mqh>

 double fuerza_actual = 0;                                                                   // Variable para almacenar la fuerza del movimiento
 int fuerza_objeto_id;    
 double valor_par = 0;                                                                   // ID del objeto de texto para la fuerza

//+------------------------------------------------------------------+
// Función para Guardar Fuerza del Movimiento por endpoint local
//+------------------------------------------------------------------+
bool guardarFuerzaMovimiento(double fuerza_movimiento, string fecha_metatrader, string par, double valor_par)
{
    // URL del endpoint local para guardar los datos
    string url = "http://127.0.0.1:5000/guardar_datos";
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // Construir la URL con parámetros
    string url_con_parametros = url + "?fuerza_movimiento=" + DoubleToString(fuerza_movimiento, 5) 
                                + "&fecha_metatrader=" + fecha_metatrader 
                                + "&par=" + par 
                                + "&valor_par=" + DoubleToString(valor_par, 5);  // Enviar valor_par con 5 decimales

    //Print(url_con_parametros);

    ResetLastError();
    int res = WebRequest("GET", url_con_parametros, cookie, NULL, timeout, post, 0, result, headers);

    if (res == 201)  // Código HTTP 201 indica que el registro fue creado exitosamente
    {
        string response = CharArrayToString(result);
        Print(response);
        return true;
    }
    else
    {
        int error_code = GetLastError();
        Print("Error en WebRequest al servidor local. Código HTTP: ", res, " Código de error MQL5: ", error_code);
        return false;
    }
}

string obtenerPar()
{
    return Symbol();  // Devuelve el símbolo del par de divisas
}

double obtenerValorPar()
{
    // Obtiene el precio de venta (bid) actual del par en el que está operando el bot
    double valor_par = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    //Print(valor_par);
    return valor_par;
}

//+------------------------------------------------------------------+
//| Función para mostrar la fuerza del movimiento en el gráfico       |
//+------------------------------------------------------------------+
void mostrarFuerzaMovimiento(double fuerza)
{
    // Si el objeto no existe, lo creamos
    if (fuerza_objeto_id == 0)
    {
        fuerza_objeto_id = ObjectCreate(0, "FuerzaMovimiento", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_XSIZE, 200);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_YSIZE, 20);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_XDISTANCE, 10); // Distancia desde la izquierda
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_YDISTANCE, 50); // Distancia desde la parte superior
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_COLOR, clrGray);
        ObjectSetInteger(0, "FuerzaMovimiento", OBJPROP_FONTSIZE, 14); // Tamaño de fuente aumentado
        ObjectSetString(0, "FuerzaMovimiento", OBJPROP_FONT, "Arial"); // Fuente del texto
    }

    string texto_fuerza = StringFormat("Fuerza del Movimiento: %.5f", fuerza);
    ObjectSetString(0, "FuerzaMovimiento", OBJPROP_TEXT, texto_fuerza);
}

// Función para obtener la fecha y hora actual del servidor en el formato "YYYY-MM-DD HH:MM:SS"
string obtenerFechaMetatrader()
{
    datetime fecha_metatrader = TimeCurrent();  // Obtiene la fecha y hora actual del servidor
    //return TimeToString(fecha_metatrader, TIME_DATE | TIME_MINUTES);  // Formatea la fecha y hora
    return TimeToString(fecha_metatrader, TIME_DATE | TIME_SECONDS);

}





//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
        return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
        
    // llamada a obtener par
    string par = obtenerPar();
    //Print("Par de divisas actual: ", par);

    // llamada a obtener fecha metatrader
    string fecha_metatrader = obtenerFechaMetatrader();
    //Print("Fecha y hora de MetaTrader: ", fecha_metatrader);

    

    // Obtener el precio actual y el precio anterior
    double precio_actual = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double precio_anterior = iClose(Symbol(), PERIOD_M1, 1); // Precio de cierre de la vela anterior

    // Calcular el cambio de precio actual
    double cambio_precio_actual = MathAbs(precio_actual - precio_anterior);
    fuerza_actual = cambio_precio_actual;

    // Mostrar la fuerza del movimiento en el gráfico
    mostrarFuerzaMovimiento(fuerza_actual);

    // llamada a obtener valor del par
    double valor_par = obtenerValorPar();

    // Llamada a guardarFuerzaMovimiento
    bool resultado = guardarFuerzaMovimiento(fuerza_actual, fecha_metatrader, par, valor_par);

 
}
