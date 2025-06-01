# API de Administração: Ferramentas do Sistema

Esta seção da API de Administração \"Deeper\" fornece endpoints para diversas ferramentas e utilitários de sistema, auxiliando no monitoramento, manutenção e diagnóstico da plataforma.

**Autenticação:** Requerida (nível de superadministrador ou permissões específicas para cada ferramenta).

## Objetivos da API de Ferramentas do Sistema:

*   Permitir o gerenciamento de caches do sistema.
*   Fornecer acesso a logs da aplicação (em um formato gerenciável).
*   Exibir informações do servidor e do ambiente da aplicação.
*   (Opcional) Gerenciar tarefas agendadas (se \"Deeper\" implementar um sistema de cron jobs interno).
*   (Opcional) Executar verificações de integridade do sistema ou diagnósticos.

## 1. Gerenciamento de Cache (`/api/v1/admin/system-tools/cache`)

Se o backend \"Deeper\" utilizar caches (ex: ETS, Agentes, Redis, Memcached) para configurações, dados frequentemente acessados, etc.

### `GET /api/v1/admin/system-tools/cache/status`
*   **Descrição:** Obtém o status dos diferentes caches utilizados pela aplicação.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"name\": \"sys_options_cache\",
          \"type\": \"Agent\", // ou \"ETS\", \"Redis\"
          \"status\": \"active\",
          \"size_items\": 150, // Número de itens cacheados
          \"memory_usage_kb\": 256, // Uso de memória aproximado
          \"last_cleared_at\": \"2023-10-28T10:00:00Z\" // Opcional
        },
        {
          \"name\": \"acl_permissions_cache\",
          \"type\": \"ETS\",
          \"status\": \"active\",
          \"size_items\": 5000,
          \"memory_usage_kb\": 1024
        }
        // ... mais status de cache
      ]
    }
```

```json
    {
      \"cache_name\": \"sys_options_cache\" // Opcional. Se omitido, limpa todos os caches permitidos.
                                        // Pode ser \"all\" para limpar todos.
    }
```

```json
    {
      \"message\": \"Cache 'sys_options_cache' cleared successfully.\"
      // ou \"All specified caches cleared.\"
    }
```

```json
    {
      \"data\": [
        {
          \"timestamp\": \"2023-10-28T12:34:56.789Z\",
          \"level\": \"ERROR\",
          \"module\": \"Deeper.Content.MarketRepo\",
          \"function\": \"create_entry/1\",
          \"message\": \"Failed to insert entry into database: constraint violation.\",
          \"metadata\": { \"user_id\": 123, \"params\": { \"title\": \"Test\" } } // Logger metadata
        }
        // ... mais entradas de log
      ],
      \"next_offset_token\": \"c3Rาร์ท...\" // Para paginação por cursor
    }
```

```json
    {
      \"data\": {
        \"application_name\": \"Deeper\",
        \"application_version\": \"1.0.2\", // Versão da aplicação Deeper
        \"elixir_version\": \"1.15.7\",
        \"erlang_otp_version\": \"26.1\",
        \"phoenix_version\": \"1.7.10\", // Se usando Phoenix
        \"environment\": \"production\", // config_env()
        \"uptime_seconds\": 7200,
        \"os\": {
          \"type\": \"linux\", // :os.type()
          \"version\": \"Ubuntu 22.04 LTS\" // Detalhes específicos do OS
        },
        \"memory\": {
          \"total_system_gb\": 16,
          \"beam_process_mb\": 256, // Memória usada pelo processo BEAM
          \"beam_total_alloc_mb\": 512 // Memória total alocada pela BEAM
        },
        \"cpu_info\": {
          \"logical_processors\": 8,
          \"schedulers_online\": 8
        },
        \"database\": {
            \"adapter\": \"SQLite3\",
            \"status\": \"connected\",
            \"version\": \"3.39.4\" // Versão do SQLite
        }
        // Adicionar outras informações relevantes, como status de serviços externos (Redis, etc.)
      }
    }
