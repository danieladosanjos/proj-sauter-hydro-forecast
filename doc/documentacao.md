
# Documentação do Projeto: Pipeline de Processamento de Dados ENA (Energia Natural Afluente)

## 1. Introdução

### 1.1. Visão Geral do Projeto
Este documento detalha o projeto de pipeline de dados para o processamento de informações sobre Energia Natural Afluente (ENA), desenvolvido como parte do **Sauter University 2025 Challenge**. O projeto foi concebido e implementado por *Genário Correia de Azevedo,* atuando como engenheiro de dados, com foco na utilização de ferramentas nativas do Google Cloud Platform (GCP). O objetivo principal é estabelecer um fluxo ETL (Extract, Transform, Load) robusto, escalável e economicamente eficiente para a ingestão, validação, transformação e armazenamento de dados brutos de ENA em um formato confiável (trusted). A arquitetura emprega o Google Cloud Storage (GCS) para armazenamento de dados brutos em formato Parquet, o BigQuery para processamento e armazenamento de dados estruturados, e o Cloud Functions para orquestração e automação do pipeline. Esta abordagem visa garantir a conformidade com as melhores práticas de Engenharia de Dados, incluindo particionamento de dados para otimização de consultas e a implementação de operações de upsert para manter a integridade e a atualidade dos dados.

## 2. Arquitetura Geral

### 2.1. Componentes Principais
A arquitetura do pipeline de dados ENA é composta por três componentes principais do Google Cloud Platform, que trabalham em conjunto para garantir o fluxo contínuo e eficiente dos dados:

*   **Google Cloud Storage (GCS)**: Atua como o data lake para o armazenamento de arquivos raw em formato Parquet. Os dados são organizados em uma estrutura particionada por data (e.g., `gs://affable-elf-472819-k2-raw-data/dt=YYYY-MM-DD`), facilitando a gestão e o acesso otimizado.
*   **BigQuery**: Serve como o data warehouse analítico, hospedando tabelas externas que referenciam os dados no GCS, tabelas trusted com dados processados e limpos, e procedimentos armazenados para a execução de transformações complexas. Sua natureza serverless e escalável o torna ideal para consultas SQL em grandes volumes de dados.
*   **Cloud Functions**: Uma função serverless desenvolvida em Python, configurada para ser acionada via HTTP trigger. Esta função é responsável por orquestrar a execução do procedimento armazenado no BigQuery, que realiza as operações de transformação e carga dos dados da camada raw para a trusted. Pode ser integrada com o Cloud Scheduler para automação diária do processo.

### 2.2. Fluxo de Dados
O fluxo de dados no pipeline ENA segue uma sequência lógica, garantindo que os dados sejam processados de forma incremental e confiável:

1.  **Ingestão de Dados Raw**: Os arquivos de dados brutos de ENA, tipicamente em formato Parquet, são carregados no bucket do Google Cloud Storage designado para dados raw (`gs://affable-elf-472819-k2-raw-data/`). A organização desses arquivos segue um padrão de particionamento por data.
2.  **Exposição no BigQuery**: Uma tabela externa no BigQuery (`ena_raw.tabela_externa_raw_data`) é criada para apontar diretamente para o diretório no GCS onde os dados raw estão armazenados. Isso permite que o BigQuery consulte esses dados sem a necessidade de importá-los fisicamente, mantendo a flexibilidade e reduzindo custos de armazenamento.
3.  **Orquestração e Transformação**: Uma Cloud Function é acionada (manualmente via HTTP request ou automaticamente via Cloud Scheduler). Esta função executa um procedimento armazenado no BigQuery (`ena_trusted.sp_atualizar_ena_trusted`). Este procedimento é responsável por ler os dados da tabela externa raw, aplicar as transformações necessárias (limpeza, tipagem, padronização) e realizar uma operação de upsert (MERGE) na tabela trusted (`ena_trusted.tabela_ena_trusted`).
4.  **Análise e Validação**: Após o processamento, queries de análise preliminar são executadas na tabela trusted para validar a qualidade e a integridade dos dados, garantindo que as transformações foram aplicadas corretamente e que os dados estão prontos para consumo por aplicações analíticas ou modelos de IA.

### 2.3. Benefícios da Arquitetura
A arquitetura proposta para o pipeline de dados ENA oferece uma série de benefícios significativos, que contribuem para a eficiência, escalabilidade e sustentabilidade do projeto:

*   **Escalabilidade**: O BigQuery é projetado para processar consultas em paralelo sobre grandes volumes de dados, escalando automaticamente conforme a demanda. Da mesma forma, o Cloud Functions escala de forma elástica para lidar com picos de execução, sem intervenção manual.
*   **Custo-Efetividade**: O modelo de precificação do GCP, baseado em pagamento por uso, é altamente vantajoso. No BigQuery, os custos são principalmente associados à quantidade de dados escaneados por consulta e ao armazenamento. No Cloud Functions, o custo é determinado pelo número de invocações e pelo tempo de execução, tornando a solução econômica para cargas de trabalho intermitentes ou agendadas.
*   **Segurança**: O GCP oferece recursos de segurança robustos. O acesso aos recursos é controlado por meio de IAM (Identity and Access Management) roles, garantindo que apenas usuários e serviços autorizados possam interagir com os dados e as funções. Além disso, os dados armazenados no GCS e BigQuery são criptografados por padrão, tanto em trânsito quanto em repouso.
*   **Integração Nativa**: A utilização de ferramentas nativas do GCP (GCS, BigQuery, Cloud Functions) simplifica a integração entre os componentes, reduzindo a complexidade de desenvolvimento e o overhead de manutenção. Isso permite que a equipe se concentre na lógica de negócio e na qualidade dos dados, em vez de gerenciar a infraestrutura subjacente.
*   **Resiliência e Alta Disponibilidade**: Os serviços do GCP são projetados para alta disponibilidade e resiliência, com redundância em várias regiões e zonas de disponibilidade, minimizando o risco de interrupções no pipeline de dados.





## 3. Detalhamento dos Componentes

### 3.1. Tabela Externa Raw (`CREATEEXTERNALENA_RAW.sql`)

Este script SQL é responsável pela criação ou substituição de uma tabela externa no BigQuery que referencia os dados brutos de ENA armazenados no Google Cloud Storage (GCS). A tabela externa, denominada `ena_raw.tabela_externa_raw_data`, atua como uma camada de acesso aos arquivos Parquet sem a necessidade de ingestão física dos dados no BigQuery, mantendo-os em seu local de origem no GCS.

#### 3.1.1. Código Principal
```sql
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
    uris = ['gs://affable-elf-472819-k2-raw-data/*'],
    description = 'Tabela externa que aponta para os arquivos Parquet no bucket raw-data, com particionamento por data de ingestão.'
);
```

