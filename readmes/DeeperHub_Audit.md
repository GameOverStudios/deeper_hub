# Módulo: `DeeperHub.Audit` 📝

## 📜 1. Visão Geral do Módulo `DeeperHub.Audit`

O módulo `DeeperHub.Audit` é responsável por registrar e gerenciar uma trilha de auditoria compreensiva de todas as ações e eventos significativos que ocorrem dentro do sistema DeeperHub. Seu propósito principal é fornecer um registro imutável e detalhado para fins de segurança, conformidade, análise forense, monitoramento de atividades de usuários e depuração. 😊

Ele captura quem fez o quê, quando e com qual resultado, abrangendo desde ações de usuários até eventos de sistema e alterações de configuração.

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Registro de Eventos de Auditoria:**
    *   Logar eventos de diversas categorias: ações de usuário (login, logout, CRUD de entidades), eventos de segurança (falhas de autenticação, alterações de permissão), eventos de sistema (inicialização, desligamento, erros críticos), alterações de configuração.
    *   Capturar informações contextuais relevantes: `user_id` (quem realizou a ação), `ip_address`, `user_agent`, `trace_id` (para rastreamento distribuído), `resource_type`, `resource_id`, detalhes da ação, dados antigos e novos (para alterações).
    *   Suporte a diferentes níveis de severidade para eventos de auditoria.
*   **Armazenamento de Logs de Auditoria:**
    *   Persistir logs de auditoria de forma segura e, idealmente, imutável ou com detecção de adulteração.
    *   Utilizar o `DeeperHub.Core.Repo` para armazenamento, possivelmente em uma tabela dedicada (ou coleção, se NoSQL).
*   **Consulta e Busca de Logs:**
    *   Fornecer uma API para buscar e filtrar logs de auditoria por diversos critérios (usuário, tipo de evento, data, recurso, severidade, etc.).
    *   Suporte a paginação e ordenação dos resultados da busca.
*   **Políticas de Retenção:**
    *   Implementar e aplicar políticas de retenção para logs de auditoria (ex: manter logs por X dias/meses/anos).
    *   Suporte para arquivamento de logs antigos em storage de baixo custo antes da exclusão.
    *   Agendamento de tarefas de limpeza e arquivamento (via `Core.BackgroundTaskManager`).
*   **Relatórios de Auditoria:**
    *   Geração de relatórios de auditoria para análise de atividades de usuários, eventos de segurança, etc.
    *   Exportação de logs e relatórios em diferentes formatos (CSV, JSON, PDF).
*   **Detecção de Anomalias (Básica ou Integração):**
    *   Análise de logs para identificar padrões suspeitos ou anormais (ex: múltiplas falhas de login, acesso de IPs incomuns).
    *   Pode integrar-se com `DeeperHub.Security.FraudDetection` ou `DeeperHub.Security.BehavioralAnalysis` para análises mais complexas.
*   **Integridade e Segurança dos Logs:**
    *   Mecanismos para garantir a integridade dos logs (ex: hashing, assinaturas).
    *   Controle de acesso para consulta e gerenciamento de logs de auditoria (via `DeeperHub.RBAC`).
*   **Interface de Auditoria (Opcional):**
    *   Fornecer uma interface (possivelmente via `DeeperHub.Console` ou uma UI de admin) para administradores consultarem logs.

## 🏗️ 3. Arquitetura e Design

O módulo `DeeperHub.Audit` será uma fachada que coordena diferentes componentes para registro, armazenamento e consulta de logs.

*   **Interface Pública (`DeeperHub.Audit.AuditFacade`):** Define as funções como `log_event/4`, `search_events/2`, `export_events/3`.
*   **Serviço de Logging (`DeeperHub.Audit.Services.LoggingService`):** Responsável por receber eventos de diferentes partes da aplicação, enriquecê-los com metadados e formatá-los.
*   **Serviço de Armazenamento (`DeeperHub.Audit.Services.AuditStorageService`):** Lida com a persistência dos logs de auditoria (via `Core.Repo`) e com a lógica de retenção e arquivamento.
*   **Serviço de Consulta (`DeeperHub.Audit.Services.QueryService`):** Implementa a lógica para buscar e filtrar logs.
*   **Serviço de Relatórios (`DeeperHub.Audit.Services.AuditReportingService`):** Gera relatórios e exporta dados.
*   **Schema (`DeeperHub.Audit.AuditLog`):** Define a estrutura do log de auditoria no banco de dados.
*   **Workers (ex: `DeeperHub.Audit.Workers.AuditLogWorker`, `DeeperHub.Audit.Scheduler.RetentionScheduler`):** Para processamento assíncrono de logs e execução de políticas de retenção.
*   **Integrações (`DeeperHub.Audit.Integrations.*`):** Módulos específicos para logar eventos de outros contextos (ex: `Auth`, `Accounts`, `API`).

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica a interação com o sistema de auditoria.
*   **Produtor/Consumidor (com Workers):** Eventos são produzidos por toda a aplicação e consumidos/processados assincronamente por workers de auditoria.
*   **Strategy (Opcional):** Para diferentes formatos de exportação ou backends de armazenamento de arquivamento.

