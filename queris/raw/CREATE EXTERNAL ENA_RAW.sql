-- Arquivo: CREATE EXTERNAL ENA_RAW.sql
-- Descrição: Tabela externa aprimorada que aponta para o diretório raiz dos dados brutos,
-- permitindo que a procedure filtre a partição de data desejada dinamicamente.

CREATE OR REPLACE EXTERNAL TABLE `ena_raw.tabela_externa_raw_data`
(
    nom_reservatorio STRING,
    cod_resplanejamento STRING,
    tip_reservatorio STRING,
    nom_bacia STRING,
    nom_ree STRING,
    id_subsistema STRING,
    nom_subsistema STRING,
    ena_data STRING,
    ena_bruta_res_mwmed STRING,
    ena_bruta_res_percentualmlt STRING,
    ena_armazenavel_res_mwmed STRING,
    ena_armazenavel_res_percentualmlt STRING,
    ena_queda_bruta STRING,
    mlt_ena STRING
)
OPTIONS(
    format = 'PARQUET',
    -- O URI agora usa um wildcard para abranger todos os diretórios de data.
    uris = ['gs://affable-elf-472819-k2-raw-data/*'],
    description = 'Tabela externa que aponta para os arquivos Parquet no bucket raw-data, com particionamento por data de ingestão.'
);