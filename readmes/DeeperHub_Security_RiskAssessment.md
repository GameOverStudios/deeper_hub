# Módulo: `DeeperHub.Security.RiskAssessment` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.RiskAssessment`

O módulo `DeeperHub.Security.RiskAssessment` é o componente central do DeeperHub responsável por **avaliar e quantificar o nível de risco associado a diversas operações e interações dentro do sistema**. Ele agrega informações de múltiplos fatores e fontes – como comportamento do usuário, dados do dispositivo, localização geográfica, natureza da operação, e alertas de outros sistemas de segurança (ex: `FraudDetection`, `IntrusionDetection`) – para calcular uma pontuação de risco compreensiva.

O objetivo principal é permitir que o DeeperHub tome decisões de segurança adaptativas e contextuais. Com base na avaliação de risco, o sistema pode, por exemplo, permitir uma operação, exigir etapas adicionais de verificação (como MFA), impor limitações, ou até mesmo bloquear uma ação considerada de alto risco. Este módulo é crucial para uma postura de segurança proativa e dinâmica. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Avaliação de Risco Contextual:**
    *   Avaliar o risco de uma ampla gama de operações, incluindo:
        *   Tentativas de login (`assess_login_risk/3`).
        *   Alterações de perfil sensíveis (`assess_profile_change_risk/3`).
        *   Transações financeiras ou de valor (`assess_transaction_risk/3`).
        *   Requisições de API (`assess_api_request_risk/3`).
        *   Validade e risco de sessões de usuário (`assess_session_risk/3`).
        *   Outras ações específicas de domínio (`assess_action_risk/4`).
*   **Agregação de Fatores de Risco:**
    *   Coletar dados de diversos módulos e fontes para calcular fatores de risco individuais (ex: reputação do IP, novidade do dispositivo, anomalia comportamental, histórico de fraude).
    *   Utilizar `RiskFactorCalculator` e `AdvancedRiskFactors` para quantificar esses fatores.
*   **Cálculo de Pontuação de Risco:**
    *   Aplicar pesos configuráveis a cada fator de risco.
    *   Calcular uma pontuação de risco consolidada (ex: 0-100) usando o `RiskCalculatorService`.
    *   Mapear a pontuação para níveis de risco qualitativos (ex: `:low`, `:medium`, `:high`, `:critical`).
*   **Recomendação de Ações de Segurança:**
    *   Com base no nível de risco e no tipo de operação, sugerir ações de mitigação apropriadas (ex: `:allow`, `:challenge_mfa`, `:limit_functionality`, `:block`, `:notify_security_team`) utilizando o `RiskActionRecommender`.
*   **Gerenciamento de Perfis de Risco de Usuário:**
    *   Construir e manter um perfil de risco dinâmico para cada usuário, refletindo seu histórico de risco e comportamento.
    *   Atualizar o perfil com base em novas avaliações.
*   **Políticas de Risco Configuráveis:**
    *   Permitir a definição e ajuste de pesos de fatores, limiares de nível de risco e regras para recomendação de ações através do `DeeperHub.Security.Policy.SecurityPolicyManager`.
*   **Histórico e Auditoria de Avaliações:**
    *   Manter um registro de todas as avaliações de risco realizadas, incluindo os fatores contribuintes e o resultado.
    *   Integrar com `DeeperHub.Audit` para auditoria.
*   **Calibração e Feedback (Opcional):**
    *   Permitir a calibração dos modelos de risco e pesos dos fatores com base em feedback manual (ex: análise de falsos positivos/negativos) ou aprendizado automático.
