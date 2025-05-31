# Documentação Deeper: Módulo de Acesso a Dados para Tarefas Agendadas (`Deeper.SystemTools.CronJobsRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemTools.CronJobsRepo`. Sua responsabilidade é interagir com a tabela `sys_cron_jobs` para fornecer informações sobre as tarefas agendadas do sistema UNA.

Este repositório será usado principalmente pela API de Administração para listar e visualizar detalhes dos cron jobs. Funções de escrita (como atualizar `ts` e `timing`) seriam usadas se tarefas Elixir equivalentes fossem implementadas e precisassem registrar seu status na tabela `sys_cron_jobs` por compatibilidade ou para monitoramento centralizado.

## Responsabilidades Principais:

*   Listar todas as tarefas agendadas de `sys_cron_jobs`.
*   Obter detalhes de uma tarefa específica pelo seu `id` ou `name`.
*   (Opcional) Atualizar o timestamp da última execução (`ts`) e a duração (`timing`) de uma tarefa.

## Funções Públicas Principais e Lógica SQL:

*   **`list_cron_jobs(opts :: Keyword.t()) :: {:ok, cron_jobs :: list(map())} | {:error, any()}`**
    *   `opts`: Pode incluir `sort_by` (ex: `name`, `ts`), `sort_order` (`asc`, `desc`).
    *   SQL: `SELECT id, name, time, class, file, service_call, ts, timing FROM sys_cron_jobs ORDER BY ? ?;`
        *   A ordenação precisa ser construída dinamicamente com segurança.
    *   Mapeia cada linha para um mapa. O campo `service_call` (se for uma string PHP serializada) pode ser retornado como está, ou uma tentativa de parse para JSON (se for JSON) pode ser feita. Para o `time` (expressão cron), pode ser útil adicionar um campo \"próxima execução prevista\" calculado em Elixir se uma biblioteca de parsing cron for usada.

*   **`get_cron_job_by_id(job_id :: integer()) :: {:ok, cron_job :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_cron_jobs WHERE id = ? LIMIT 1;`
    *   Retorna um mapa com todos os campos ou `{:error, :not_found}`.

*   **`get_cron_job_by_name(job_name :: String.t()) :: {:ok, cron_job :: map()} | {:error, :not_found | any()}`**
    *   SQL: `SELECT * FROM sys_cron_jobs WHERE name = ? LIMIT 1;`

*   **`update_cron_job_run_status(job_id :: integer(), last_run_ts :: integer(), duration_seconds :: float()) :: :ok | {:error, :not_found | any()}`**
    *   Usado se uma tarefa Elixir equivalente a um `sys_cron_jobs` for executada e precisar atualizar o registro.
    *   SQL: `UPDATE sys_cron_jobs SET ts = ?, timing = ? WHERE id = ?;`
    *   Retorna `:ok` ou um erro se o `job_id` não for encontrado.

*   **`update_cron_job_run_status_by_name(job_name :: String.t(), last_run_ts :: integer(), duration_seconds :: float()) :: :ok | {:error, :not_found | any()}`**
    *   Similar ao anterior, mas usa o `name` do job.
    *   SQL: `UPDATE sys_cron_jobs SET ts = ?, timing = ? WHERE name = ?;`

## Considerações:

*   **Parsing de `time` (Expressão Cron):** A API pode querer retornar não apenas a string da expressão cron, mas também uma interpretação ou a próxima data/hora de execução prevista. Bibliotecas Elixir como `Cronex` ou `Crontab` podem ser usadas para parsear e calcular isso.
*   **Parsing de `service_call`:** Se `service_call` for uma string PHP serializada, a API \"Deeper\" provavelmente a retornará como está. Se for JSON, pode ser parseada.
*   **Segurança:** Este repositório, especialmente as funções de atualização, deve ser usado apenas por código administrativo confiável.

Este `CronJobsRepo` fornece a interface de dados para monitorar (e opcionalmente interagir com o log de execução de) tarefas agendadas.