#### 3.1.2. Justificativa Técnica

A escolha de uma tabela externa para a camada RAW é estratégica e oferece múltiplos benefícios para o pipeline de dados:

*   **Separação de Armazenamento e Computação**: A tabela externa permite que os dados permaneçam no GCS, que é um serviço de armazenamento de objetos altamente escalável e de baixo custo, enquanto o BigQuery é utilizado para a camada de computação e consulta. Isso evita a duplicação de dados e otimiza os custos de armazenamento.
*   **Flexibilidade e Atualização Dinâmica**: Ao referenciar diretamente os arquivos no GCS, qualquer atualização ou adição de novos arquivos Parquet no bucket é automaticamente refletida na tabela externa, sem a necessidade de recarregar ou reprocessar os dados no BigQuery. Isso simplifica a manutenção do pipeline e garante que a visão dos dados seja sempre a mais recente.
*   **Formato Parquet**: A especificação do `format = 'PARQUET'` é uma escolha acertada para dados de big data. O Parquet é um formato de arquivo colunar que oferece alta compressão e codificação eficiente, resultando em menor volume de dados para leitura e, consequentemente, em consultas mais rápidas e econômicas no BigQuery. Além disso, suporta schemas evolutivos, o que é benéfico em ambientes de dados dinâmicos.
*   **URIs com Wildcard**: O uso de `uris = ['gs://affable-elf-472819-k2-raw-data/*']` é fundamental para a flexibilidade do pipeline. O wildcard `*` permite que a tabela externa abranja todos os subdiretórios e arquivos dentro do bucket `affable-elf-472819-k2-raw-data`. Isso é particularmente útil quando os dados são particionados por data (e.g., `dt=YYYY-MM-DD`), pois o BigQuery pode inferir essas partições e otimizar as consultas, lendo apenas os dados relevantes para uma determinada data ou período.
*   **Campos como STRING**: Inicialmente, todos os campos são definidos como `STRING`. Essa abordagem é uma boa prática para a camada RAW, pois preserva os dados em seu formato original, mesmo que inconsistentes (e.g., números com vírgula como separador decimal). As transformações de tipo de dado e limpeza serão realizadas em etapas posteriores do pipeline, garantindo que a camada RAW seja uma representação fiel da fonte de dados.

#### 3.1.3. Sugestões de Melhoria

Embora a implementação atual seja funcional e siga boas práticas, algumas melhorias podem ser consideradas para otimizar ainda mais a tabela externa e o pipeline:

*   **Particionamento por Hive**: A inclusão da opção `hive_partitioning_mode = 'AUTO'` nas `OPTIONS` da tabela externa permitiria que o BigQuery inferisse automaticamente as partições baseadas na estrutura de diretórios do GCS (e.g., `dt=YYYY-MM-DD`). Isso otimizaria as consultas que filtram por data, pois o BigQuery seria capaz de pular diretórios não relevantes, reduzindo a quantidade de dados escaneados e, consequentemente, os custos e o tempo de execução. Atualmente, o filtro é feito via `_FILE_NAME` na `MERGE` statement, o que é funcional, mas a inferência de partição pelo BigQuery é mais eficiente.
*   **Filtro de Partição Obrigatório**: Adicionar `require_partition_filter = TRUE` nas `OPTIONS` forçaria os usuários a incluir uma cláusula `WHERE` que filtre por partição em suas consultas à tabela externa. Isso é uma medida de governança de dados que ajuda a evitar varreduras completas da tabela (full table scans) acidentais, o que pode ser custoso em grandes volumes de dados. Embora o procedimento armazenado já filtre por `_FILE_NAME`, essa opção adicionaria uma camada de segurança para consultas ad-hoc.
*   **Validação de Schema**: Para garantir a consistência dos dados, especialmente em um ambiente onde a fonte de dados pode variar, a implementação de validações de schema no GCS (por exemplo, usando ferramentas como o Apache Avro ou Parquet com schema definido) antes da ingestão poderia ser benéfica. Embora o BigQuery seja tolerante a schemas, a validação antecipada pode prevenir erros a jusante no pipeline.

Essas melhorias visam aumentar a eficiência, a governança e a robustez da camada RAW, garantindo que o pipeline seja ainda mais otimizado para cenários de big data.



### 3.2. Procedimento Armazenado (`CREATE_PROCEDURE.sql`)

Este script SQL define um procedimento armazenado no BigQuery, denominado `ena_trusted.sp_atualizar_ena_trusted`, que é o coração do processo de transformação e carga de dados da camada RAW para a camada TRUSTED. Ele implementa uma lógica de *upsert* (atualização ou inserção) utilizando a instrução `MERGE`, garantindo a idempotência e a integridade dos dados na tabela final.

#### 3.2.1. Código Principal
```sql
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
      SAFE_CAST(REPLACE(ena_bruta_res_mwmed, ",", ".") AS FLOAT64) AS ena_bruta_res_mwmed,
      SAFE_CAST(REPLACE(ena_bruta_res_percentualmlt, ",", ".") AS FLOAT64) AS ena_bruta_res_percentualmlt,
      SAFE_CAST(REPLACE(ena_armazenavel_res_mwmed, ",", ".") AS FLOAT64) AS ena_armazenavel_res_mwmed,
      SAFE_CAST(REPLACE(ena_armazenavel_res_percentualmlt, ",", ".") AS FLOAT64) AS ena_armazenavel_res_percentualmlt,
      SAFE_CAST(REPLACE(ena_queda_bruta, ",", ".") AS FLOAT64) AS ena_queda_bruta,
      SAFE_CAST(REPLACE(mlt_ena, ",", ".") AS FLOAT64) AS mlt_ena,
      p_data_processamento AS dt_processamento,
      CURRENT_TIMESTAMP() AS dt_carga
    FROM
      `ena_raw.tabela_externa_raw_data`
    WHERE STARTS_WITH(_FILE_NAME, FORMAT("gs://affable-elf-472819-k2-raw-data/dt=%t", p_data_processamento))
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
```

#### 3.2.2. Justificativa Técnica

O procedimento armazenado `sp_atualizar_ena_trusted` é crucial para a qualidade e eficiência do pipeline, e suas escolhas de design são bem fundamentadas:

