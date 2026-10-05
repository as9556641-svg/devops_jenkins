from app import create_app


def test_root_returns_success_message():
    client = create_app().test_client()

    response = client.get("/")

    assert response.status_code == 200
    assert response.get_json() == {"message": "Application is running"}


def test_health_check_returns_healthy_status():
    client = create_app().test_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "healthy"}