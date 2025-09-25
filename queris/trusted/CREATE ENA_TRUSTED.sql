CREATE OR REPLACE TABLE `affable-elf-472819-k2.ena_trusted.tabela_ena_trusted`
(
  -- Colunas de Identificação
  nom_reservatorio STRING,
  cod_resplanejamento INT64, -- Convertido de STRING para INT64
  tip_reservatorio STRING,
  nom_bacia STRING,
  nom_ree STRING,
  id_subsistema INT64, -- Convertido de STRING para INT64
  nom_subsistema STRING,

  -- Colunas de Dados e Valores
  ena_bruta_res_mwmed FLOAT64, -- Convertido de STRING para FLOAT64
  ena_bruta_res_percentualmlt FLOAT64, -- Convertido de STRING para FLOAT64
  ena_armazenavel_res_mwmed FLOAT64, -- Convertido de STRING para FLOAT64
  ena_armazenavel_res_percentualmlt FLOAT64, -- Convertido de STRING para FLOAT64
  ena_queda_bruta FLOAT64, -- Convertido de STRING para FLOAT64
  mlt_ena FLOAT64, -- Convertido de STRING para FLOAT64

  -- Colunas de Controle e Particionamento
  ena_data DATE, -- Convertido de STRING para DATE
  dt_processamento DATE,
  dt_carga TIMESTAMP
)
PARTITION BY
  dt_processamento
OPTIONS(
  description="Tabela Trusted com dados de ENA por reservatório, particionada por data de processamento."
);
