import pytest
from fastapi.testclient import TestClient

import main

client = TestClient(main.app)


@pytest.fixture(autouse=True)
def reset_tasks(monkeypatch):
    # Cada prueba recibe su propia lista vacía.
    monkeypatch.setattr(main, "tasks", [])


def test_list_tasks_starts_empty():
    response = client.get("/tasks")

    assert response.status_code == 200
    assert response.json() == []


def test_create_task_and_list_it():
    response = client.post("/tasks", json={"title": "Estudiar Terraform"})

    assert response.status_code == 201
    assert response.json() == {"title": "Estudiar Terraform", "done": False}
    assert client.get("/tasks").json() == [response.json()]


def test_version_uses_environment_variable(monkeypatch):
    monkeypatch.setenv("APP_VERSION", "v1.0.0")

    response = client.get("/version")

    assert response.status_code == 200
    assert response.json() == {"version": "v1.0.0"}