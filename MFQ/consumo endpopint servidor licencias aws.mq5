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
string url = "https://mldi93hmc0.execute-api.sa-east-1.amazonaws.com/PDN/validar_licencia";

// Función para verificar la licencia a través del endpoint de AWS
bool verificarLicencia()
{
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // Construir la URL con parámetros
    string url_con_parametros = url + "?license_key=" + licencia + "&email=" + email;

    ResetLastError();
    int res = WebRequest("GET", url_con_parametros, cookie, NULL, timeout, post, 0, result, headers);

    if (res == 200)
    {
        string response = CharArrayToString(result);
        if (StringFind(response, "\"Licencia Valida\"") != -1)
        {
            Print("Licencia válida. El bot está funcionando.");
            return true;
        }
        else
        {
            Print("Licencia inválida.");
            return false;
        }
    }
    else
    {
        int error_code = GetLastError();
        Print("Error en WebRequest a AWS. Código HTTP: ", res, " Código de error MQL5: ", error_code);
        return false;
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if (verificarLicencia())
    {
        Print("Inicialización exitosa. El bot está autorizado para operar.");
        return INIT_SUCCEEDED;
    }
    else
    {
        Print("Error: licencia no válida. El bot no operará.");
        return INIT_FAILED;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Lógica de trading aquí (solo si la licencia es válida)
}