*   **Instrução `MERGE` para Upsert**: A utilização da instrução `MERGE` é uma prática recomendada para operações de *upsert*, que combinam `INSERT` e `UPDATE` em uma única transação. Isso garante que, para cada registro de entrada, se já existir um registro correspondente na tabela de destino (identificado pela chave de correspondência `T.cod_resplanejamento = S.cod_resplanejamento AND T.ena_data = S.ena_data`), ele será atualizado. Caso contrário, um novo registro será inserido. Essa abordagem é fundamental para a idempotência do pipeline, ou seja, a execução repetida do procedimento com os mesmos dados de entrada não causará duplicações ou inconsistências, apenas garantirá que a tabela `trusted` reflita o estado mais recente dos dados para uma dada data de ENA e reservatório.
*   **Transformações de Tipo de Dados e Limpeza**: A subquery `USING` realiza as transformações necessárias para converter os dados da camada RAW (onde todos os campos são `STRING`) para os tipos de dados apropriados na camada TRUSTED. As funções `SAFE_CAST` são empregadas para lidar com possíveis erros de conversão de forma robusta, retornando `NULL` em vez de falhar a consulta inteira se um valor não puder ser convertido. A função `REPLACE(",", ".")` é utilizada para padronizar o separador decimal de vírgula para ponto, um requisito comum ao lidar com dados numéricos em diferentes formatos regionais. Isso garante que os dados numéricos sejam armazenados corretamente como `FLOAT64` e `INT64`, permitindo cálculos precisos e análises eficientes.
*   **Filtro Otimizado por `_FILE_NAME`**: A cláusula `WHERE STARTS_WITH(_FILE_NAME, FORMAT("gs://affable-elf-472819-k2-raw-data/dt=%t", p_data_processamento))` é uma técnica de otimização inteligente. Em vez de escanear toda a tabela externa, que pode conter dados de várias datas, o procedimento filtra os arquivos no GCS com base no nome do arquivo (que inclui a partição `dt=YYYY-MM-DD`). Isso reduz significativamente a quantidade de dados lidos do GCS e processados pelo BigQuery, resultando em consultas mais rápidas e custos mais baixos, especialmente em pipelines incrementais que processam dados de um dia específico.
*   **Parâmetro `p_data_processamento`**: A aceitação de `p_data_processamento DATE` como parâmetro permite que o procedimento seja flexível e reutilizável. Ele pode ser invocado para processar dados de qualquer data específica, facilitando o reprocessamento de dados históricos ou o processamento diário de forma controlada. Além disso, a inclusão de `dt_processamento` e `dt_carga` na tabela `trusted` fornece metadados importantes para auditoria e rastreabilidade, indicando quando os dados foram processados e carregados.

#### 3.2.3. Sugestões de Melhoria

Para aprimorar ainda mais a robustez e a capacidade de monitoramento do procedimento armazenado, as seguintes melhorias podem ser consideradas:

*   **Logging Detalhado**: Implementar um mecanismo de logging mais detalhado dentro do procedimento. Isso pode ser feito inserindo registros em uma tabela de log dedicada (`INSERT INTO log_table ...`) que capture informações como o status da execução (sucesso/falha), a data de processamento, o número de registros inseridos/atualizados, e mensagens de erro. Isso é crucial para depuração e monitoramento da saúde do pipeline em produção.
*   **Validações de Dados e Erros**: Adicionar validações explícitas para cenários específicos. Por exemplo, verificar se a partição de dados para `p_data_processamento` existe na camada RAW antes de tentar processá-la. Se a partição estiver vazia ou não existir, o procedimento poderia registrar um aviso ou erro e sair, em vez de tentar processar dados inexistentes. A instrução `IF COUNT(*) = 0 THEN RAISE ERROR` pode ser usada para interromper a execução em caso de condições inesperadas, como a ausência de dados para a data especificada.
*   **Tratamento de Erros Transacionais**: Embora o BigQuery seja transacional por padrão para operações DML, considerar blocos `BEGIN...EXCEPTION...END` (se o BigQuery suportar sintaxe similar para procedimentos) para um tratamento de erros mais granular, permitindo *rollback* ou ações corretivas específicas em caso de falha em partes do `MERGE`.
*   **Modularidade e Reutilização**: Para procedimentos mais complexos, considerar a criação de funções auxiliares ou sub-procedimentos para encapsular lógicas específicas (e.g., validação de um campo específico, cálculo de uma métrica). Isso melhora a legibilidade e a manutenibilidade do código SQL.
*   **Variáveis e Loops para Batches**: Se houver a necessidade de processar dados em batches menores ou iterar sobre uma lista de datas, o uso de `DECLARE` para variáveis e estruturas de loop (como `WHILE` ou `FOR`) pode ser explorado. No entanto, para o cenário atual de processamento diário, a abordagem parametrizada é eficiente.

Essas sugestões visam tornar o procedimento mais observável, resiliente a dados inesperados e mais fácil de depurar e manter em um ambiente de produção.



### 3.3. Análise Preliminar de Dados (`ANÁLISEPRELIMINAR.sql`)

Este script SQL contém um conjunto de queries projetadas para realizar uma análise preliminar da qualidade dos dados brutos de ENA na camada RAW do BigQuery. O objetivo é identificar rapidamente potenciais problemas como valores nulos, formatos inválidos, inconsistências e padrões inesperados antes que os dados sejam transformados e carregados na camada TRUSTED. Esta etapa é fundamental para garantir a confiabilidade dos dados que serão utilizados em análises e modelos de IA.

#### 3.3.1. Exemplos de Queries e Justificativa Técnica

O script `ANÁLISEPRELIMINAR.sql` aborda diversas dimensões da qualidade dos dados:

*   **Contagem Total de Registros e Unicidade**: Queries como `SELECT COUNT(*) as total_registros, COUNT(DISTINCT cod_resplanejamento) as reservatorios_unicos FROM ena_raw.tabela_externa_raw_data;` fornecem uma visão geral do volume de dados e da unicidade de identificadores chave. Isso ajuda a verificar se o volume de dados está conforme o esperado e se não há duplicações inesperadas na granularidade do identificador.

*   **Percentual de Nulos por Coluna**: A análise de nulos, exemplificada por `ROUND(100 * SUM(CASE WHEN nom_reservatorio IS NULL OR nom_reservatorio = '' THEN 1 ELSE 0 END) / COUNT(*), 2) as pct_nom_reservatorio_nulo`, é crucial para identificar campos com alta taxa de dados ausentes. Valores nulos podem indicar problemas na fonte de dados ou no processo de ingestão, e seu tratamento adequado é essencial para evitar vieses em análises posteriores.

*   **Estatísticas e Formatos Numéricos**: Queries que verificam `ena_bruta_res_mwmed` como string e usam `REGEXP_CONTAINS` para validar padrões numéricos (`r'^-?[0-9]+([,.][0-9]+)?$'`) são importantes para entender a distribuição dos valores e identificar registros que não se encaixam no formato numérico esperado. Isso é vital antes de realizar `SAFE_CAST` para tipos numéricos, pois valores mal formatados podem levar a `NULL`s ou erros de conversão.

*   **Validade e Range Temporal das Datas**: A verificação de datas com `SAFE_CAST(ena_data AS DATE) IS NULL` e a identificação de `MIN`/`MAX` datas ajudam a garantir que os campos de data estejam em um formato válido e que o período coberto pelos dados esteja correto. Inconsistências em datas podem afetar a análise temporal e o particionamento.

