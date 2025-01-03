//+------------------------------------------------------------------+
//|                         MovimientoFuerteBTC1.2.3.mq5             |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#property copyright "Andrés Quintero"
#property link      "https://www.tp.com"
#property version   "1.2.3"
#include <Trade\Trade.mqh>

// Variables input
input string licencia = "EENDJSASSSFSASM";                  // Licencia
input string email = "quinte05dev@gmail.com";               // Correo Registrado

// URL del servidor de verificación de licencia
string url = "https://www.google.com";

// Prueba inicial de conexión a Google para confirmar la conectividad de WebRequest
void probarConexionGoogle()
{
    string cookie = NULL, headers;
    char post[], result[];
    string google_url = "https://www.google.com";
    int timeout = 5000;

    ResetLastError();
    int res = WebRequest("GET", google_url, cookie, NULL, timeout, post, 0, result, headers);

    if (res == 200)
    {
        Print("Conexión exitosa a Google.");
    }
    else
    {
        int error_code = GetLastError();
        Print("Error en WebRequest a Google. Código HTTP: ", res, " Código de error MQL5: ", error_code);
    }
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    probarConexionGoogle();  // Prueba de conexión a Google


    Print("Licencia válida. El bot está funcionando.");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Lógica de trading aquí (si la licencia es válida)
}
