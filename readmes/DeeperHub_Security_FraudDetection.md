# Módulo: `DeeperHub.Security.FraudDetection` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.FraudDetection`

O módulo `DeeperHub.Security.FraudDetection` é dedicado a identificar, prevenir e gerenciar atividades fraudulentas dentro do sistema DeeperHub. Ele analisa diversos tipos de interações e transações dos usuários, aplicando um conjunto de regras, heurísticas e, potencialmente, modelos de aprendizado de máquina para detectar comportamentos que se desviam do normal ou que correspondem a padrões de fraude conhecidos.

As principais áreas de análise incluem tentativas de login, alterações de perfil, transações financeiras (se aplicável), uso da API e anomalias biométricas. O objetivo é minimizar perdas financeiras, proteger contas de usuários contra comprometimento e manter a integridade da plataforma. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Análise de Atividades para Detecção de Fraude:**
    *   **Login (`analyze_login/1`):** Avaliar o risco de tentativas de login com base em fatores como localização, dispositivo, histórico, velocidade de viagem, IPs suspeitos.
    *   **Alterações de Perfil (`analyze_profile_changes/1`):** Detectar alterações suspeitas em dados críticos do perfil (ex: email, telefone, senha, endereço) feitas rapidamente ou de locais/dispositivos incomuns.
    *   **Transações (se aplicável):** Monitorar transações financeiras ou de itens de valor para padrões fraudulentos (ex: valores incomuns, frequência, destinatários suspeitos).
    *   **Uso de API (`analyze_api_usage/1`):** Identificar abuso de API, scraping ou atividades automatizadas maliciosas.
    *   **Anomalias Biométricas (`record_biometric_anomaly/1`):** Receber e processar alertas do módulo `DeeperHub.Biometrics` sobre desvios comportamentais.
*   **Gerenciamento de Regras de Detecção:**
    *   Permitir a criação, atualização, exclusão e consulta de regras de detecção de fraude (via `RulesManagerService`).
    *   Suportar diferentes tipos de condições e pesos para as regras.
*   **Cálculo de Pontuação de Risco (Risk Scoring):**
    *   Atribuir uma pontuação de risco a cada evento/atividade analisada com base nas regras acionadas e outros fatores.
    *   Classificar o risco em níveis (ex: baixo, médio, alto, crítico) (via `RiskCalculatorService`).
*   **Registro de Detecções:**
    *   Armazenar todas as detecções de fraude, incluindo detalhes, contexto, pontuação de risco e status (via `DetectionRecorderService`).
*   **Gerenciamento de Casos de Fraude:**
    *   Permitir que analistas de segurança revisem detecções, adicionem notas e atualizem o status (ex: falso positivo, fraude confirmada, resolvido) (via `Core` ou `DetectionRecorderService`).
*   **Notificações e Alertas:**
    *   Notificar a equipe de segurança e/ou usuários sobre detecções de fraude de alta criticidade (via `FraudNotifierService` e `DeeperHub.Notifications`).
*   **Integração com Outros Módulos de Segurança:**
    *   Utilizar dados do `LoginLocation`, `DeviceFingerprint`, `BehavioralAnalysis` para enriquecer a análise.
    *   Fornecer informações para o `SecurityManager` tomar decisões (ex: bloquear usuário, exigir MFA adicional).
*   **Relatórios e Estatísticas:**
    *   Gerar relatórios sobre tendências de fraude, eficácia das regras, etc.
    *   Fornecer estatísticas sobre detecções e níveis de risco.

## 🏗️ 3. Arquitetura e Design