*   **Valores Únicos por Categoria**: Queries `UNION ALL` para campos categóricos como `tip_reservatorio` e `nom_subsistema` permitem entender a variedade e a distribuição dos valores. Isso pode revelar erros de digitação, categorias inesperadas ou a necessidade de padronização.

*   **Qualidade por Partição**: A análise da qualidade dos dados por partição (`REGEXP_EXTRACT(_FILE_NAME, r'dt=([^/]+)')`) é uma prática excelente para identificar problemas que podem estar isolados em datas específicas de ingestão. Isso ajuda a rastrear a origem de problemas de qualidade de dados ao longo do tempo.

*   **Amostra Aleatória para Visualização**: `TABLESAMPLE SYSTEM (10 PERCENT) LIMIT 50` é uma ferramenta prática para obter uma amostra representativa dos dados brutos. Essa amostra pode ser usada para inspeção manual, visualização rápida ou para alimentar ferramentas de exploração de dados, sem a necessidade de processar o conjunto de dados completo.

*   **Dashboard de Qualidade de Dados**: A query final que agrega métricas como `total_registros`, `reservatorios_unicos`, `pct_ena_bruta_ausente`, `pct_datas_validas` e `pct_codigos_invalidos` serve como um resumo executivo da qualidade dos dados. Isso pode ser a base para um dashboard de monitoramento, fornecendo uma visão rápida da saúde do pipeline.

Em suma, a justificativa para estas queries reside na necessidade de **garantir a qualidade dos dados desde a origem**. Ao identificar e quantificar problemas na camada RAW, é possível tomar decisões informadas sobre limpeza, transformação e até mesmo sobre a necessidade de correção na fonte de dados, antes que esses problemas se propaguem para as camadas mais refinadas do data warehouse.

#### 3.3.2. Sugestões de Melhoria

Para elevar o nível da análise preliminar de dados e integrá-la de forma mais eficaz ao pipeline, as seguintes melhorias são recomendadas:

*   **Automação via Scheduled Queries no BigQuery**: As queries de análise preliminar podem ser configuradas como *Scheduled Queries* no BigQuery. Isso permitiria a execução automática diária (ou em outra frequência definida) dessas verificações, gerando relatórios de qualidade de dados de forma proativa. Os resultados poderiam ser armazenados em uma tabela de auditoria ou enviados para um sistema de alerta.
*   **Integração com Ferramentas de Data Governance (Dataform/dbt)**: Para um pipeline de dados mais maduro, a integração com ferramentas como Dataform ou dbt (data build tool) seria altamente benéfica. Essas ferramentas permitem versionar o código SQL, criar testes de qualidade de dados como parte do pipeline de transformação (e.g., `assert not_null(column_name)`, `assert unique(id_column)`), e documentar o lineage dos dados. Isso transformaria a análise preliminar em um componente ativo e automatizado do processo de ETL.
*   **Visualizações Interativas (Looker/Data Studio)**: Os resultados das queries de qualidade de dados podem ser facilmente conectados a ferramentas de visualização como Looker ou Data Studio. A criação de dashboards interativos permitiria que analistas e stakeholders monitorassem a qualidade dos dados em tempo real, identificassem tendências de degradação da qualidade e tomassem ações corretivas de forma mais ágil. Por exemplo, um gráfico mostrando o percentual de nulos por coluna ao longo do tempo seria extremamente útil.
*   **Definição de Limiares e Alertas**: Para cada métrica de qualidade de dados (e.g., percentual de nulos, contagem de registros inválidos), poderiam ser definidos limiares. Se uma métrica exceder um limiar pré-definido, um alerta automático (via Cloud Monitoring, Pub/Sub, ou e-mail) poderia ser disparado para a equipe de engenharia de dados, indicando um problema que requer atenção imediata.
*   **Criação de Views Materializadas para Métricas**: Para queries de qualidade de dados que são executadas frequentemente ou que envolvem grandes volumes de dados, a criação de *views materializadas* no BigQuery pode otimizar o desempenho. Essas views pré-computam os resultados das queries e os armazenam, acelerando o acesso às métricas de qualidade.

Ao implementar essas melhorias, a análise preliminar de dados se tornaria não apenas uma ferramenta de diagnóstico, mas um sistema proativo de garantia de qualidade, essencial para a construção de um data lakehouse confiável e para o suporte a aplicações de IA que dependem de dados de alta qualidade.



### 3.4. Tabela Trusted (`CREATEENA_TRUSTED.sql`)

Este script SQL é responsável pela criação ou substituição da tabela `ena_trusted.tabela_ena_trusted` no BigQuery. Esta tabela representa a camada *trusted* (confiável) do pipeline de dados, onde os dados brutos de ENA, após passarem por processos de limpeza, validação e transformação, são armazenados em um formato otimizado para análise e consumo por aplicações downstream, como relatórios, dashboards e modelos de Machine Learning.

#### 3.4.1. Código Principal
```sql
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
```

#### 3.4.2. Justificativa Técnica

A estrutura e as opções definidas para a `tabela_ena_trusted` refletem as melhores práticas para um data warehouse analítico no BigQuery:

*   **Tipos de Dados Convertidos e Otimizados**: Ao contrário da camada RAW, onde os dados são mantidos como `STRING` para flexibilidade, na camada TRUSTED, os campos são convertidos para seus tipos de dados nativos e mais apropriados (e.g., `INT64`, `FLOAT64`, `DATE`, `TIMESTAMP`). Essa conversão é fundamental por várias razões:
    *   **Otimização de Armazenamento e Desempenho**: Tipos de dados corretos permitem que o BigQuery armazene os dados de forma mais eficiente e execute operações (filtros, agregações, joins) de maneira mais rápida, pois não há necessidade de conversões implícitas em tempo de consulta.
    *   **Precisão Analítica**: Garante que cálculos numéricos e operações de data/hora sejam realizados com precisão, evitando erros que poderiam surgir de manipulações de strings.
    *   **Consistência e Validação**: Reforça a consistência dos dados, pois apenas valores que podem ser convertidos para o tipo especificado são aceitos, atuando como uma forma de validação de schema.

*   **Particionamento por `dt_processamento`**: A cláusula `PARTITION BY dt_processamento` é uma técnica de otimização essencial no BigQuery. Ela organiza a tabela em partições menores com base na data de processamento. Os benefícios incluem:
    *   **Redução de Custos**: Quando as consultas filtram por `dt_processamento`, o BigQuery escaneia apenas as partições relevantes, reduzindo a quantidade de dados processados e, consequentemente, os custos de consulta.
    *   **Melhora de Desempenho**: Consultas que acessam um subconjunto de dados particionados são executadas mais rapidamente, pois o BigQuery pode eliminar partições não necessárias.
    *   **Gerenciamento de Dados**: Facilita a gestão do ciclo de vida dos dados, permitindo a exclusão ou expiração de partições antigas de forma eficiente.

