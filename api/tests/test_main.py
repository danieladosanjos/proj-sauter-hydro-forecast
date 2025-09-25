import unittest
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from datetime import date
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from main import app

class TestMain(unittest.TestCase):

    def setUp(self):
        self.client = TestClient(app)

    def test_health_check(self):
        """Testa o endpoint de verificação de saúde da API."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    @patch('main.consultar_dados_por_intervalo', new_callable=AsyncMock)
    def test_consultar_bigquery_sucesso(self, mock_consultar):
        """Testa o endpoint de consulta com dados retornados com sucesso."""
        mock_consultar.return_value = [{"id": 1, "data": "2023-01-01"}, {"id": 2, "data": "2023-01-02"}]

        response = self.client.get("/consultar?data_inicio=2023-01-01&data_fim=2023-01-31")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Consulta retornou 2 registros com sucesso.", data["mensagem"])
        self.assertEqual(data["total_registros"], 2)
        self.assertEqual(len(data["dados"]), 2)

    @patch('main.consultar_dados_por_intervalo', new_callable=AsyncMock)
    def test_consultar_bigquery_sem_dados(self, mock_consultar):
        """Testa o endpoint de consulta quando nenhum dado é encontrado."""
        mock_consultar.return_value = []

        response = self.client.get("/consultar?data_inicio=2023-01-01&data_fim=2023-01-31")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Nenhum dado encontrado", data["mensagem"])
        self.assertEqual(data["total_registros"], 0)

    def test_consultar_bigquery_data_invalida(self):
        """Testa o endpoint de consulta com data de início posterior à data de fim."""
        response = self.client.get("/consultar?data_inicio=2023-02-01&data_fim=2023-01-31")

        self.assertEqual(response.status_code, 400)
        self.assertIn("A data de início não pode ser posterior à data de fim.", response.json()["detail"])

    @patch('main.executar_fluxo', new_callable=AsyncMock)
    def test_processar_arquivos_sucesso(self, mock_executar_fluxo):
        """Testa o endpoint de processamento com dados retornados com sucesso."""
        mock_executar_fluxo.return_value = [{"id": 1, "processed": True}]

        response = self.client.post("/processar", json={"data_inicio": "2023-01-01", "data_fim": "2023-01-31"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Processados 1 registros com sucesso.", data["mensagem"])
        self.assertEqual(data["total_registros"], 1)

    @patch('main.executar_fluxo', new_callable=AsyncMock)
    def test_processar_arquivos_sem_dados(self, mock_executar_fluxo):
        """Testa o endpoint de processamento quando nenhum dado é processado."""
        mock_executar_fluxo.return_value = []

        response = self.client.post("/processar", json={"data_inicio": "2023-01-01", "data_fim": "2023-01-31"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("O fluxo de trabalho terminou, mas nenhum dado foi processado.", data["mensagem"])
        self.assertEqual(data["total_registros"], 0)

    def test_processar_arquivos_data_invalida(self):
        """Testa o endpoint de processamento com data de início posterior à data de fim."""
        response = self.client.post("/processar", json={"data_inicio": "2023-02-01", "data_fim": "2023-01-31"})

        self.assertEqual(response.status_code, 400)
        self.assertIn("A data de início não pode ser posterior à data de fim.", response.json()["detail"])

if __name__ == '__main__':
    unittest.main()