*   **Observabilidade:**
    *   Fornecer métricas detalhadas sobre as avaliações de risco, distribuição de scores e eficácia das políticas.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.RiskAssessment` (Fachada Pública):**
    *   Ponto de entrada para todas as solicitações de avaliação de risco.
    *   Delega para o `DefaultRiskAssessmentService`.
2.  **`DeeperHub.Security.RiskAssessment.Services.DefaultRiskAssessmentService` (GenServer ou Serviço Coordenador):**
    *   **Responsabilidade:** Orquestra todo o processo de avaliação.
    *   **Interações:**
        *   Coleta dados de contexto (IP, dispositivo, sessão).
        *   Obtém dados do usuário (de `DeeperHub.Accounts`) e seu perfil de risco (do `ProfileStore` interno ou de `DefaultRiskAssessmentService` mesmo).
        *   Chama `RiskFactorCalculator` para fatores de risco baseados em atributos.
        *   Chama `AdvancedRiskFactors` para fatores comportamentais e contextuais mais complexos (pode interagir com `BehavioralAnalysis`, `LoginLocation`).
        *   Envia os fatores e seus valores para `RiskCalculatorService`.
        *   Recebe o score e nível de risco.
        *   Chama `RiskActionRecommender` para obter ações sugeridas.
        *   Registra a avaliação (via `RiskAssessmentLogStore` ou similar).
        *   Atualiza o perfil de risco do usuário.
3.  **`DeeperHub.Security.RiskAssessment.Services.RiskFactorCalculator`:**
    *   Módulo funcional contendo funções para calcular valores de fatores de risco individuais (ex: `calculate_ip_risk(ip)`, `calculate_device_novelty_score(user_id, device_fingerprint)`).
4.  **`DeeperHub.Security.RiskAssessment.Services.AdvancedRiskFactors`:**
    *   Módulo funcional ou GenServer para fatores que exigem mais estado ou análise (ex: `calculate_impossible_travel_score`, `get_behavioral_anomaly_score`).
5.  **`DeeperHub.Security.RiskAssessment.Services.RiskCalculatorService`:**
    *   Módulo funcional que aplica pesos (obtidos de `SecurityPolicyManager`) aos fatores de risco e calcula a pontuação final.
    *   Determina o nível de risco com base em limiares configurados.
6.  **`DeeperHub.Security.RiskAssessment.Services.RiskActionRecommender`:**
    *   Módulo funcional ou GenServer que, com base no nível de risco, tipo de operação e políticas, sugere um conjunto de ações (ex: `[:require_mfa, :notify_user]`).
7.  **`DeeperHub.Security.RiskAssessment.Services.RiskWeightCalibrator` (Opcional):**
    *   GenServer para gerenciar e potencialmente auto-ajustar os pesos dos fatores de risco.
8.  **`DeeperHub.Security.RiskAssessment.Metrics.RiskMetricsCollector` (GenServer):**
    *   Coleta e agrega métricas sobre as avaliações de risco.
9.  **Schemas (Persistência):**
    *   `DeeperHub.Security.RiskAssessment.Schemas.RiskProfile`: Para armazenar o perfil de risco de cada usuário.
    *   `DeeperHub.Security.RiskAssessment.Schemas.RiskAssessmentLog`: Para armazenar o histórico de avaliações de risco.
10. **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Define pesos, limiares, regras de ação, etc.

### 3.2. Estrutura de Diretórios (Consistente com a anterior)

```
lib/deeper_hub/security/risk_assessment/
├── risk_assessment.ex                # Fachada Pública
│
├── services/
│   ├── default_risk_assessment_service.ex
│   ├── risk_factor_calculator.ex
│   ├── advanced_risk_factors.ex
│   ├── risk_calculator_service.ex
│   ├── risk_action_recommender.ex
│   └── risk_weight_calibrator.ex     # Opcional
│
├── metrics/
│   └── risk_metrics_collector.ex
│
├── schemas/
│   ├── risk_profile.ex
│   └── risk_assessment_log.ex
│
├── supervisor.ex
└── telemetry.ex
```

### 3.3. Decisões de Design Importantes

*   **Baseado em Evidências:** A avaliação de risco deve ser baseada em múltiplos pontos de dados e evidências, não em um único fator.
*   **Ponderação Configurável:** A importância de cada fator de risco deve ser configurável para adaptar o sistema a diferentes cenários e tolerâncias a risco.
*   **Explicabilidade:** O sistema deve ser capaz de fornecer (pelo menos para administradores) os fatores que contribuíram para uma determinada pontuação de risco.
*   **Ciclo de Feedback:** Mecanismos para ajustar o modelo de risco com base em resultados (fraudes reais, falsos positivos) são importantes para a melhoria contínua.

## 🛠️ 4. Casos de Uso Principais

*   **Avaliação de Risco de Login:**
    *   `DeeperHub.Auth` solicita uma avaliação de risco para uma tentativa de login.
    *   `RiskAssessment` considera: IP (novo, reputação), dispositivo (novo, confiável), localização (usual, viagem impossível), horário (usual), histórico de tentativas falhas, score de anomalia comportamental.
    *   Retorna um score e ações (ex: permitir, exigir MFA).
*   **Avaliação de Risco de Mudança de Senha:**
    *   `DeeperHub.Accounts` solicita avaliação antes de permitir a mudança de senha.
    *   `RiskAssessment` considera: sessão atual (MFA verificado recentemente?), IP/dispositivo da solicitação, se a senha antiga foi fornecida corretamente.
    *   Pode recomendar notificação ao usuário em todos os casos, e MFA se o risco for médio/alto.
*   **Avaliação de Risco de uma Transação de Alto Valor (Exemplo):**
    *   Um módulo financeiro solicita avaliação.
    *   `RiskAssessment` considera: valor da transação (vs. histórico), destinatário (novo, conhecido), frequência de transações, score de anomalia comportamental do usuário.
    *   Pode recomendar bloqueio temporário e revisão manual.

## 🌊 5. Fluxos Importantes

### Fluxo de Avaliação de Risco Genérico (`assess_risk/4`)

1.  **Solicitação:** Um módulo chama `DeeperHub.Security.RiskAssessment.assess_risk(user_id, operation_type, operation_data, context_data)`.
2.  **`DefaultRiskAssessmentService`:**
    *   **Coleta de Dados:**
        *   Obtém perfil de risco do `user_id` (se existir).
        *   Obtém dados de `LoginLocation`, `DeviceFingerprint`, `BehavioralAnalysis` relacionados ao `user_id` e `context_data`.
    *   **Cálculo de Fatores:**
        *   Chama `RiskFactorCalculator` para calcular fatores básicos (ex: `ip_is_known`, `device_is_trusted`).
        *   Chama `AdvancedRiskFactors` para calcular fatores complexos (ex: `behavioral_score`, `geo_velocity_score`).
    *   **Cálculo de Score:**
        *   Envia a lista de `{fator, valor}` para `RiskCalculatorService`.
        *   `RiskCalculatorService` obtém os pesos dos fatores (de `SecurityPolicyManager`) e calcula a pontuação de risco agregada e o nível de risco.
    *   **Recomendação de Ação:**
        *   Envia o `operation_type` e `risk_level` para `RiskActionRecommender`.
        *   `RiskActionRecommender` consulta as políticas (de `SecurityPolicyManager`) e retorna uma lista de ações (ex: `[:allow, :log_medium_risk]`).
    *   **Registro e Atualização:**
        *   Registra a avaliação completa (fatores, score, ações) no `RiskAssessmentLog`.
        *   (Opcional) Enfileira uma atualização para o `RiskProfile` do usuário.
    *   **Resposta:** Retorna o `RiskAssessmentResult.t()` para o chamador.

## 📡 6. API (Funções Públicas da Fachada)

*(Baseado no que já foi documentado e consolidado)*

### 6.1. `DeeperHub.Security.RiskAssessment.assess_risk(user_id :: String.t() | nil, operation_type :: atom(), operation_data :: map(), context_data :: map(), opts :: keyword()) :: {:ok, RiskAssessmentResult.t()} | {:error, term()}`

*   **Descrição:** Avalia o risco de uma operação, considerando o usuário, tipo de operação, dados específicos da operação e contexto.
*   **`operation_type`:** Ex: `:login`, `:password_change`, `:email_update`, `:api_access_resource_x`, `:financial_transaction`.
*   **`operation_data`:** Mapa com dados relevantes para a `operation_type` (ex: para `:financial_transaction`, `%{amount: 100.0, currency: \"USD\", recipient_account: \"...\"}`).
*   **`context_data`:** Mapa com dados contextuais (ex: `%{ip_address: \"1.2.3.4\", user_agent: \"...\", session_id: \"...\", device_fingerprint: \"...\"}`).
*   **`opts`:** Opções adicionais, como `:force_recalculation` (ignorar cache de perfil de risco).
*   **`RiskAssessmentResult.t()`:** `%{risk_score: float(), risk_level: atom(), recommended_actions: list(atom()), contributing_factors: list(%{factor: atom(), value: term(), score_impact: float()}), assessment_id: String.t()}`.

### 6.2. `DeeperHub.Security.RiskAssessment.get_user_risk_profile(user_id :: String.t(), opts :: keyword()) :: {:ok, UserRiskProfile.t()} | {:error, :not_found | term()}`

*   **Descrição:** Obtém o perfil de risco atual de um usuário.
*   **`UserRiskProfile.t()`:** Mapa contendo dados como `%{average_login_risk: float(), last_high_risk_event_at: DateTime.t() | nil, typical_locations: list(map()), known_devices: list(String.t()), behavioral_baseline_summary: map()}`.

### 6.3. `DeeperHub.Security.RiskAssessment.get_assessment_details(assessment_id :: String.t()) :: {:ok, RiskAssessmentLog.t()} | {:error, :not_found | term()}` (Nova Sugestão)

*   **Descrição:** Recupera os detalhes completos de uma avaliação de risco específica pelo seu ID.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :risk_assessment, :enabled]`** (Boolean): Habilita/desabilita o módulo.
*   **`[:security, :risk_assessment, :default_weights, <factor_name>]`** (Float): Peso padrão para cada fator de risco.
    *   Ex: `[:security, :risk_assessment, :default_weights, :ip_reputation_score] = 0.15`
*   **`[:security, :risk_assessment, :risk_level_thresholds]`** (Map): Mapeamento de scores para níveis.
    *   Ex: `%{critical: 90, high: 70, medium: 40, low: 20}` (scores acima do valor são o nível).
*   **`[:security, :risk_assessment, :action_policies]`** (List de Maps): Regras para mapear `operation_type` e `risk_level` para `recommended_actions`.
    *   Ex: `%{operation_type: :login, risk_level: :high, actions: [:challenge_mfa, :notify_user]}`
*   **`[:security, :risk_assessment, :profile_history_days]`** (Integer): Quantos dias de dados usar para construir/atualizar perfis de risco.
*   **`[:security, :risk_assessment, :log_retention_days]`** (Integer): Retenção para logs de avaliação de risco.
*   **`[:security, :risk_assessment, :factors_enabled, <factor_name>]`** (Boolean): Habilita/desabilita fatores de risco específicos.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `DeeperHub.Security.Policy.SecurityPolicyManager`: Essencial para obter pesos, limiares e regras de ação.
*   `DeeperHub.Security.LoginLocation`, `DeeperHub.Security.DeviceFingerprint`, `DeeperHub.Security.BehavioralAnalysis`: Fornecedores chave de fatores de risco.
*   `DeeperHub.Security.FraudDetection`: Pode ser tanto um consumidor dos resultados do RiskAssessment quanto um provedor de um fator de risco (\"fraude detectada anteriormente\").
*   `DeeperHub.Accounts`: Para dados de usuário.
*   `DeeperHub.MFA`: Para executar ações como `:require_mfa`.
*   `DeeperHub.Audit`: Para logar as avaliações.

### 8.2. Bibliotecas Externas

*   Nenhuma dependência externa direta crucial para o orquestrador, mas os módulos de cálculo de fatores (`AdvancedRiskFactors`) podem usar bibliotecas de ML/estatística.

## 🤝 9. Como Usar / Integração

O `RiskAssessment` é tipicamente chamado por outros módulos de segurança ou de domínio antes de permitir operações sensíveis.

**Exemplo em `DeeperHub.Auth` durante o login:**
```elixir
# Dentro do fluxo de login, após a verificação primária da senha
context_data = %{ip_address: ip, device_fingerprint: fp, user_agent: ua}
case DeeperHub.Security.RiskAssessment.assess_risk(user.id, :login, %{}, context_data) do
  {:ok, %{recommended_actions: actions}} ->
    if :block in actions do
      {:error, :login_blocked_high_risk}
    elif :challenge_mfa in actions and UserMFASettings.is_enabled?(user.id) do
      {:error, :mfa_required_due_to_risk} # Sinaliza para o frontend iniciar fluxo MFA
    else
      # Prosseguir com a criação da sessão
      # ...
    end
  {:error, _reason} ->
    # Falha segura: talvez negar ou exigir MFA se o risk assessment falhar
    Logger.error(\"Falha na avaliação de risco do login para user_id: #{user.id}\")
    {:error, :mfa_required_risk_assessment_failed} 
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a orquestração do `DefaultRiskAssessmentService` com mocks para os calculadores de fatores e recomendador de ações.
*   Testar cada serviço (`RiskFactorCalculator`, `AdvancedRiskFactors`, `RiskCalculatorService`, `RiskActionRecommender`) individualmente com diversos cenários de entrada.
*   Testar a lógica de persistência e recuperação de `RiskProfile` e `RiskAssessmentLog`.
*   Localização: `test/deeper_hub/security/risk_assessment/`.

### 10.2. Métricas

*   `deeper_hub.security.risk_assessment.evaluations.count` (tags: `operation_type`, `resulting_risk_level`)
*   `deeper_hub.security.risk_assessment.evaluation.duration_ms` (Histograma, tags: `operation_type`)
*   `deeper_hub.security.risk_assessment.factor_calculation.duration_ms` (Histograma, tags: `factor_name`)
*   `deeper_hub.security.risk_assessment.actions_taken.count` (tags: `operation_type`, `action_taken`, `original_risk_level`)
*   `deeper_hub.security.risk_assessment.profiles.updated.count` (Contador)

### 10.3. Logs

*   **Nível DEBUG:** Valores detalhados de cada fator de risco calculado durante uma avaliação.
*   **Nível INFO:** Resultado de cada avaliação de risco (score, nível, ações recomendadas, ID da avaliação).
*   **Nível WARNING:** Avaliações resultando em risco alto ou crítico, ou quando uma operação é bloqueada devido ao risco.
*   **Nível ERROR:** Falhas no processo de avaliação, incapacidade de calcular fatores essenciais.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :risk_assessment, :assess_operation, :start | :stop | :exception]`
    *   Metadados: `%{operation_type: type, user_id: id, context_keys: keys(context_data)}`
    *   No `:stop`: `%{risk_score: score, risk_level: level, recommended_actions: actions, assessment_id: id}`
*   `[:deeper_hub, :security, :risk_assessment, :factor_calculated]`
    *   Metadados: `%{assessment_id: id, factor_name: name, factor_value: value, score_contribution: contrib}`
*   `[:deeper_hub, :security, :risk_assessment, :action_recommended]`
    *   Metadados: `%{assessment_id: id, operation_type: type, risk_level: level, actions: actions}`

## ❌ 11. Tratamento de Erros

*   Se um fator de risco específico não puder ser calculado (ex: serviço de geolocalização offline), o sistema deve usar um valor padrão ou um peso neutro para esse fator, logar o problema e continuar a avaliação com os fatores disponíveis.
*   Uma falha completa no `RiskAssessmentService` deve ser tratada como um cenário de alto risco pelo chamador, aplicando a política de segurança mais restritiva (ex: negar a operação).

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Integridade dos Dados de Entrada:** O `RiskAssessment` confia nos dados fornecidos por outros módulos (IP, dispositivo, comportamento). A segurança desses módulos é indiretamente crucial.
*   **Segurança das Políticas de Risco:** As configurações de pesos, limiares e regras de ação são críticas e devem ser protegidas contra acesso não autorizado (responsabilidade do `SecurityPolicyManager`).
*   **Manipulação de Perfil:** Um invasor não deve ser capaz de manipular seu perfil de risco para parecer de baixo risco. A atualização dos perfis deve ser um processo controlado.

## 🧑‍💻 13. Contribuição

*   A adição de novos fatores de risco deve ser acompanhada de uma análise de seu impacto potencial e da disponibilidade/confiabilidade dos dados necessários.
*   As regras de recomendação de ação devem ser claras e cobrir todos os níveis de risco e tipos de operação relevantes.
*   Mantenha a lógica de cálculo de fatores e de pontuação o mais transparente e testável possível.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar aprendizado de máquina para otimizar dinamicamente os pesos dos fatores de risco e identificar novos padrões de risco.
*   [ ] Adicionar capacidade de simulação (\"what-if\") para testar o impacto de mudanças nas políticas de risco em dados históricos.
*   [ ] Desenvolver uma UI para visualização de perfis de risco, histórico de avaliações e ajuste manual de pesos/limiares por administradores.
*   [ ] Permitir a definição de \"contextos de risco\" personalizados (ex: \"período de alta promoção\", \"novo lançamento de feature\") que podem influenciar temporariamente os pesos ou limiares.
*   [ ] Integração com Threat Intelligence Feeds para enriquecer fatores de risco como reputação de IP.

---

*Última atualização: 2025-05-11*

---

O `RiskAssessment` é um módulo integrador bem interessante!

Qual o próximo? Talvez `DeeperHub.Security.DeviceFingerprint` e `DeeperHub.Security.GeoLocationService`, que são importantes provedores de fatores de risco? Ou prefere algo do Core, como `DeeperHub.Core.Cache`?"""),
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
                types.Part.from_text(text="""Entendido! Vamos seguir com `DeeperHub.Security.DeviceFingerprint` e, em seguida, podemos abordar `DeeperHub.Security.GeoLocationService`, pois ambos são fontes importantes de informação para o `RiskAssessment`.

---