*   **Clustering Implícito e Otimização do BigQuery**: Embora o script não especifique explicitamente `CLUSTER BY`, o BigQuery aplica otimizações de armazenamento e consulta automaticamente. Para tabelas particionadas, o BigQuery pode organizar os dados dentro de cada partição de forma a otimizar o acesso para colunas frequentemente usadas em filtros ou junções (como `cod_resplanejamento` e `ena_data`). Isso é particularmente eficaz para padrões de acesso que envolvem a recuperação de dados para reservatórios específicos em datas específicas.

*   **Descrição da Tabela**: A `OPTIONS(description="...")` é uma boa prática de documentação de dados. Ela fornece metadados importantes sobre a finalidade da tabela, facilitando a compreensão e o uso por outros engenheiros de dados, analistas e cientistas de dados.

#### 3.4.3. Sugestões de Melhoria

Para aprimorar ainda mais a performance e a usabilidade da tabela `ena_trusted`, as seguintes melhorias podem ser consideradas:

*   **Clustering Explícito**: Embora o BigQuery otimize automaticamente, a adição de `CLUSTER BY cod_resplanejamento, ena_data` pode refinar ainda mais a organização física dos dados dentro de cada partição. O clustering organiza os dados com base nos valores das colunas especificadas, o que pode acelerar consultas que filtram ou agregam por essas colunas, especialmente quando elas são frequentemente usadas em conjunto com o particionamento. A escolha das colunas para clustering deve ser baseada nos padrões de consulta mais comuns.
*   **Definição de Chave Primária e Única (Conceitual)**: O BigQuery não impõe chaves primárias ou restrições de unicidade no nível do schema como bancos de dados relacionais tradicionais. No entanto, é uma boa prática documentar conceitualmente quais colunas formam a chave primária (e.g., `cod_resplanejamento` e `ena_data`) e garantir sua unicidade através da lógica do procedimento `MERGE`. Isso é vital para a integridade referencial e para evitar duplicações lógicas.
*   **Índices ou Views Materializadas para Consultas Comuns**: Para consultas de alto desempenho que são executadas com muita frequência e envolvem agregações complexas ou junções, a criação de *views materializadas* pode ser uma solução eficaz. Elas pré-computam os resultados de uma consulta e os armazenam, acelerando significativamente o tempo de resposta. Alternativamente, para cenários específicos, a criação de tabelas agregadas ou sumarizadas pode ser mais apropriada.
*   **Políticas de Expiração de Dados**: Para gerenciar o custo de armazenamento e a conformidade com políticas de retenção de dados, configurar políticas de expiração de dados para a tabela ou para partições específicas. Isso pode ser feito via `DEFAULT TABLE EXPIRATION` ou `PARTITION EXPIRATION` nas opções da tabela, garantindo que dados antigos sejam automaticamente removidos.
*   **Controle de Acesso Granular**: Reforçar o controle de acesso (IAM) na tabela `trusted`, concedendo permissões de leitura apenas para usuários e serviços que realmente precisam acessar esses dados, e permissões de escrita apenas para o serviço que executa o procedimento de atualização (neste caso, a Cloud Function através de sua conta de serviço).

Essas melhorias visam transformar a `tabela_ena_trusted` em um ativo de dados ainda mais valioso, otimizado para desempenho, governança e segurança, e pronto para suportar as demandas analíticas mais exigentes.



### 3.5. Cloud Function (Código Python)

A Cloud Function é o componente de orquestração serverless que atua como o gatilho para a execução do procedimento armazenado no BigQuery. Desenvolvida em Python, esta função é acionada via HTTP e é responsável por receber requisições, extrair parâmetros de data de processamento e invocar o procedimento `sp_atualizar_ena_trusted` no BigQuery. Sua natureza serverless a torna ideal para tarefas de orquestração e automação, sem a necessidade de gerenciar servidores.

#### 3.5.1. Código Principal
```python
import functions_framework
from google.cloud import bigquery
from flask import jsonify
import logging

@functions_framework.http
def run_bigquery_procedure(request):
    """
    Executa o procedimento armazenado do BigQuery para atualizar a tabela ENA.

    A data de processamento é passada como parâmetro para o procedimento.
    1. No body (JSON): { "data": "2025-09-24" }
    2. Na query string: ?data=2025-09-24

    Caso não seja enviada, usa CURRENT_DATE().
    """
    # Configura o logging
    logging.basicConfig(level=logging.INFO)

    try:
        # 1. Verifica se veio na query string
        data_param = request.args.get("data")

        # 2. Se não veio na query, tenta pegar do body JSON
        if not data_param:
            request_json = request.get_json(silent=True) or {}
            data_param = request_json.get("data")

        # Configurações do BigQuery
        client = bigquery.Client()
        project_dataset_procedure = '`affable-elf-472819-k2.ena_trusted.sp_atualizar_ena_trusted`'
        data_usada = ''
        
        # 3. Monta o SQL
        if data_param:
            # CORREÇÃO: Passa a data como uma string literal entre aspas simples ('YYYY-MM-DD').
            # O BigQuery converte essa string para DATE, que é o tipo esperado pelo procedimento.
            sql_command = f"""
                CALL {project_dataset_procedure}('{data_param}');
            """
            data_usada = data_param
        else:
            # Usa CURRENT_DATE() quando nenhuma data é fornecida
            sql_command = f"""
                CALL {project_dataset_procedure}(CURRENT_DATE());
            """
            data_usada = "CURRENT_DATE()"

        logging.info(f"Executando SQL: {sql_command.strip()}")
        
        # Execução do procedimento
        query_job = client.query(sql_command)
        query_job.result()  # Aguarda execução terminar
        
        logging.info("Procedimento executado com sucesso.")
        return jsonify({
            "status": "sucesso",
            "mensagem": "Procedimento BigQuery executado com sucesso.",
            "data_processamento": data_usada
        }), 200
        
    except Exception as e:
        # Loga o erro completo para diagnóstico
        logging.error(f"Erro ao executar o procedimento: {e}", exc_info=True)
        return jsonify({
            "status": "erro",
            "mensagem": f"Erro interno ao executar o procedimento BigQuery. Detalhe: {str(e)}"
        }), 500
```

#### 3.5.2. Justificativa Técnica

A implementação da Cloud Function demonstra uma abordagem eficiente e flexível para a orquestração do pipeline:

