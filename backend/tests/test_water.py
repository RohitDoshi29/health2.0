"""Tests for water intake logging, daily hydration summaries, and goals."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_log_water_and_get_today_summary(
    client: AsyncClient, auth_headers: dict[str, str]
) -> None:
    # 1. Initially today's summary is 0
    res = await client.get("/api/v1/water/today", headers=auth_headers)
    assert res.status_code == 200
    data = res.json()
    assert data["total_ml"] == 0.0
    assert data["target_ml"] == 2500.0

    # 2. Log 250 ml
    log_res = await client.post("/api/v1/water", json={"amount_ml": 250.0}, headers=auth_headers)
    assert log_res.status_code == 201
    log_data = log_res.json()
    assert log_data["total_ml"] == 250.0
    assert log_data["logs_count"] == 1
    assert log_data["logs"][0]["amount_ml"] == 250.0

    # 3. Log 500 ml
    log_res2 = await client.post("/api/v1/water", json={"amount_ml": 500.0}, headers=auth_headers)
    assert log_res2.status_code == 201
    log_data2 = log_res2.json()
    assert log_data2["total_ml"] == 750.0
    assert log_data2["logs_count"] == 2
    assert log_data2["percentage"] == round(750.0 / 2500.0 * 100, 1)


@pytest.mark.asyncio
async def test_get_water_history(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    # Log 300 ml
    await client.post("/api/v1/water", json={"amount_ml": 300.0}, headers=auth_headers)

    res = await client.get("/api/v1/water/history?days=7", headers=auth_headers)
    assert res.status_code == 200
    days = res.json()
    assert len(days) == 7
    # Last day is today
    assert days[-1]["total_ml"] >= 300.0


@pytest.mark.asyncio
async def test_delete_water_log(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    log_res = await client.post("/api/v1/water", json={"amount_ml": 400.0}, headers=auth_headers)
    log_id = log_res.json()["logs"][0]["id"]

    # Delete the log
    del_res = await client.delete(f"/api/v1/water/{log_id}", headers=auth_headers)
    assert del_res.status_code == 204

    # Verify summary reduced
    summary = await client.get("/api/v1/water/today", headers=auth_headers)
    assert summary.status_code == 200
    assert not any(entry["id"] == log_id for entry in summary.json()["logs"])


@pytest.mark.asyncio
async def test_update_water_goal(client: AsyncClient, auth_headers: dict[str, str]) -> None:
    res = await client.put(
        "/api/v1/water/goal", json={"water_target_ml": 3000.0}, headers=auth_headers
    )
    assert res.status_code == 200
    assert res.json()["water_target_ml"] == 3000.0

    # Verify today summary uses new target
    summary = await client.get("/api/v1/water/today", headers=auth_headers)
    assert summary.json()["target_ml"] == 3000.0
