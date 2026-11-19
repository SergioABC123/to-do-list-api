import os
from contextlib import asynccontextmanager

from datetime import UTC, datetime

from botocore.exceptions import BotoCoreError, ClientError
from fastapi import FastAPI, Response
from psycopg import Error as PostgresError

from pydantic import BaseModel

import database


@asynccontextmanager
async def lifespan(_app: FastAPI):
    database.initialize()
    yield


app = FastAPI(lifespan=lifespan)


class Task(BaseModel):
    title: str
    done: bool = False  # Si se omite, la tarea empieza como pendiente.


@app.get("/tasks")
def list_tasks():
    return database.list_tasks()


@app.post("/tasks", status_code=201)
def create_task(task: Task):
    database.create_task(task.title, task.done)
    return task


@app.get("/version")
def get_version():
    return {"version": os.getenv("APP_VERSION", "dev")}

@app.get("/health")
def health(response: Response):
    try:
        database.check_connection()
        database_status = "ok"
    except (PostgresError, BotoCoreError, ClientError):
        response.status_code = 503
        database_status = "unavailable"

    return {
        "database": database_status,
        "version": get_version()["version"],
        "timestamp": datetime.now(UTC).isoformat(),
    }