O `DeeperHub.Security.FraudDetection` é um módulo complexo que geralmente é composto por vários serviços e componentes especializados.

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.FraudDetection` (Fachada Pública):**
    *   Ponto de entrada para o sistema de detecção de fraude.
    *   Delega chamadas para o `FraudDetectionService` ou diretamente para serviços especializados.
2.  **`DeeperHub.Security.FraudDetection.Services.DefaultFraudDetectionService` (ou `FraudDetectionCoreService`):**
    *   Serviço central que orquestra o processo de análise.
    *   Recebe dados de eventos, aplica regras, calcula riscos e registra detecções.
    *   Pode ser um GenServer para gerenciar estado ou executar tarefas assíncronas.
3.  **`DeeperHub.Security.FraudDetection.Services.RulesManagerService` (GenServer):**
    *   Responsável por carregar, armazenar e fornecer acesso às regras de detecção de fraude.
    *   Permite a atualização dinâmica de regras.
4.  **`DeeperHub.Security.FraudDetection.Services.RiskCalculatorService` (GenServer ou Módulo Funcional):**
    *   Contém a lógica para calcular a pontuação de risco com base nos fatores identificados e nos pesos das regras.
5.  **`DeeperHub.Security.FraudDetection.Services.DetectionRecorderService` (GenServer):**
    *   Responsável por persistir os registros de detecções de fraude.
    *   Gerencia o ciclo de vida das detecções (status, notas).
6.  **`DeeperHub.Security.FraudDetection.Services.FraudNotifierService` (GenServer):**
    *   Responsável por enviar notificações e alertas com base nas detecções.
7.  **`DeeperHub.Security.FraudDetection.Schema.FraudDetectionSchema`:**
    *   Schema Ecto para armazenar os registros de detecção de fraude.
8.  **`DeeperHub.Security.FraudDetection.Schema.RiskFactors` e `RiskScore` (Opcional):**
    *   Schemas para detalhar os fatores que contribuíram para uma pontuação de risco.
9.  **Workers (`AnalysisWorker`, `CleanupWorker`):**
    *   `AnalysisWorker`: Para análises periódicas de padrões de fraude mais complexos ou em lote.
    *   `CleanupWorker`: Para limpar dados antigos de detecção.
10. **Integrações:**
    *   `AuditIntegration`: Para logar eventos de fraude.
    *   `EventIntegration`: Para publicar/subscrever eventos relacionados à fraude.
    *   `MetricsReporter` ou `Telemetry`: Para registrar métricas.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/fraud_detection/
├── fraud_detection.ex                # Fachada Pública
│
├── services/
│   ├── default_fraud_detection_service.ex # Serviço orquestrador
│   ├── rules_manager_service.ex
│   ├── risk_calculator_service.ex
│   ├── detection_recorder_service.ex
│   └── fraud_notifier_service.ex
│
├── schemas/
│   ├── fraud_detection_schema.ex
│   ├── risk_factors.ex               # Opcional
│   └── risk_score.ex                 # Opcional
│
├── rules/                            # Onde as definições de regras podem residir
│   └── login_rules.ex
│
├── integrations/
│   ├── audit_integration.ex
│   └── event_integration.ex          # (Pode ser gerenciado centralmente em Security/Integrations)
│
├── workers/
│   ├── analysis_worker.ex
│   └── cleanup_worker.ex
│
├── supervisor.ex
└── telemetry.ex                      # (ou MetricsReporter.ex)
```

### 3.3. Decisões de Design Importantes

*   **Sistema Baseado em Regras Extensível:** A capacidade de adicionar e modificar regras dinamicamente é crucial.
*   **Pontuação de Risco Flexível:** O `RiskCalculatorService` deve permitir diferentes modelos de pontuação e ponderação de fatores.
*   **Feedback Loop:** O sistema deve permitir que analistas marquem detecções como falsos positivos, o que pode ser usado para treinar/ajustar modelos ou regras.
*   **Processamento em Tempo Real e em Lote:** Algumas análises precisam ser em tempo real (ex: login), enquanto outras podem ser feitas em lote (ex: análise de padrões históricos).

## 🛠️ 4. Casos de Uso Principais

*   **Tentativa de Login de um Novo Dispositivo e Localização:**
    *   `DeeperHub.Auth` envia dados do login para `FraudDetection.analyze_login/1`.
    *   O serviço aplica regras como \"novo dispositivo\", \"nova localização\", \"viagem impossível\".
    *   Calcula um score de risco. Se alto, pode recomendar MFA adicional ou bloquear temporariamente.
*   **Usuário Altera Email e Senha Rapidamente:**
    *   `DeeperHub.Accounts` envia dados das alterações para `FraudDetection.analyze_profile_changes/1`.
    *   Regras para \"múltiplas alterações sensíveis em curto período\" são acionadas.
    *   Score de risco alto -> notificação para o usuário sobre as alterações.
