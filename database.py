import json
import os

import boto3
import psycopg


def connect():
    # Lee las credenciales de RDS al abrir la conexión.
    secrets = boto3.client("secretsmanager")
    response = secrets.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])
    credentials = json.loads(response["SecretString"])

    return psycopg.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=credentials["username"],
        password=credentials["password"],
        sslmode="require",
        connect_timeout=5,
    )

def initialize():
    # Crea la tabla en el primer arranque y la conserva en los siguientes.
    with connect() as connection:
        connection.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                title TEXT NOT NULL,
                done BOOLEAN NOT NULL DEFAULT FALSE
            )
        """)

def list_tasks():
    with connect() as connection, connection.cursor(row_factory=dict_row) as cursor:
        cursor.execute("SELECT title, done FROM tasks ORDER BY id")
        return cursor.fetchall()


def create_task(title: str, done: bool):
    with connect() as connection:
        connection.execute(
            "INSERT INTO tasks (title, done) VALUES (%s, %s)",
            (title, done),
        )

def check_connection():
    # Ejecuta una consulta sencilla para comprobar que PostgreSQL responde.
    with connect() as connection:
        connection.execute("SELECT 1")