```

```json
    {
      \"data\": [
        {
          \"name\": \"cleanup_expired_sessions\",
          \"schedule\": \"0 0 * * *\", // Cron expression
          \"next_run_at\": \"2023-10-29T00:00:00Z\",
          \"last_run_at\": \"2023-10-28T00:00:00Z\",
          \"last_run_status\": \"success\", // \"success\", \"failed\"
          \"is_enabled\": true
        }
      ]
    }
```

### `POST /api/v1/admin/system-tools/cache/clear`
*   **Descrição:** Limpa um ou todos os caches do sistema.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:** Invoca as funções apropriadas para limpar os caches especificados.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400 Bad Request` (nome de cache inválido).

## 2. Visualizador de Logs da Aplicação (`/api/v1/admin/system-tools/logs`)

Fornece acesso aos logs da aplicação Elixir (gerados pelo `Logger` do Elixir ou bibliotecas de logging). **Cuidado:** Expor logs via API requer atenção à segurança e ao volume de dados.

### `GET /api/v1/admin/system-tools/logs`
*   **Descrição:** Busca e lista entradas de log da aplicação.
*   **Query Parameters:**
    *   `level` (string, ex: `\"error\"`, `\"warn\"`, `\"info\"`, `\"debug\"`).
    *   `start_time` (ISO 8601 string ou Unix timestamp).
    *   `end_time` (ISO 8601 string ou Unix timestamp).
    *   `search_term` (string, para buscar no texto do log).
    *   `module_filter` (string, para filtrar por módulo que gerou o log, se disponível).
    *   `limit` (integer, default 100, para limitar o número de entradas retornadas).
    *   `offset_token` (string, para paginação baseada em cursor, se os logs forem muito volumosos).
*   **Lógica do Backend:**
    *   Interage com o backend de logging configurado (ex: ler de um arquivo de log, consultar um sistema de logging centralizado como ELK, se aplicável).
    *   A leitura direta de arquivos de log grandes via API pode ser ineficiente; considerar ferramentas especializadas para análise de logs. Esta API seria para visualização rápida das entradas mais recentes ou específicas.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400 Bad Request` (parâmetros inválidos).

## 3. Informações do Sistema/Servidor (`/api/v1/admin/system-tools/info`)

### `GET /api/v1/admin/system-tools/info`
*   **Descrição:** Exibe informações sobre o ambiente da aplicação Elixir e o servidor.
*   **Lógica do Backend:** Coleta informações usando funções do Erlang/Elixir (`:erlang.system_info`, `Application.spec/1`, etc.).
*   **Resposta de Sucesso (200 OK):**

## 4. Gerenciamento de Tarefas Agendadas (Cron Jobs - Opcional)

Se \"Deeper\" implementar um sistema interno para tarefas agendadas (ex: usando Quantum ou Oban, ou um GenServer customizado):

### `GET /api/v1/admin/system-tools/cron-jobs`
*   **Descrição:** Lista todas as tarefas agendadas configuradas e seu status.
*   **Resposta de Sucesso (200 OK):**

### `POST /api/v1/admin/system-tools/cron-jobs/{job_name}/trigger`
*   **Descrição:** Dispara manualmente a execução de uma tarefa agendada (fora do seu schedule).
*   **Resposta de Sucesso (202 Accepted):** Indica que o job foi enfileirado para execução.

### `POST /api/v1/admin/system-tools/cron-jobs/{job_name}/toggle`
*   **Descrição:** Habilita ou desabilita uma tarefa agendada.
*   **Corpo da Requisição (JSON):** `{\"enable\": true}` ou `{\"enable\": false}`.
*   **Resposta de Sucesso (200 OK):** Status atualizado do job.

## Considerações para API de Ferramentas do Sistema:

*   **Segurança:** Expor informações do sistema e logs requer cuidado extremo. O acesso deve ser restrito a superadministradores. Evitar expor informações sensíveis (chaves, senhas) nos logs ou info do sistema.
*   **Performance:** A leitura de logs ou a coleta de informações detalhadas do sistema podem ser operações intensivas. Implementar com cuidado para não impactar a performance da aplicação principal.
*   **Abstração:** Para logs e cron jobs, a API deve abstrair a biblioteca específica usada no backend (ex: Logger, Quantum) para fornecer uma interface consistente.

Esta API fornecerá aos administradores visibilidade e controle sobre aspectos operacionais importantes da plataforma \"Deeper\".