*   **Serverless e Escalabilidade Automática**: A principal vantagem de usar Cloud Functions é o modelo serverless. Isso significa que não há servidores para provisionar, gerenciar ou escalar. O GCP cuida de toda a infraestrutura subjacente, permitindo que a função escale automaticamente para lidar com o volume de requisições, desde execuções esporádicas até picos de demanda. O desenvolvedor pode focar apenas na lógica de negócio.
*   **Gatilho HTTP Flexível**: A função é exposta via um gatilho HTTP (`@functions_framework.http`), o que a torna extremamente versátil. Ela pode ser invocada manualmente (para testes ou reprocessamento), por outras aplicações, por serviços de agendamento (como Cloud Scheduler para execuções diárias), ou até mesmo por webhooks. Essa flexibilidade de invocação é um ponto forte do design.
*   **Flexibilidade na Entrada de Dados**: A função inteligentemente aceita o parâmetro `data` tanto via *query string* (`request.args.get(


data")`) quanto via corpo da requisição JSON (`request.get_json().get("data")`). Além disso, ela fornece um *fallback* para `CURRENT_DATE()` do BigQuery caso nenhuma data seja fornecida. Essa flexibilidade torna a função mais amigável e robusta para diferentes cenários de uso.
*   **Integração Direta com BigQuery**: A função utiliza a biblioteca cliente oficial do Google Cloud para Python (`google.cloud.bigquery`) para interagir com o BigQuery. Isso garante uma comunicação segura e eficiente com o serviço. A chamada `client.query(sql_command)` envia a instrução SQL para o BigQuery, e `query_job.result()` garante que a função aguarde a conclusão da execução do procedimento armazenado antes de retornar uma resposta, tornando a operação síncrona do ponto de vista da Cloud Function.
*   **Tratamento de Erros e Logging**: A inclusão de um bloco `try-except` e o uso do módulo `logging` são cruciais para a robustez da função. O `try-except` captura quaisquer exceções que possam ocorrer durante a execução do procedimento BigQuery ou na manipulação dos parâmetros, retornando uma resposta de erro HTTP 500 com uma mensagem descritiva. O `logging.basicConfig(level=logging.INFO)` e as chamadas `logging.info()` e `logging.error()` permitem que os eventos e erros da função sejam registrados no Cloud Logging, facilitando o monitoramento, a depuração e a auditoria da execução do pipeline.
*   **Resposta Padronizada**: A função retorna uma resposta JSON padronizada, indicando o `status` (sucesso ou erro), uma `mensagem` e a `data_processamento` utilizada. Isso facilita a integração com outros sistemas e o consumo da resposta por ferramentas de monitoramento ou orquestração.

#### 3.5.3. Sugestões de Melhoria

Para tornar a Cloud Function ainda mais robusta, segura e eficiente em um ambiente de produção, as seguintes melhorias são recomendadas:

*   **Autenticação e Autorização**: Atualmente, a função é acessível publicamente via HTTP. Para ambientes de produção, é crucial implementar mecanismos de autenticação e autorização. Isso pode ser feito de várias maneiras:
    *   **Cloud IAM**: Restringir o acesso à função apenas a contas de serviço ou usuários específicos via políticas do IAM.
    *   **API Gateway**: Colocar um API Gateway na frente da Cloud Function para gerenciar autenticação (e.g., chaves de API, OAuth 2.0) e autorização, além de fornecer recursos como limitação de taxa e caching.
    *   **Token de ID**: Para invocações internas entre serviços GCP, usar tokens de ID para autenticar chamadas de serviço para serviço.
*   **Execução Assíncrona para Jobs Longos**: Para procedimentos BigQuery que podem levar um tempo considerável para serem concluídos, a abordagem síncrona (`query_job.result()`) pode fazer com que a Cloud Function exceda seu tempo limite de execução (timeout). Uma melhoria seria iniciar o job do BigQuery de forma assíncrona e retornar imediatamente um `job_id` para o cliente. O cliente (ou outro serviço) poderia então consultar o status do job usando esse `job_id`. Isso libera a Cloud Function rapidamente e permite que jobs de longa duração sejam executados em segundo plano.
*   **Monitoramento e Alertas Aprimorados**: Além do logging básico, integrar a função com o Cloud Monitoring para criar métricas personalizadas (e.g., tempo de execução do procedimento, número de vezes que o fallback para `CURRENT_DATE()` foi usado, contagem de erros). Configurar alertas baseados nessas métricas para notificar a equipe de operações sobre falhas ou comportamentos anormais.
*   **Configuração de Variáveis de Ambiente**: Evitar o *hardcoding* de valores como `project_dataset_procedure` diretamente no código. Em vez disso, utilizar variáveis de ambiente (e.g., `os.environ.get('BIGQUERY_PROCEDURE_PATH')`). Isso torna a função mais flexível, fácil de configurar para diferentes ambientes (desenvolvimento, staging, produção) e melhora a segurança, pois credenciais ou IDs de projeto não ficam expostos no código-fonte.
*   **Testes Unitários e de Integração**: Desenvolver testes unitários para a lógica da Cloud Function (e.g., parsing de parâmetros, construção da query SQL) utilizando frameworks como `pytest`. Utilizar *mocks* para simular as interações com o cliente BigQuery, garantindo que a lógica da função funcione conforme o esperado sem a necessidade de executar chamadas reais ao BigQuery. Testes de integração também seriam valiosos para verificar a comunicação ponta a ponta com o BigQuery.
*   **Cloud Scheduler para Agendamento**: Para automação diária ou em intervalos regulares, configurar um job no Cloud Scheduler que invoque a Cloud Function via HTTP. Isso elimina a necessidade de invocações manuais e garante que o pipeline seja executado de forma consistente no horário desejado.
*   **Validação de Entrada Mais Robusta**: Embora a função já lide com a ausência de `data_param`, uma validação mais rigorosa do formato da data (se fornecida) poderia ser implementada para evitar que datas mal formatadas cheguem ao BigQuery e causem erros no procedimento armazenado. Isso pode ser feito com bibliotecas como `datetime` do Python.

Ao implementar essas melhorias, a Cloud Function se tornará um componente ainda mais confiável e de nível de produção, capaz de suportar as demandas de um pipeline de dados crítico.



## 4. Análise Técnica Detalhada e Justificativas Adicionais

### 4.1. Arquitetura Geral e Fluxo de Dados: Uma Visão Integrada

A arquitetura do pipeline de dados ENA é um exemplo clássico de um design moderno de data lakehouse no Google Cloud Platform, combinando a flexibilidade de um data lake (GCS para dados RAW) com as capacidades de processamento e análise de um data warehouse (BigQuery para dados TRUSTED). A orquestração via Cloud Functions adiciona a agilidade e a escalabilidade necessárias para um pipeline de dados eficiente.

O fluxo de dados pode ser visualizado como uma jornada em três estágios principais:

