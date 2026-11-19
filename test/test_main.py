import pytest
from fastapi.testclient import TestClient

import main

@pytest.fixture
def client(monkeypatch):
    tasks = []

    def save_task(title, done):
        tasks.append({"title": title, "done": done})

    monkeypatch.setattr(main.database, "initialize", lambda: None)
    monkeypatch.setattr(main.database, "list_tasks", lambda: tasks)
    monkeypatch.setattr(main.database, "create_task", save_task)

    with TestClient(main.app) as test_client:
        yield test_client


def test_list_tasks_starts_empty(client):
    response = client.get("/tasks")

    assert response.status_code == 200
    assert response.json() == []


def test_create_task_and_list_it(client):
    response = client.post("/tasks", json={"title": "Estudiar Terraform"})

    assert response.status_code == 201
    assert response.json() == {"title": "Estudiar Terraform", "done": False}
    assert client.get("/tasks").json() == [response.json()]


def test_version_uses_environment_variable(client, monkeypatch):
    monkeypatch.setenv("APP_VERSION", "v1.0.0")

    response = client.get("/version")

    assert response.status_code == 200
    assert response.json() == {"version": "v1.0.0"}

def test_health_returns_503_when_database_is_down(client, monkeypatch):
    def fail_connection():
        raise main.PostgresError("Database unavailable")

    monkeypatch.setattr(main.database, "check_connection", fail_connection)

    response = client.get("/health")

    assert response.status_code == 503
    assert response.json()["database"] == "unavailable"