### 3.1. Componentes Principais

*   **`DeeperHub.Audit.AuditFacade`:** Ponto de entrada para logar e consultar eventos.
*   **`DeeperHub.Audit.Services.LoggingService`:** Orquestra o recebimento e formatação dos logs.
*   **`DeeperHub.Audit.AuditLog` (Schema):** Estrutura de dados do log.
*   **`DeeperHub.Audit.Workers.AuditLogWorker`:** Processa e persiste logs de forma assíncrona.
*   **`DeeperHub.Audit.Scheduler.RetentionScheduler`:** Gerencia a aplicação de políticas de retenção.
*   **`DeeperHub.Audit.Policies.RetentionPolicy`:** Define as regras de retenção.
*   **`DeeperHub.Audit.Supervisor`:** Supervisiona os processos do módulo.

### 3.3. Decisões de Design Importantes

*   **Processamento Assíncrono:** Para evitar que o logging de auditoria impacte a performance das operações principais, os logs devem ser processados e persistidos assincronamente.
*   **Estrutura do Log:** Definir uma estrutura de log rica e padronizada é crucial para permitir buscas e análises eficientes.
*   **Imutabilidade (ou detecção de adulteração):** Garantir que os logs, uma vez escritos, não possam ser alterados ou que alterações sejam detectáveis.
*   **Performance de Escrita e Leitura:** Otimizar para alta taxa de escrita de logs e consultas eficientes, especialmente em grandes volumes de dados.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário faz Login:** O módulo `DeeperHub.Auth` chama `AuditFacade.log_event/4` para registrar a tentativa de login (sucesso ou falha), incluindo `user_id`, `ip_address`, `timestamp`.
*   **Administrador Altera Configuração Crítica:** O módulo `DeeperHub.Admin` chama `AuditFacade.log_event/4` para registrar a alteração, incluindo `admin_id`, chave da configuração, valor antigo e novo.
*   **Sistema Detecta Atividade Suspeita:** O módulo `DeeperHub.Security.FraudDetection` chama `AuditFacade.log_event/4` para registrar a detecção, incluindo detalhes da atividade e nível de risco.
*   **Analista de Segurança Investiga Incidente:** O analista usa uma interface (ou console) que chama `AuditFacade.search_events/2` para filtrar logs por usuário, período e tipo de evento.
*   **Auditor Externo Solicita Relatório:** Um relatório de acesso a dados sensíveis é gerado via `AuditFacade.export_events/3`.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Registro de um Evento de Auditoria:**

1.  Um módulo (ex: `DeeperHub.Accounts`) precisa logar uma ação (ex: `user_updated`).
2.  Ele chama `DeeperHub.Audit.AuditFacade.log_event(:user_action, \"user_updated\", %{user_id: \"123\", changes: ...}, %{performed_by: \"admin456\"})`.
3.  `AuditFacade` delega para `DeeperHub.Audit.Services.LoggingService`.
4.  `LoggingService` enriquece o evento com metadados globais (timestamp, `trace_id` se disponível).
5.  O evento formatado é enfileirado para processamento assíncrono (ex: enviado para `DeeperHub.Audit.Workers.AuditLogWorker`).
6.  `AuditLogWorker` recebe o evento da fila.
7.  Cria uma instância do schema `DeeperHub.Audit.AuditLog`.
8.  Persiste o log no banco de dados usando `DeeperHub.Core.Repo`.
9.  Emite métricas sobre o evento logado (ex: `audit.event.logged.count`).

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.Audit.AuditFacade.log_event/4`

*   **Descrição:** Registra um evento de auditoria no sistema.
*   **`@spec`:** `log_event(category :: atom(), event_type :: String.t() | atom(), details :: map(), context :: map()) :: :ok | {:error, atom()}`
*   **Parâmetros:**
    *   `category` (atom): Categoria do evento (ex: `:user_action`, `:security`, `:system`, `:config_change`).
    *   `event_type` (String.t() | atom): Tipo específico do evento (ex: `\"login_success\"`, `:permission_granted`).
    *   `details` (map): Mapa contendo detalhes específicos do evento (ex: `%{resource_id: \"doc123\", operation: \"read\"}`).
    *   `context` (map): Metadados contextuais (ex: `%{user_id: \"usr_abc\", ip_address: \"1.2.3.4\", trace_id: \"xyz\"}`).