1.  **Ingestão e Armazenamento RAW (GCS + BigQuery External Table)**: Os dados de ENA, tipicamente gerados em sistemas externos, são primeiramente carregados no Google Cloud Storage. A escolha do GCS como camada de armazenamento RAW é estratégica devido à sua durabilidade, escalabilidade ilimitada e baixo custo. Os arquivos são armazenados em formato Parquet, que é um formato colunar otimizado para análise, permitindo compressão eficiente e leitura seletiva de colunas, o que reduz o volume de dados a serem processados. A organização dos dados em diretórios particionados por data (`dt=YYYY-MM-DD`) no GCS é uma prática fundamental para otimização de custos e desempenho em consultas futuras. A tabela externa do BigQuery (`ena_raw.tabela_externa_raw_data`) atua como um *schema-on-read* sobre esses arquivos, permitindo que o BigQuery os consulte diretamente sem a necessidade de ingestão física. Isso oferece flexibilidade, pois o schema pode ser adaptado conforme a necessidade sem alterar os dados subjacentes, e evita a duplicação de dados, mantendo uma única fonte de verdade para os dados brutos.

2.  **Transformação e Enriquecimento (BigQuery Stored Procedure)**: A fase de transformação é orquestrada pelo procedimento armazenado `sp_atualizar_ena_trusted` no BigQuery. Este procedimento é o motor do pipeline, responsável por converter os dados brutos (strings) em tipos de dados apropriados (inteiros, floats, datas), padronizar formatos (e.g., substituição de vírgulas por pontos em números decimais) e aplicar qualquer lógica de negócio necessária para preparar os dados para análise. A instrução `MERGE` é central aqui, pois permite a implementação de uma lógica de *upsert* eficiente. Isso significa que, para cada registro de ENA para um dado reservatório e data, o procedimento verifica se o registro já existe na tabela `ena_trusted`. Se existir, ele é atualizado; caso contrário, é inserido. Essa abordagem garante a idempotência do pipeline, prevenindo duplicações e mantendo a tabela `trusted` sempre atualizada com a versão mais recente e limpa dos dados. O filtro por `_FILE_NAME` dentro do procedimento é uma otimização crucial, garantindo que apenas os dados da partição relevante no GCS sejam lidos, minimizando o volume de dados escaneados e, consequentemente, os custos e o tempo de execução.

3.  **Armazenamento e Consumo TRUSTED (BigQuery Partitioned Table)**: Após a transformação, os dados são armazenados na `ena_trusted.tabela_ena_trusted`. Esta tabela é projetada para ser a fonte de dados para todas as aplicações downstream. Ao contrário da camada RAW, os dados aqui já estão limpos, tipados corretamente e prontos para uso. O particionamento da tabela por `dt_processamento` (data em que o registro foi processado e carregado na camada trusted) é uma otimização chave. Isso permite que as consultas que filtram por data (um padrão de uso muito comum em análises de séries temporais) escaneiem apenas um subconjunto dos dados, resultando em desempenho superior e custos reduzidos. A estrutura da tabela `trusted` é otimizada para consultas analíticas, com tipos de dados que permitem operações numéricas e temporais eficientes, tornando-a ideal para relatórios, dashboards e como base para modelos de Machine Learning.

### 4.2. Justificativa das Escolhas Tecnológicas (GCP)

As escolhas de tecnologias do Google Cloud Platform (GCP) para este projeto não foram arbitrárias, mas sim fundamentadas em uma análise cuidadosa dos requisitos de escalabilidade, custo, manutenção e integração. A combinação de Cloud Storage, BigQuery e Cloud Functions oferece uma solução robusta e moderna para o pipeline de dados de ENA.

*   **Google Cloud Storage (GCS) para Data Lake**: O GCS é a escolha natural para um data lake devido à sua **escalabilidade ilimitada**, **durabilidade de 99.999999999% (11 noves)** e **custo-benefício** para armazenamento de grandes volumes de dados. Ele suporta diversos formatos de arquivo, sendo o Parquet uma excelente opção para dados estruturados. A integração nativa com o BigQuery via tabelas externas simplifica a arquitetura, eliminando a necessidade de mover dados para o BigQuery para consulta, o que seria custoso e demorado.

*   **BigQuery para Data Warehouse e Processamento**: O BigQuery é um data warehouse analítico **serverless e altamente escalável**, projetado para lidar com petabytes de dados. Suas principais vantagens incluem:
    *   **Desempenho Inigualável**: Capaz de executar consultas complexas sobre enormes volumes de dados em segundos, graças à sua arquitetura colunar e processamento massivamente paralelo.
    *   **Gerenciamento Zero de Infraestrutura**: Elimina a necessidade de provisionar, escalar ou manter servidores, permitindo que a equipe se concentre na análise de dados em vez da administração de banco de dados.
    *   **Modelo de Custos Otimizado**: O modelo de pagamento por dados escaneados incentiva a otimização de consultas e o uso de particionamento/clustering, resultando em custos previsíveis e controláveis.
    *   **Suporte a SQL Padrão**: Facilita a adoção por equipes familiarizadas com SQL e permite a criação de procedimentos armazenados complexos para lógica de ETL.
    *   **Ecossistema Rico**: Integra-se perfeitamente com outras ferramentas GCP, como Data Studio, Looker e Vertex AI, para visualização e Machine Learning.

*   **Cloud Functions para Orquestração Serverless**: A Cloud Function é a cola que une o GCS e o BigQuery neste pipeline. Suas vantagens são:
    *   **Serverless e Pagamento por Uso**: Executa código em resposta a eventos HTTP sem a necessidade de gerenciar servidores, cobrando apenas pelo tempo de execução e número de invocações. Isso é ideal para tarefas de orquestração que podem ser disparadas sob demanda ou agendadas.
    *   **Desenvolvimento Ágil**: Permite o desenvolvimento rápido de funções em Python (ou outras linguagens), com foco na lógica de negócio específica para orquestrar o pipeline.
    *   **Integração com o Ecossistema GCP**: Facilita a interação com outros serviços GCP, como BigQuery, Cloud Storage e Cloud Scheduler, através das bibliotecas cliente oficiais.
    *   **Manutenção Simplificada**: Reduz a carga operacional, pois o GCP gerencia o ambiente de execução, atualizações e patches de segurança.

Em conjunto, essas tecnologias formam uma arquitetura moderna e eficiente, que capitaliza os pontos fortes de cada serviço GCP para construir um pipeline de dados robusto, escalável e de baixo custo, capaz de suportar as demandas atuais e futuras de análise de dados de ENA e integração com soluções de IA.




## 5. Identificação de Melhorias e Boas Práticas

Com base na análise detalhada dos componentes do pipeline de dados ENA, diversas oportunidades de melhoria e a adoção de boas práticas podem ser identificadas para aprimorar ainda mais a robustez, a eficiência, a segurança e a manutenibilidade do projeto. Estas sugestões abrangem desde otimizações de código até a implementação de mecanismos de governança e monitoramento.