*   **Detecção de Padrão de Abuso de API:**
    *   `DeeperHub.API` envia dados de uso para `FraudDetection.analyze_api_usage/1`.
    *   Regras de \"alta frequência de requisições\" ou \"acesso a endpoints sensíveis de forma incomum\" são acionadas.
    *   Risco alto -> pode levar a rate limiting mais agressivo ou bloqueio temporário do cliente API.

## 🌊 5. Fluxos Importantes

### Fluxo de Análise de Fraude para um Evento (ex: Login)

1.  **Evento de Entrada:** `FraudDetection.analyze_login(login_info)` é chamado.
2.  **`DefaultFraudDetectionService`:**
    *   Coleta dados contextuais adicionais (histórico do usuário, reputação do IP, etc.).
    *   Recupera as regras relevantes para o tipo de evento \"login\" do `RulesManagerService`.
3.  **Aplicação de Regras:**
    *   Para cada regra, avalia se as condições são atendidas com base nos dados do evento e contexto.
    *   Coleta os fatores de risco e as pontuações parciais das regras acionadas.
4.  **`RiskCalculatorService`:**
    *   Recebe os fatores de risco e suas pontuações/pesos.
    *   Calcula a pontuação de risco final e o nível de risco (baixo, médio, alto, crítico).
5.  **`DetectionRecorderService`:**
    *   Se a pontuação de risco exceder um limiar mínimo para registro, um novo `FraudDetectionSchema` é criado e persistido com todos os detalhes.
6.  **`FraudNotifierService`:**
    *   Se o nível de risco for alto o suficiente para justificar uma notificação imediata, envia alertas para a equipe de segurança ou para o usuário (via `DeeperHub.Notifications`).
