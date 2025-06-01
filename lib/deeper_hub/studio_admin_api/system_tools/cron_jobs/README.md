# Documentação Deeper Studio API: Gerenciamento de Tarefas Agendadas (`sys_cron_jobs`)

Este documento descreve os endpoints da API de Administração (\"Studio API\") para visualizar e, potencialmente, interagir com as tarefas agendadas (cron jobs) definidas na tabela `sys_cron_jobs` do sistema UNA.

**Objetivo Principal:** Permitir que administradores monitorem as tarefas agendadas, vejam quando foram executadas pela última vez, e possivelmente as disparem manualmente para fins de teste ou manutenção.

**Nota sobre Execução:** A API \"Deeper\" (Elixir) não executará diretamente os scripts PHP definidos em `sys_cron_jobs.file` ou `sys_cron_jobs.class`. O sistema de cron do servidor original do UNA é responsável por isso. Esta API servirá principalmente para *visualizar* o estado dessas tarefas conforme registrado no banco de dados e, se a API \"Deeper\" implementar funcionalidades equivalentes em Elixir para esses cron jobs, ela poderia oferecer uma forma de dispará-los.

## Tabelas Relevantes:

*   **`sys_cron_jobs`**: Define as tarefas agendadas.
    *   Campos chave: `id`, `name`, `time` (expressão cron), `file` (arquivo PHP), `class` (classe PHP), `service_call` (formato serializado para chamada de serviço), `ts` (timestamp da última execução), `timing` (duração da última execução).

## Módulo de Acesso a Dados (`Deeper.SystemTools.CronJobsRepo` - Hipotético):

*   Precisará de funções para:
    *   Listar todas as tarefas de `sys_cron_jobs`.
    *   Obter detalhes de uma tarefa específica.
    *   Atualizar o `ts` (timestamp da última execução) e `timing` de uma tarefa (se a API \"Deeper\" for simular ou registrar execuções de tarefas Elixir equivalentes).

## Endpoints da API de Admin para Tarefas Agendadas (`/api/v1/admin/system/cron-jobs`):

### 1. Listar Todas as Tarefas Agendadas

*   **Endpoint:** `GET /api/v1/admin/system/cron-jobs`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `sort_by` (ex: `name_asc`, `last_run_ts_desc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"Limpador de Sessões Antigas\",
          \"cron_expression\": \"0 0 * * *\", // sys_cron_jobs.time
          \"script_path\": \"inc/classes/BxDolSessionQuery.php\", // sys_cron_jobs.file
          \"class_name\": \"BxDolSessionQuery\", // sys_cron_jobs.class
          \"service_call_details\": null, // Parseado de sys_cron_jobs.service_call se aplicável
          \"last_run_timestamp\": 1679000000, // sys_cron_jobs.ts
          \"last_run_duration_seconds\": 0.52 // sys_cron_jobs.timing
        }
        // ... outras tarefas ...
      ]
    }
```

```json
    {
      \"data\": {
        \"message\": \"Deeper task '{job_name_deeper}' triggered successfully.\",
        \"job_name\": \"elixir_session_cleaner_task\",
        \"status\": \"queued\" // ou \"running\" ou \"completed\" se síncrono
      }
    }
```

### 2. Obter Detalhes de uma Tarefa Agendada Específica

*   **Endpoint:** `GET /api/v1/admin/system/cron-jobs/{job_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna todos os campos da tarefa `sys_cron_jobs` com `id = job_id`.

### 3. (Opcional) Disparar Manualmente uma Tarefa Agendada \"Deeper\"

*   **Endpoint:** `POST /api/v1/admin/system/cron-jobs/{job_name_deeper}/trigger`
*   **Path Parameter:** `job_name_deeper` (um nome para uma tarefa Elixir equivalente, não necessariamente o `sys_cron_jobs.name` do PHP).
*   **Autenticação:** Requer JWT de Admin.
*   **Descrição:** Este endpoint não executaria o script PHP original. Em vez disso, se a aplicação \"Deeper\" reimplementar a lógica de um cron job específico em Elixir (ex: limpeza de tokens expirados, agregação de dados), este endpoint poderia disparar essa tarefa Elixir manualmente.
*   **Corpo da Requisição:** Vazio ou com parâmetros específicos para a tarefa Elixir.
*   **Resposta de Sucesso (202 Accepted ou 200 OK):**

*   **Lógica do Backend:**
    1.  Identifica a tarefa Elixir correspondente a `job_name_deeper`.
    2.  Dispara a tarefa (ex: enviando uma mensagem para um GenServer, enfileirando um job com Oban/Exq se usados).
    3.  (Opcional) Se esta tarefa Elixir tem um correspondente em `sys_cron_jobs` para fins de log de execução, pode chamar `CronJobsRepo.update_job_run_timestamp(corresponding_sys_cron_job_id, System.os_time(:second))`.

## Migrações para `sys_cron_jobs`:

*   A migração para `sys_cron_jobs` precisará ser adicionada ao diretório `migrations/` desta seção.

## Considerações:

*   **Execução de Tarefas PHP:** A API \"Deeper\" **não** deve tentar executar os scripts PHP listados em `sys_cron_jobs`. Isso seria um risco de segurança e adicionaria complexidade desnecessária. A tabela `sys_cron_jobs` é lida principalmente para fins de informação e monitoramento do que o sistema UNA *deveria* estar fazendo.
*   **Reimplementação em Elixir:** Se a funcionalidade de um cron job do UNA for crítica para a operação da \"Deeper\" (ex: expiração de dados, agregações), essa lógica deve ser reimplementada em Elixir, possivelmente usando uma biblioteca de agendamento como `Quantum` ou processos supervisionados. O endpoint \"trigger\" acima seria para essas versões Elixir.
*   **Atualização de `ts` e `timing`:** Se as tarefas reimplementadas em Elixir correspondem a entradas em `sys_cron_jobs`, elas devem atualizar `ts` (timestamp da última execução) e `timing` (duração) para que o status no UNA Studio (se ainda usado) reflita a atividade.

Esta API fornece uma visão sobre as tarefas agendadas e uma ponte para executar tarefas equivalentes implementadas em Elixir.