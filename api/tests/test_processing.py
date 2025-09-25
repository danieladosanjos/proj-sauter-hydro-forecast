import unittest
from unittest.mock import patch, AsyncMock
from datetime import date
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from processing import executar_fluxo

class TestProcessing(unittest.TestCase):

    @patch('service.obter_recursos_ons', new_callable=AsyncMock)
    @patch('service.filtrar_recursos_por_ano_e_formato')
    @patch('service.processar_recurso', new_callable=AsyncMock)
    def test_executar_fluxo_sucesso(self, mock_processar, mock_filtrar, mock_obter):
        """Testa o fluxo de execução com sucesso."""
        mock_obter.return_value = [{'url': 'http://example.com/dados_2023.parquet', 'format': 'PARQUET'}]
        mock_filtrar.return_value = [{'url': 'http://example.com/dados_2023.parquet', 'format': 'PARQUET'}]
        mock_processar.return_value = [{'id': 1, 'data': '2023-01-01'}]

        async def run_test():
            resultado = await executar_fluxo(date(2023, 1, 1), date(2023, 12, 31))
            self.assertEqual(len(resultado), 1)
            self.assertEqual(resultado[0]['id'], 1)

        import asyncio
        asyncio.run(run_test())

    @patch('service.obter_recursos_ons', new_callable=AsyncMock)
    def test_executar_fluxo_sem_recursos(self, mock_obter):
        """Testa o fluxo quando não há recursos da ONS."""
        mock_obter.return_value = []

        async def run_test():
            resultado = await executar_fluxo(date(2023, 1, 1), date(2023, 12, 31))
            self.assertEqual(len(resultado), 0)

        import asyncio
        asyncio.run(run_test())

    @patch('service.obter_recursos_ons', new_callable=AsyncMock)
    @patch('service.filtrar_recursos_por_ano_e_formato')
    def test_executar_fluxo_sem_recursos_filtrados(self, mock_filtrar, mock_obter):
        """Testa o fluxo quando não há recursos após a filtragem."""
        mock_obter.return_value = [{'url': 'http://example.com/dados_2023.zip', 'format': 'ZIP'}]
        mock_filtrar.return_value = []

        async def run_test():
            resultado = await executar_fluxo(date(2023, 1, 1), date(2023, 12, 31))
            self.assertEqual(len(resultado), 0)

        import asyncio
        asyncio.run(run_test())

if __name__ == '__main__':
    unittest.main()