CREATE OR REPLACE PROCEDURE `affable-elf-472819-k2.ena_trusted.sp_atualizar_ena_trusted`(p_data_processamento DATE)
BEGIN
  MERGE `affable-elf-472819-k2.ena_trusted.tabela_ena_trusted` AS T
  USING (
    SELECT
      nom_reservatorio,
      SAFE_CAST(cod_resplanejamento AS INT64) AS cod_resplanejamento,
      tip_reservatorio,
      nom_bacia,
      nom_ree,
      SAFE_CAST(id_subsistema AS INT64) AS id_subsistema,
      nom_subsistema,
      SAFE_CAST(ena_data AS DATE) AS ena_data,
      SAFE_CAST(REPLACE(ena_bruta_res_mwmed, ',', '.') AS FLOAT64) AS ena_bruta_res_mwmed,
      SAFE_CAST(REPLACE(ena_bruta_res_percentualmlt, ',', '.') AS FLOAT64) AS ena_bruta_res_percentualmlt,
      SAFE_CAST(REPLACE(ena_armazenavel_res_mwmed, ',', '.') AS FLOAT64) AS ena_armazenavel_res_mwmed,
      SAFE_CAST(REPLACE(ena_armazenavel_res_percentualmlt, ',', '.') AS FLOAT64) AS ena_armazenavel_res_percentualmlt,
      SAFE_CAST(REPLACE(ena_queda_bruta, ',', '.') AS FLOAT64) AS ena_queda_bruta,
      SAFE_CAST(REPLACE(mlt_ena, ',', '.') AS FLOAT64) AS mlt_ena,
      p_data_processamento AS dt_processamento,
      CURRENT_TIMESTAMP() AS dt_carga
    FROM
      `ena_raw.tabela_externa_raw_data`
    WHERE STARTS_WITH(_FILE_NAME, FORMAT('gs://affable-elf-472819-k2-raw-data/dt=%t', p_data_processamento))
  ) AS S
  ON T.cod_resplanejamento = S.cod_resplanejamento AND T.ena_data = S.ena_data

  WHEN MATCHED THEN
    UPDATE SET
      T.nom_reservatorio = S.nom_reservatorio,
      T.tip_reservatorio = S.tip_reservatorio,
      T.nom_bacia = S.nom_bacia,
      T.nom_ree = S.nom_ree,
      T.id_subsistema = S.id_subsistema,
      T.nom_subsistema = S.nom_subsistema,
      T.ena_bruta_res_mwmed = S.ena_bruta_res_mwmed,
      T.ena_bruta_res_percentualmlt = S.ena_bruta_res_percentualmlt,
      T.ena_armazenavel_res_mwmed = S.ena_armazenavel_res_mwmed,
      T.ena_armazenavel_res_percentualmlt = S.ena_armazenavel_res_percentualmlt,
      T.ena_queda_bruta = S.ena_queda_bruta,
      T.mlt_ena = S.mlt_ena,
      T.dt_carga = S.dt_carga

  WHEN NOT MATCHED THEN
    INSERT (
      nom_reservatorio, cod_resplanejamento, tip_reservatorio, nom_bacia, nom_ree, id_subsistema, nom_subsistema,
      ena_data, ena_bruta_res_mwmed, ena_bruta_res_percentualmlt, ena_armazenavel_res_mwmed,
      ena_armazenavel_res_percentualmlt, ena_queda_bruta, mlt_ena, dt_processamento, dt_carga
    )
    VALUES (
      S.nom_reservatorio, S.cod_resplanejamento, S.tip_reservatorio, S.nom_bacia, S.nom_ree, S.id_subsistema, S.nom_subsistema,
      S.ena_data, S.ena_bruta_res_mwmed, S.ena_bruta_res_percentualmlt, S.ena_armazenavel_res_mwmed,
      S.ena_armazenavel_res_percentualmlt, S.ena_queda_bruta, S.mlt_ena, S.dt_processamento, S.dt_carga
    );
END;