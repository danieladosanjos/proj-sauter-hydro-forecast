-- 1.1. Contagem total de registros
SELECT 
  COUNT(*) as total_registros,
  COUNT(DISTINCT cod_resplanejamento) as reservatorios_unicos,
  COUNT(DISTINCT nom_subsistema) as subsistemas_unicos
FROM `ena_raw.tabela_externa_raw_data`;


-- 2.1. Percentual de nulos por coluna
SELECT
  COUNT(*) as total,
  ROUND(100 * SUM(CASE WHEN nom_reservatorio IS NULL OR nom_reservatorio = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_nom_reservatorio_nulo,
  ROUND(100 * SUM(CASE WHEN cod_resplanejamento IS NULL OR cod_resplanejamento = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_cod_reservatorio_nulo,
  ROUND(100 * SUM(CASE WHEN ena_data IS NULL OR ena_data = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_ena_data_nula,
  ROUND(100 * SUM(CASE WHEN ena_bruta_res_mwmed IS NULL OR ena_bruta_res_mwmed = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_ena_bruta_nula
FROM `ena_raw.tabela_externa_raw_data`;


-- 3.1. Estatísticas dos campos numéricos (como string)
SELECT
  ena_bruta_res_mwmed as valor_original,
  COUNT(*) as frequencia
FROM `ena_raw.tabela_externa_raw_data`
WHERE ena_bruta_res_mwmed IS NOT NULL 
  AND ena_bruta_res_mwmed != ''
GROUP BY ena_bruta_res_mwmed
ORDER BY frequencia DESC
LIMIT 20;

-- 3.2. Verificar formatos numéricos problemáticos
SELECT
  ena_bruta_res_mwmed,
  COUNT(*) as total
FROM `ena_raw.tabela_externa_raw_data`
WHERE ena_bruta_res_mwmed IS NOT NULL
  AND ena_bruta_res_mwmed != ''
  AND NOT REGEXP_CONTAINS(ena_bruta_res_mwmed, r'^-?[0-9]+([,.][0-9]+)?$')
GROUP BY ena_bruta_res_mwmed;

-- 4.1. Verificar formato e validade das datas
SELECT
  ena_data,
  COUNT(*) as total,
  CASE 
    WHEN SAFE_CAST(ena_data AS DATE) IS NULL THEN 'DATA_INVALIDA'
    ELSE 'DATA_VALIDA'
  END as status_data
FROM `ena_raw.tabela_externa_raw_data`
WHERE ena_data IS NOT NULL AND ena_data != ''
GROUP BY ena_data, status_data
ORDER BY total DESC
LIMIT 15;

-- 4.2. Range temporal dos dados
SELECT
  MIN(SAFE_CAST(ena_data AS DATE)) as data_minima,
  MAX(SAFE_CAST(ena_data AS DATE)) as data_maxima,
  COUNT(DISTINCT SAFE_CAST(ena_data AS DATE)) as dias_unicos
FROM `ena_raw.tabela_externa_raw_data`
WHERE SAFE_CAST(ena_data AS DATE) IS NOT NULL;


-- 5.1. Valores únicos por categoria
SELECT 
  'tip_reservatorio' as campo,
  tip_reservatorio as valor,
  COUNT(*) as total
FROM `ena_raw.tabela_externa_raw_data`
GROUP BY tip_reservatorio
UNION ALL
SELECT 
  'nom_subsistema' as campo,
  nom_subsistema as valor,
  COUNT(*) as total
FROM `ena_raw.tabela_externa_raw_data`
GROUP BY nom_subsistema
ORDER BY campo, total DESC;

-- 6.1. Qualidade dos dados por data de processamento (partição)
SELECT
  REGEXP_EXTRACT(_FILE_NAME, r'dt=([^/]+)') as dt_particao,
  COUNT(*) as total_registros,
  ROUND(100 * SUM(CASE WHEN ena_bruta_res_mwmed IS NULL OR ena_bruta_res_mwmed = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_dados_ausentes,
  ROUND(100 * SUM(CASE WHEN SAFE_CAST(ena_data AS DATE) IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_datas_invalidas
FROM `ena_raw.tabela_externa_raw_data`
GROUP BY dt_particao
ORDER BY dt_particao;

-- 7.1. Amostra aleatória para visualização
SELECT 
  nom_reservatorio,
  cod_resplanejamento,
  tip_reservatorio,
  ena_data,
  ena_bruta_res_mwmed,
  ena_bruta_res_percentualmlt,
  _FILE_NAME
FROM `ena_raw.tabela_externa_raw_data`
TABLESAMPLE SYSTEM (10 PERCENT)
LIMIT 50;

-- 8.1. Dashboard de qualidade dos dados
SELECT
  'RESUMO_QUALIDADE_DADOS' as metricas,
  COUNT(*) as total_registros,
  COUNT(DISTINCT cod_resplanejamento) as reservatorios_unicos,
  ROUND(100 * SUM(CASE WHEN ena_bruta_res_mwmed IS NULL OR ena_bruta_res_mwmed = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_ena_bruta_ausente,
  ROUND(100 * SUM(CASE WHEN SAFE_CAST(ena_data AS DATE) IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_datas_validas,
  ROUND(100 * SUM(CASE WHEN cod_resplanejamento IS NULL OR cod_resplanejamento = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_codigos_invalidos
FROM `ena_raw.tabela_externa_raw_data`;