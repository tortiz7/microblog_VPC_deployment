import pytest
from microblog import create_app

@pytest.fixture
def client():
  app = create_app()
  app.config['TESTING'] = True
  with app.test_client() as client:
    with app.app_context():
      yield client

def test_home_page(client):
  response = client.get('/', follow_redirects=True)
  assert response.status_code == 200
  assert b'Microblog' in response.data

def test_login_page(client):
  response = client.get('/auth/login')
  assert response.status_code == 200
  assert b'Microblog' in response.data

def test_404_page(client):
  response = client.get('/nonexistent')
  assert response.status_code == 404
