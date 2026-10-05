def _create(client, code="LF-0001"):
    return client.post(
        "/deliveries", json={"tracking_code": code, "destination": "Av. Providencia 1234, Santiago"}
    )


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_version(client):
    r = client.get("/version")
    assert r.status_code == 200
    assert "version" in r.json()


def test_create_and_get_delivery(client):
    r = _create(client)
    assert r.status_code == 201
    assert r.json()["status"] == "created"
    assert client.get("/deliveries/LF-0001").json()["tracking_code"] == "LF-0001"


def test_duplicate_tracking_code_returns_409(client):
    _create(client)
    assert _create(client).status_code == 409


def test_unknown_delivery_returns_404(client):
    assert client.get("/deliveries/NOPE").status_code == 404


def test_add_event_updates_status(client):
    _create(client)
    r = client.post(
        "/deliveries/LF-0001/events",
        json={
            "status": "in_transit",
            "lat": -33.45,
            "lng": -70.66,
            "note": "Salió del centro de distribución",
        },
    )
    assert r.status_code == 201
    assert client.get("/deliveries/LF-0001").json()["status"] == "in_transit"
    assert len(client.get("/deliveries/LF-0001/events").json()) == 1


def test_invalid_status_is_rejected(client):
    _create(client)
    r = client.post("/deliveries/LF-0001/events", json={"status": "teletransportado"})
    assert r.status_code == 422


def test_invalid_coordinates_are_rejected(client):
    _create(client)
    r = client.post("/deliveries/LF-0001/events", json={"status": "in_transit", "lat": 999, "lng": 0})
    assert r.status_code == 422


def test_list_deliveries(client):
    _create(client, "LF-0001")
    _create(client, "LF-0002")
    assert len(client.get("/deliveries").json()) == 2
