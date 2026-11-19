import os
from contextlib import asynccontextmanager
from datetime import UTC, datetime

from botocore.exceptions import BotoCoreError, ClientError
from fastapi import FastAPI, HTTPException, Response
from psycopg import Error as PostgresError
from pydantic import BaseModel
from time import perf_counter

import database
import metrics

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
    started_at = perf_counter()
    try:
        tasks = database.list_tasks()
    except PostgresError as error:
        metrics.record_rds_error()
        raise HTTPException(
            status_code=503, detail="No se pudieron leer las tareas."
        ) from error

    elapsed_ms = (perf_counter() - started_at) * 1000
    metrics.record_task_read_latency(elapsed_ms)
    return tasks


@app.post("/tasks", status_code=201)
def create_task(task: Task):
    try:
        database.create_task(task.title, task.done)
    except PostgresError as error:
        metrics.record_rds_error()
        raise HTTPException(
            status_code=503, detail="No se pudo guardar la tarea."
        ) from error
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