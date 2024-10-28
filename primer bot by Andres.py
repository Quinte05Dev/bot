from flask import Flask, request, jsonify
import pymysql.cursors

app = Flask(__name__)

# Configuración de conexión a la base de datos
connection = pymysql.connect(
    host='your_mysql_host',
    user='your_mysql_user',
    password='your_mysql_password',
    database='your_database_name',
    cursorclass=pymysql.cursors.DictCursor
)

@app.route('/validate_license', methods=['GET'])
def validate_license():
    license_key = request.args.get('license_key')
    email = request.args.get('email')

    if not license_key or not email:
        return jsonify({"status": "error", "message": "license_key and email are required"}), 400

    with connection.cursor() as cursor:
        # Consulta para validar licencia y correo
        sql = """
            SELECT * FROM licenses 
            WHERE license_key = %s AND email = %s AND status = 'activo' AND expiry_date >= CURDATE()
        """
        cursor.execute(sql, (license_key, email))
        result = cursor.fetchone()

        if result:
            return jsonify({"status": "valid"})
        else:
            return jsonify({"status": "invalid"})

if __name__ == '__main__':
    app.run()
