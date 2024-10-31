from flask import Flask, request, jsonify
import csv
from datetime import datetime
import os

app = Flask(__name__)

# Variable para el contador de ID
contador_id = 1

# Leer el último ID utilizado (si existe) para continuar el conteo
if os.path.exists("datos.csv"):
    with open("datos.csv", "r") as file:
        lines = file.readlines()
        if lines:
            last_line = lines[-1]
            last_id = int(last_line.split(",")[0])
            contador_id = last_id + 1

# Ruta para recibir y almacenar los datos mediante GET
@app.route('/guardar_datos', methods=['GET'])
def guardar_datos():
    global contador_id  # Usamos la variable global para mantener el contador

    # Generar un ID autoincremental
    id = contador_id
    contador_id += 1  # Incrementar el contador para la próxima solicitud

    # Obtener los otros parámetros de la URL
    fuerza_movimiento = request.args.get("fuerza_movimiento")
    fecha_metatrader = request.args.get("fecha_metatrader")  # Fecha enviada desde MetaTrader
    par = request.args.get("par")
    valor_par = request.args.get("valor_par")  # Nuevo parámetro para el valor del par
    
    # Obtener la fecha y hora actual del servidor
    fecha_servidor = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Crear el registro para guardar en el archivo CSV, incluyendo el valor del par
    registro = [id, fuerza_movimiento, fecha_metatrader, fecha_servidor, par, valor_par]

    # Guardar el registro en el archivo CSV
    with open("datos.csv", "a", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(registro)

    # Retornar la respuesta en una sola línea
    return jsonify({"message": f"Registro con Id: {id}, guardado exitosamente con valor {fuerza_movimiento} para el par {par} con precio {valor_par}"}), 201

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
