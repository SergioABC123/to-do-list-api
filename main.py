from fastapi import FastAPI
from pydantic import BaseModel
import os

app = FastAPI()


class Task(BaseModel): # define los datos que recibirá la api cuando se crea una tarea
    title: str
    done: bool = False # falso por predeterminado si no le pones nada


tasks: list[Task] = [] # las tareas se guardan en memoria y se pierden al reiniciar el servidor


@app.get("/tasks") # Primera ruta que usamos con el FastAPI para obtener las tareas
def list_tasks():
    return tasks


@app.post("/tasks", status_code=200) # FastAPI valida el JSON de la petición con Task
def create_task(task: Task):
    tasks.append(task) # la añadimos a la lista
    return task

@app.get("/version")
def get_version():
    # en cada despliegue, APP_VERSION tendrá la etiqueta del release
    return {"version": os.getenv("APP_VERSION", "dev")}