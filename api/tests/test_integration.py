import unittest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi.testclient import TestClient
from datetime import date
import pandas as pd
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from main import app

class TestIntegration(unittest.TestCase):

    def setUp(self):
        self.client = TestClient(app)

    @patch('main.executar_fluxo', new_callable=AsyncMock)
    def test_processar_endpoint_integration(self, mock_executar_fluxo):
        """Testa a integração do endpoint /processar com os serviços mockados."""
        mock_executar_fluxo.return_value = [{'id': 1, 'data': '2023-01-15'}]

        response = self.client.post("/processar", json={"data_inicio": "2023-01-01", "data_fim": "2023-12-31"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Processados 1 registros com sucesso.", data["mensagem"])
        self.assertEqual(data["total_registros"], 1)
        mock_executar_fluxo.assert_called_once()

    @patch('main.consultar_dados_por_intervalo', new_callable=AsyncMock)
    def test_consultar_endpoint_integration(self, mock_consultar):
        """Testa a integração do endpoint /consultar com o serviço de BigQuery mockado."""
        mock_consultar.return_value = [{'id': 1, 'ena_data': date(2023, 1, 10)}]

        response = self.client.get("/consultar?data_inicio=2023-01-01&data_fim=2023-01-31")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Consulta retornou 1 registros com sucesso.", data["mensagem"])
        self.assertEqual(data["total_registros"], 1)
        mock_consultar.assert_called_once_with(date(2023, 1, 1), date(2023, 1, 31))

    @patch('main.executar_fluxo', new_callable=AsyncMock)
    def test_processar_endpoint_sem_recursos_filtrados(self, mock_executar_fluxo):
        """Testa o endpoint /processar quando nenhum recurso é encontrado para o período."""
        mock_executar_fluxo.return_value = []

        response = self.client.post("/processar", json={"data_inicio": "2023-01-01", "data_fim": "2023-12-31"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("O fluxo de trabalho terminou, mas nenhum dado foi processado.", data["mensagem"])
        self.assertEqual(data["total_registros"], 0)

if __name__ == '__main__':
    unittest.main()