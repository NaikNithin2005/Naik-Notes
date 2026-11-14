import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_register_and_login_flow():
    email = "scientist@naiknotes.com"
    password = "secretPassword123"
    displayName = "Marie Curie"

    # 1. Register new user
    reg_res = client.post(
        "/v1/auth/register",
        json={"email": email, "password": password, "displayName": displayName},
    )
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert reg_data["email"] == email
    assert reg_data["displayName"] == displayName
    assert "token" in reg_data
    token = reg_data["token"]

    # 2. Duplicate registration fails
    dup_res = client.post(
        "/v1/auth/register",
        json={"email": email, "password": password, "displayName": displayName},
    )
    assert dup_res.status_code == 400

    # 3. Login with wrong password fails
    wrong_res = client.post(
        "/v1/auth/login",
        json={"email": email, "password": "wrongPassword!"},
    )
    assert wrong_res.status_code == 401

    # 4. Login with correct credentials succeeds
    login_res = client.post(
        "/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert login_data["email"] == email
    assert "token" in login_data

    # 5. Verify token with /me endpoint
    me_res = client.get(f"/v1/auth/me?token={login_data['token']}")
    assert me_res.status_code == 200
    me_data = me_res.json()
    assert me_data["email"] == email
    assert me_data["displayName"] == displayName