7.  **Resposta:** O `DefaultFraudDetectionService` retorna o resultado da análise (nível de risco, ID da detecção, ações recomendadas) para o chamador.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Security.FraudDetection`)

*(Muitas já foram descritas na documentação original. Foco em clareza e exemplos.)*

### 6.1. `DeeperHub.Security.FraudDetection.analyze_login(login_info :: map()) :: {:ok, FraudAnalysisResult.t()} | {:error, term()}`

*   **Descrição:** Analisa uma tentativa de login para detectar fraude.
*   **`login_info`:** `%{user_id: String.t(), ip_address: String.t(), user_agent: String.t(), location: map() | nil, success: boolean()}`
*   **`FraudAnalysisResult.t()`:** `%{risk_score: float(), risk_level: atom(), detection_id: String.t() | nil, details: map()}`
*   **Exemplo:**
    ```elixir
    login_data = %{user_id: \"u1\", ip_address: \"1.2.3.4\", user_agent: \"...\", success: true}
    case FraudDetection.analyze_login(login_data) do
      {:ok, result} -> Logger.info(\"Análise de login: #{inspect(result)}\")
      {:error, e} -> Logger.error(\"Erro na análise de login: #{inspect(e)}\")
    end
    ```

### 6.2. `DeeperHub.Security.FraudDetection.add_rule(rule_definition :: map()) :: {:ok, Rule.t()} | {:error, term()}`

*   **Descrição:** Adiciona uma nova regra de detecção de fraude.
*   **`rule_definition`:** `%{name: String.t(), detection_type: atom(), conditions: list(map()), action_score: integer(), enabled: boolean()}`
*   **Exemplo:**
    ```elixir
    rule = %{name: \"High value transfer from new device\", detection_type: :transaction, conditions: [...], action_score: 70}
    FraudDetection.add_rule(rule)
    ```

### 6.3. `DeeperHub.Security.FraudDetection.update_detection_status(detection_id :: String.t(), status :: atom(), reviewer_id :: String.t(), notes :: String.t() | nil) :: {:ok, FraudDetectionSchema.t()} | {:error, term()}`

*   **Descrição:** Atualiza o status de uma detecção (ex: `:reviewed`, `:false_positive`, `:confirmed_fraud`).

*(Outras funções como `analyze_profile_changes/1`, `analyze_transaction/1`, `get_rules/1`, `list_detections/1` seguiriam um padrão similar.)*

## ⚙️ 7. Configuração

Configurações gerenciadas pelo `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :fraud_detection, :enabled]`** (Boolean): Habilita/desabilita o sistema de detecção de fraude. (Padrão: `true`)
*   **`[:security, :fraud_detection, :default_risk_thresholds]`** (Map): Limiares padrão para classificar scores de risco (ex: `%{low: 20, medium: 50, high: 75, critical: 90}`).
*   **`[:security, :fraud_detection, :rules_source]`** (Atom ou String): Fonte para carregar as regras de detecção (ex: `:config_file`, `:database`, ou caminho para um arquivo).
*   **`[:security, :fraud_detection, :rules_file_path]`** (String): Caminho para o arquivo de regras, se `rules_source` for `:config_file`.
*   **`[:security, :fraud_detection, :record_all_analyses]`** (Boolean): Se deve registrar todas as análises, mesmo as de baixo risco. (Padrão: `false`, registrar apenas acima de um limiar)
*   **`[:security, :fraud_detection, :min_score_to_record]`** (Integer): Pontuação mínima para registrar uma detecção. (Padrão: `30`)
*   **`[:security, :fraud_detection, :notification_thresholds]`** (Map): Limiares de risco para diferentes canais de notificação (ex: `%{email: :high, sms: :critical}`).
*   **`[:security, :fraud_detection, :cleanup_worker, :retention_days]`** (Integer): Por quantos dias manter os registros de detecção. (Padrão: `180`)
*   **`[:security, :fraud_detection, :analysis_worker, :batch_size]`** (Integer): Tamanho do lote para análise em background.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `DeeperHub.Auth`: Para informações de usuário e sessão.
*   `DeeperHub.Accounts`: Para dados de perfil.
*   `DeeperHub.API`: Para dados de uso da API.
*   `DeeperHub.Biometrics`: Para dados de anomalias biométricas.
*   `DeeperHub.Security.LoginLocation`: Para dados de localização.
*   `DeeperHub.Security.DeviceFingerprint`: Para dados de dispositivo.
*   `DeeperHub.Security.RiskAssessment`: Pode ser usado como um dos insumos para a pontuação de fraude ou ser o resultado dela.
*   `DeeperHub.Notifications`: Para enviar alertas.
*   `DeeperHub.Audit`: Para registrar detecções e ações.

### 8.2. Bibliotecas Externas

*   Bibliotecas de Machine Learning (opcional, ex: `Nx`, `Axon`, `Scholar`) se modelos de ML forem usados.
*   Bibliotecas para processamento de regras (opcional, ex: `RuleEx`).

## 🤝 9. Como Usar / Integração

Os módulos de domínio (Accounts, API, etc.) devem chamar as funções `analyze_*` da fachada `DeeperHub.Security.FraudDetection` quando eventos relevantes ocorrem.

**Exemplo em `DeeperHub.Accounts` ao atualizar email:**
```elixir
def update_email(user, new_email, context_info) do
  # ... (lógica de atualização do email) ...

  # Análise de fraude
  profile_change_info = %{
    user_id: user.id,
    changes: %{email: new_email},
    ip_address: context_info.ip_address,
    # ... outros dados de contexto
  }
  case DeeperHub.Security.FraudDetection.analyze_profile_changes(profile_change_info) do
    {:ok, %{risk_level: risk_level, detection_id: detection_id}} when risk_level in [:high, :critical] ->
      Logger.warning(\"Alta suspeita de fraude na alteração de email para user_id: #{user.id}\", detection_id: detection_id)
      # Pode-se optar por bloquear a alteração, exigir verificação adicional, etc.
      # ...
    {:ok, _low_or_medium_risk} ->
      # Prossegue normalmente
      # ...
    {:error, reason} ->
      Logger.error(\"Erro na análise de fraude para alteração de email: #{inspect(reason)}\")
      # Lidar com o erro, talvez prosseguir com cautela ou negar.
  end
  # ...
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada função de análise (`analyze_login`, `analyze_transaction`, etc.) com diversos cenários (normal, suspeito, fraudulento).
*   Testar a lógica de aplicação de regras e cálculo de score de risco.
*   Testar o registro e atualização de status de detecções.
*   Testar a funcionalidade dos workers (`AnalysisWorker`, `CleanupWorker`).
*   Localização: `test/deeper_hub/security/fraud_detection/`.

### 10.2. Métricas

*   `deeper_hub.security.fraud_detection.analyzed.count` (tags: `type` (`login`, `transaction`, etc.))
*   `deeper_hub.security.fraud_detection.detected.count` (tags: `type`, `risk_level`)
*   `deeper_hub.security.fraud_detection.analysis.duration_ms` (Histograma, tags: `type`)
*   `deeper_hub.security.fraud_detection.rules.triggered.count` (tags: `rule_id`)
*   `deeper_hub.security.fraud_detection.false_positives.count` (tags: `type`)
*   `deeper_hub.security.fraud_detection.average_risk_score.gauge` (tags: `type`)

### 10.3. Logs

*   **Nível INFO:** Análise de eventos com baixo risco, atualizações de status de detecção.
*   **Nível WARNING:** Detecções de risco médio ou alto, acionamento de regras importantes.
*   **Nível ERROR:** Falhas na análise, erros ao registrar detecções, detecções de risco crítico.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :fraud_detection, :analysis, :start | :stop | :exception]`
    *   Metadados: `%{type: type, user_id: id, input_data_sample: sample}`
*   `[:deeper_hub, :security, :fraud_detection, :rule_evaluation, :start | :stop | :exception]`
    *   Metadados: `%{rule_id: id, conditions_met: boolean}`
*   `[:deeper_hub, :security, :fraud_detection, :detection_recorded]`
    *   Metadados: `%{detection_id: id, type: type, risk_level: level, risk_score: score}`
*   `[:deeper_hub, :security, :fraud_detection, :status_updated]`
    *   Metadados: `%{detection_id: id, new_status: status, reviewer_id: id}`

## ❌ 11. Tratamento de Erros

*   Falhas na análise de fraude não devem impedir a operação principal do usuário, mas devem ser logadas e, possivelmente, sinalizar a operação para revisão manual ou aplicar uma política de \"negar por padrão\" se o risco for desconhecido e alto.
*   Erros de persistência de detecções ou atualização de regras devem ser tratados e logados, com mecanismos de retry se apropriado.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Segurança das Regras:** O mecanismo de atualização de regras (`RulesManagerService`) deve ser protegido para evitar que regras maliciosas sejam injetadas.
*   **Dados de Análise:** Os dados usados para análise de fraude podem ser sensíveis. Garantir que sejam manuseados com segurança e que o acesso aos resultados da análise seja restrito.
*   **Falsos Positivos:** O sistema deve ser ajustado para minimizar falsos positivos, que podem impactar negativamente a experiência do usuário. Um processo claro para revisar e corrigir falsos positivos é essencial.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas regras, documente claramente suas condições e o racional por trás delas.
*   Teste exaustivamente novas regras contra dados históricos para avaliar seu impacto e precisão.
*   Considere a performance ao adicionar regras complexas ou que exigem muitas consultas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Integrar modelos de Machine Learning para detecção de anomalias mais sofisticada e adaptativa.
*   [ ] Desenvolver uma interface de usuário para analistas de fraude gerenciarem regras, revisarem detecções e verem estatísticas.
*   [ ] Adicionar suporte para \"listas de observação\" (watchlists) de usuários ou entidades com comportamento suspeito.
*   [ ] Implementar feedback loop para que as decisões dos analistas (ex: marcar como falso positivo) possam retroalimentar e ajustar os modelos/regras.
*   [ ] Permitir simulação de novas regras contra dados históricos antes de ativá-las em produção.
*   [ ] Integração com provedores externos de dados de risco/fraude (ex: reputação de IP, dados de cartão de crédito roubado).

---

*Última atualização: 2025-05-11*

---

Este módulo de Detecção de Fraude é bastante abrangente e interage com muitos outros.

Onde gostaria de focar agora? Talvez `DeeperHub.Security.BruteForceProtection` ou `DeeperHub.Security.RiskAssessment`? Ou podemos ir para um módulo Core como `DeeperHub.Core.Repo`?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, vamos seguir com outro componente importante da camada de segurança: `DeeperHub.Security.BruteForceProtection`.

---