*   **Retorno:**
    *   `:ok`: Se o evento foi enfileirado/processado com sucesso.
    *   `{:error, reason}`: Em caso de falha.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    details = %{target_user_id: \"user_xyz\", permission: \"admin_access\"}
    context = %{user_id: \"admin_abc\", ip_address: \"192.168.1.10\"}
    DeeperHub.Audit.AuditFacade.log_event(:security, :permission_granted, details, context)
    ```

### 6.2. `DeeperHub.Audit.AuditFacade.search_events/2`

*   **Descrição:** Busca eventos de auditoria com base em critérios de filtro.
*   **`@spec`:** `search_events(filters :: map(), opts :: Keyword.t()) :: {:ok, %{logs: list(AuditLog.t()), total_count: integer()}} | {:error, atom()}`
*   **Parâmetros:**
    *   `filters` (map): Critérios de filtro (ex: `%{user_id: \"usr_abc\", event_type: \"login_failed\", date_range: {start_dt, end_dt}}`).
    *   `opts` (Keyword.t()): Opções de paginação e ordenação (ex: `[limit: 50, offset: 0, order_by: [timestamp: :desc]]`).
*   **Retorno:**
    *   `{:ok, %{logs: logs_list, total_count: count}}`: Lista de logs e contagem total.
    *   `{:error, reason}`: Em caso de falha na busca.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    filters = %{user_id: \"user123\", category: :security}
    opts = [limit: 10, order_by: [timestamp: :desc]]
    case DeeperHub.Audit.AuditFacade.search_events(filters, opts) do
      {:ok, result} -> IO.inspect(result.logs)
      {:error, reason} -> Logger.error(\"Falha ao buscar logs de auditoria: #{reason}\")
    end
    ```

## ⚙️ 7. Configuração

*   **ConfigManager:**
    *   `[:audit, :default_retention_days]`: Período padrão de retenção de logs em dias. (Padrão: `365`)
    *   `[:audit, :retention_policies, :category_name, :days]`: Período de retenção específico por categoria de evento.
    *   `[:audit, :archive, :enabled]`: Se o arquivamento de logs está habilitado. (Padrão: `false`)
    *   `[:audit, :archive, :storage_adapter]`: Adaptador para o storage de arquivamento (ex: S3, FileSystem).
    *   `[:audit, :archive, :archive_older_than_days]`: Idade mínima para arquivar logs.
    *   `[:audit, :log_worker, :batch_size]`: Número de logs processados por lote pelo worker. (Padrão: `100`)
    *   `[:audit, :log_worker, :flush_interval_ms]`: Intervalo para flush de logs do worker. (Padrão: `5000`)
    *   `[:audit, :retention_scheduler, :cron_expression]`: Expressão cron para a tarefa de retenção. (Padrão: `\"0 2 * * *\"` - às 2 da manhã todo dia)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Repo`: Para persistência dos logs.
*   `DeeperHub.Core.ConfigManager`: Para configurações de retenção, arquivamento, etc.
*   `DeeperHub.Core.EventBus` (Indireta): Outros módulos publicam eventos que podem ser consumidos por integrações de auditoria.
*   `DeeperHub.Core.BackgroundTaskManager`: Para agendar e executar tarefas de retenção/arquivamento.
*   `DeeperHub.Core.Logger`: Para logging interno do módulo de auditoria.
*   `DeeperHub.Core.Metrics`: Para métricas de desempenho do sistema de auditoria.

### 8.2. Bibliotecas Externas

*   `Ecto`: Para interações com o banco de dados.
*   `Jason`: Para serializar/deserializar o campo `details` (mapa) dos logs.
*   Opcionalmente, bibliotecas para exportação (CSV, PDF).
*   Opcionalmente, bibliotecas para interagir com storage de arquivamento (ExAws para S3).

## 🤝 9. Como Usar / Integração

Outros módulos devem usar a `AuditFacade.log_event/4` para registrar eventos.

**Exemplo de módulo de `Auth` registrando um login falho:**
```elixir
defmodule DeeperHub.Auth do
  alias DeeperHub.Audit.AuditFacade

  def login(email, _password, context_ip) do
    # ... lógica de autenticação ...
    user_id_tentativa = \"id_do_usuario_se_encontrado_pelo_email\"
    context = %{user_id: user_id_tentativa, ip_address: context_ip, attempt_email: email}

    if authentication_failed do
      AuditFacade.log_event(:security, :login_failure, %{reason: \"invalid_credentials\"}, context)
      {:error, :invalid_credentials}
    else
      AuditFacade.log_event(:security, :login_success, %{}, context)
      # ...
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o registro de eventos de diferentes categorias e tipos.
*   Testar a consulta de logs com diversos filtros.
*   Testar a lógica de retenção e arquivamento (pode exigir simulação de tempo).
*   Testar a geração de relatórios.
*   Localização: `test/deeper_hub/audit/`

### 10.2. Métricas

*   `deeper_hub.audit.event.logged.count` (Contador): Número de eventos de auditoria logados. Tags: `category`, `event_type`.
*   `deeper_hub.audit.event.processed.duration_ms` (Histograma): Tempo para processar e persistir um evento de auditoria.
*   `deeper_hub.audit.query.duration_ms` (Histograma): Duração das consultas de logs de auditoria. Tags: `filter_count`.
*   `deeper_hub.audit.retention.logs_deleted.count` (Contador): Número de logs excluídos pela política de retenção.
*   `deeper_hub.audit.retention.logs_archived.count` (Contador): Número de logs arquivados.
*   `deeper_hub.audit.queue.size.gauge` (Gauge): Tamanho da fila de logs pendentes de processamento.

### 10.3. Logs

*   Logs internos do módulo de auditoria devem usar `DeeperHub.Core.Logger` e incluir `{module: DeeperHub.Audit.<SubModule>}`.
*   Ex: `Logger.info(\"Política de retenção executada, #{count} logs excluídos\", module: DeeperHub.Audit.Scheduler.RetentionScheduler)`

### 10.4. Telemetria

*   `[:deeper_hub, :audit, :event, :logged]`: Emitido após um evento ser persistido. Payload: `%{log: audit_log_struct}`.
*   `[:deeper_hub, :audit, :retention, :run, :start | :stop | :exception]`: Para a execução da tarefa de retenção.

## ❌ 11. Tratamento de Erros

*   Falhas no enfileiramento de logs devem ser tratadas com retry ou logadas como erro crítico se persistirem, mas não devem bloquear a operação original da aplicação.
*   Falhas na persistência de logs devem ser tratadas com retry e, se persistirem, um alerta deve ser gerado para a equipe de operações.
*   Consultas inválidas devem retornar `{:error, :invalid_filters}` ou similar.

## 🛡️ 12. Considerações de Segurança

*   **Sensibilidade dos Logs:** Logs de auditoria podem conter informações sensíveis. O acesso a eles deve ser estritamente controlado via `DeeperHub.RBAC`.
*   **Performance:** Um volume muito alto de logs pode impactar a performance do banco de dados. O design do schema e as estratégias de indexação são cruciais.
*   **Adulteração:** Considerar mecanismos para detectar ou prevenir adulteração dos logs (ex: logs apenas de acréscimo, checksums, blockchain).
*   **Vazamento de Informação:** Ao exibir logs ou em relatórios, garantir que informações excessivamente sensíveis (ex: senhas brutas, tokens completos) não sejam expostas.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos tipos de eventos de auditoria, certifique-se de que a categoria e o `event_type` sejam consistentes.
*   Garanta que todos os detalhes relevantes e o contexto sejam incluídos nos logs.
*   Otimize consultas de logs, especialmente aquelas que podem ser executadas com frequência ou sobre grandes volumes de dados.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um backend de arquivamento para S3.
*   [ ] Adicionar suporte para assinatura digital de logs para garantir integridade.
*   [ ] Criar uma interface de usuário para administradores consultarem e analisarem logs de auditoria.
*   [ ] Desenvolver um sistema de alertas configurável para eventos de auditoria críticos.
*   [ ] Integrar com ferramentas de análise de logs externas (ex: ELK stack, Splunk).

---

*Última atualização: YYYY-MM-DD*

---

Próximo da lista: `DeeperHub.FeatureFlags`. Vamos a ele?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Excelente! Vamos agora detalhar o README para o módulo `DeeperHub.FeatureFlags`.

---

