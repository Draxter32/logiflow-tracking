def _create(client, code):
    return client.post("/deliveries", json={"tracking_code": code, "destination": "Santiago Centro"})


def test_filter_by_status(client):
    _create(client, "LF-0001")
    _create(client, "LF-0002")
    client.post("/deliveries/LF-0002/events", json={"status": "delivered"})
    r = client.get("/deliveries", params={"status": "delivered"})
    assert [d["tracking_code"] for d in r.json()] == ["LF-0002"]


def test_filter_by_invalid_status_is_rejected(client):
    assert client.get("/deliveries", params={"status": "xyz"}).status_code == 422


def test_stats(client):
    _create(client, "LF-0001")
    _create(client, "LF-0002")
    client.post("/deliveries/LF-0002/events", json={"status": "in_transit"})
    data = client.get("/stats").json()
    assert data["total"] == 2
    assert data["by_status"] == {"created": 1, "in_transit": 1}