### 5.1. Melhorias para a Tabela Externa Raw

A camada RAW, embora funcional, pode ser otimizada para melhor desempenho e governança. A principal recomendação é a adoção do particionamento por Hive e a imposição de filtros de partição obrigatórios. A inclusão da opção `hive_partitioning_mode = 'AUTO'` nas `OPTIONS` da tabela externa permitiria que o BigQuery inferisse automaticamente as partições baseadas na estrutura de diretórios do GCS (e.g., `dt=YYYY-MM-DD`). Isso otimizaria significativamente as consultas que filtram por data, pois o BigQuery seria capaz de pular diretórios não relevantes, reduzindo a quantidade de dados escaneados e, consequentemente, os custos e o tempo de execução. Atualmente, o filtro é feito via `_FILE_NAME` na `MERGE` statement, o que é funcional, mas a inferência de partição pelo BigQuery é inerentemente mais eficiente. Adicionalmente, a opção `require_partition_filter = TRUE` nas `OPTIONS` forçaria os usuários a incluir uma cláusula `WHERE` que filtre por partição em suas consultas à tabela externa. Esta é uma medida de governança de dados que ajuda a evitar varreduras completas da tabela (full table scans) acidentais, que podem ser custosas em grandes volumes de dados. Embora o procedimento armazenado já filtre por `_FILE_NAME`, essa opção adicionaria uma camada de segurança para consultas ad-hoc. Para garantir a consistência dos dados, especialmente em um ambiente onde a fonte de dados pode variar, a implementação de validações de schema no GCS (por exemplo, usando ferramentas como o Apache Avro ou Parquet com schema definido) antes da ingestão poderia ser benéfica. Embora o BigQuery seja tolerante a schemas, a validação antecipada pode prevenir erros a jusante no pipeline.

### 5.2. Melhorias para o Procedimento Armazenado do BigQuery

O procedimento armazenado é o motor de transformação e, como tal, se beneficia de melhorias em observabilidade e resiliência. A implementação de um mecanismo de logging mais detalhado é fundamental. Isso pode ser feito inserindo registros em uma tabela de log dedicada que capture informações como o status da execução (sucesso/falha), a data de processamento, o número de registros inseridos/atualizados e mensagens de erro. Este logging é crucial para depuração e monitoramento da saúde do pipeline em produção. Além disso, adicionar validações explícitas para cenários específicos, como verificar se a partição de dados para `p_data_processamento` existe na camada RAW antes de tentar processá-la, aumentaria a robustez. Se a partição estiver vazia ou não existir, o procedimento poderia registrar um aviso ou erro e sair, em vez de tentar processar dados inexistentes. A instrução `IF COUNT(*) = 0 THEN RAISE ERROR` pode ser usada para interromper a execução em caso de condições inesperadas. Para procedimentos mais complexos, considerar a criação de funções auxiliares ou sub-procedimentos para encapsular lógicas específicas, melhorando a legibilidade e a manutenibilidade do código SQL.

### 5.3. Melhorias para a Análise Preliminar de Dados

A análise preliminar de dados é uma etapa crítica para a garantia de qualidade e pode ser aprimorada através de automação e integração com ferramentas de governança. As queries de análise preliminar podem ser configuradas como *Scheduled Queries* no BigQuery, permitindo a execução automática diária ou em outra frequência definida, gerando relatórios de qualidade de dados de forma proativa. Os resultados poderiam ser armazenados em uma tabela de auditoria ou enviados para um sistema de alerta. Para um pipeline de dados mais maduro, a integração com ferramentas como Dataform ou dbt (data build tool) seria altamente benéfica, permitindo versionar o código SQL, criar testes de qualidade de dados como parte do pipeline de transformação e documentar o *lineage* dos dados. Os resultados das queries de qualidade de dados podem ser facilmente conectados a ferramentas de visualização como Looker ou Data Studio para a criação de dashboards interativos, permitindo que analistas e stakeholders monitorem a qualidade dos dados em tempo real. Para cada métrica de qualidade de dados, poderiam ser definidos limiares, e se uma métrica exceder um limiar pré-definido, um alerta automático (via Cloud Monitoring, Pub/Sub, ou e-mail) poderia ser disparado. Para queries de qualidade de dados que são executadas frequentemente ou que envolvem grandes volumes de dados, a criação de *views materializadas* no BigQuery pode otimizar o desempenho.

### 5.4. Melhorias para a Tabela Trusted

A tabela TRUSTED é a base para o consumo de dados e pode ser otimizada para desempenho e governança. A adição de `CLUSTER BY cod_resplanejamento, ena_data` pode refinar ainda mais a organização física dos dados dentro de cada partição, acelerando consultas que filtram ou agregam por essas colunas. Embora o BigQuery não imponha chaves primárias, é uma boa prática documentar conceitualmente quais colunas formam a chave primária e garantir sua unicidade através da lógica do procedimento `MERGE`. Para consultas de alto desempenho que são executadas com muita frequência e envolvem agregações complexas, a criação de *views materializadas* pode ser uma solução eficaz. Para gerenciar o custo de armazenamento e a conformidade com políticas de retenção de dados, configurar políticas de expiração de dados para a tabela ou para partições específicas. Reforçar o controle de acesso (IAM) na tabela `trusted`, concedendo permissões de leitura apenas para usuários e serviços que realmente precisam acessar esses dados, e permissões de escrita apenas para o serviço que executa o procedimento de atualização.

### 5.5. Melhorias para a Cloud Function

A Cloud Function, como orquestrador, pode ser aprimorada em termos de segurança, resiliência e monitoramento. A implementação de mecanismos de autenticação e autorização é crucial, como restringir o acesso via Cloud IAM, colocar um API Gateway na frente da função, ou usar tokens de ID para invocações internas. Para procedimentos BigQuery que podem levar um tempo considerável, uma melhoria seria iniciar o job do BigQuery de forma assíncrona e retornar imediatamente um `job_id` para o cliente, liberando a Cloud Function rapidamente. Além do logging básico, integrar a função com o Cloud Monitoring para criar métricas personalizadas e configurar alertas baseados nessas métricas. Evitar o *hardcoding* de valores como `project_dataset_procedure` utilizando variáveis de ambiente, tornando a função mais flexível e segura. Desenvolver testes unitários e de integração para a lógica da Cloud Function, utilizando *mocks* para simular as interações com o cliente BigQuery. Para automação diária, configurar um job no Cloud Scheduler que invoque a Cloud Function via HTTP. Por fim, uma validação mais rigorosa do formato da data (se fornecida) poderia ser implementada para evitar que datas mal formatadas cheguem ao BigQuery e causem erros no procedimento armazenado.

