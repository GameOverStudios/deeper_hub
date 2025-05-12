# Módulo: `DeeperHub.Security.BehavioralAnalysis` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.BehavioralAnalysis`

O módulo `DeeperHub.Security.BehavioralAnalysis` é dedicado a analisar os padrões de comportamento dos usuários ao longo do tempo para construir perfis individuais e detectar desvios que possam indicar comprometimento de conta, fraude ou outras atividades maliciosas. Ele vai além das regras estáticas, aprendendo o \"normal\" para cada usuário e sinalizando atividades que fogem desse padrão.

Este módulo coleta e processa uma variedade de eventos de usuário, como padrões de login (horários, dispositivos, localizações), padrões de navegação na interface, tipos de transações realizadas e até mesmo padrões de digitação (se integrado com `DeeperHub.Biometrics`). O objetivo é identificar anomalias sutis que seriam difíceis de capturar com regras de segurança tradicionais. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Coleta de Eventos de Comportamento:**
    *   Receber e registrar eventos de comportamento de várias partes do sistema (via `record_behavior_event/4`).
    *   Eventos típicos: login, logout, visualização de página, execução de ação, transação, uso de API, etc.
*   **Construção de Perfis Comportamentais de Usuário:**
    *   Processar eventos históricos para construir e manter um perfil de comportamento individual para cada usuário (`get_user_profile/2`, `update_user_profile/2`).
    *   O perfil pode incluir:
        *   Horários de login e atividade típicos.
        *   Dispositivos e endereços IP frequentemente usados.
        *   Localizações geográficas comuns.
        *   Padrões de navegação (sequência de páginas, tempo em página).
        *   Tipos e valores de transações comuns.
        *   Frequência de certas ações.
*   **Análise de Comportamento e Detecção de Anomalias:**
    *   Analisar o comportamento recente de um usuário em comparação com seu perfil estabelecido (`analyze_user_behavior/2`).
    *   Detectar anomalias em tempo real à medida que novos eventos ocorrem (`detect_realtime_anomaly/3`).
    *   Identificar padrões temporais (ex: picos de atividade incomuns) (`detect_temporal_patterns/2`).
*   **Pontuação de Anomalia:**
    *   Atribuir uma pontuação de anomalia a comportamentos desviantes.
    *   Fornecer detalhes sobre quais aspectos do comportamento foram considerados anômalos.
*   **Integração com `RiskAssessment` e `FraudDetection`:**
    *   Fornecer scores de anomalia comportamental como um fator de risco para outros sistemas de segurança.
*   **Gerenciamento de Modelos (Opcional, se ML for usado):**
    *   Treinar e atualizar modelos de aprendizado de máquina para detecção de anomalias comportamentais.
*   **Configurabilidade:**
    *   Permitir a configuração de sensibilidade da detecção, janelas de tempo para análise e quais características comportamentais monitorar.
*   **Observabilidade:**
    *   Registrar métricas e logs sobre eventos processados, perfis construídos e anomalias detectadas.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.BehavioralAnalysis` (Fachada Pública):**
    *   Ponto de entrada para registrar eventos e solicitar análises.
    *   Delega para o `BehavioralAnalysisService`.
2.  **`DeeperHub.Security.BehavioralAnalysis.Services.DefaultBehavioralAnalysisService` (GenServer ou Serviço Coordenador):**
    *   Orquestra a coleta, processamento e análise de dados comportamentais.
    *   Interage com o `EventStore` (para eventos de comportamento), `ProfileStore` (para perfis), `PatternAnalysisService` e `AnomalyDetectionService`.
3.  **`DeeperHub.Security.BehavioralAnalysis.Services.EventStore` (Adapter/Behaviour):**
    *   **Responsabilidade:** Armazenar e recuperar eventos de comportamento brutos.
    *   **Implementação:** Pode ser uma tabela Ecto, um sistema de séries temporais, ou integrado com o `Core.EventBus` se os eventos relevantes já passarem por lá.
4.  **`DeeperHub.Security.BehavioralAnalysis.Services.ProfileStore` (Adapter/Behaviour):**
    *   **Responsabilidade:** Armazenar e recuperar os perfis comportamentais construídos para cada usuário.
    *   **Implementação:** Pode ser uma tabela Ecto ou um armazenamento NoSQL otimizado para perfis.
5.  **`DeeperHub.Security.BehavioralAnalysis.Services.PatternAnalysisService` (Módulo Funcional):**
    *   Contém algoritmos para extrair e identificar padrões dos dados de comportamento (ex: `extract_login_patterns`, `detect_temporal_patterns`).
6.  **`DeeperHub.Security.BehavioralAnalysis.Services.AnomalyDetectionService` (Módulo Funcional ou ML Model Service):**
    *   Contém algoritmos para comparar o comportamento atual com o perfil e detectar anomalias (ex: `analyze_events` para análise em lote, `analyze_realtime_event`).
    *   Pode usar métodos estatísticos (Z-score, desvio padrão) ou modelos de aprendizado de máquina (ex: Isolation Forest, Autoencoders).
7.  **`DeeperHub.Security.BehavioralAnalysis.Schemas.BehaviorProfileSchema` (Ecto Schema):**
    *   Define a estrutura para armazenar os perfis comportamentais.
8.  **`DeeperHub.Security.BehavioralAnalysis.Schemas.BehaviorEventSchema` (Ecto Schema, opcional):**
    *   Define a estrutura para armazenar os eventos de comportamento brutos, se um `EventStore` baseado em Ecto for usado.
9.  **Workers (Opcional):**
    *   `ProfileBuilderWorker`: Para construir ou reconstruir perfis em background.
    *   `BatchAnalysisWorker`: Para análises de anomalias em lote sobre dados históricos.
10. **Configurações (via `DeeperHub.Core.ConfigManager` e `DeeperHub.Security.Policy.SecurityPolicyManager`):**
    *   Limiares de anomalia, janelas de tempo, pesos de características.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/security/behavioral_analysis/
├── behavioral_analysis.ex           # Fachada Pública
│
├── services/
│   ├── default_behavioral_analysis_service.ex # Serviço orquestrador
│   ├── pattern_analysis_service.ex
│   ├── anomaly_detection_service.ex
│   ├── event_store_adapter.ex        # Behaviour para armazenamento de eventos
│   └── profile_store_adapter.ex      # Behaviour para armazenamento de perfis
│
├── storage_implementations/          # Implementações concretas dos StoreAdapters
│   ├── ecto_event_store.ex
│   └── ecto_profile_store.ex
│
├── schemas/
│   ├── behavior_profile_schema.ex
│   └── behavior_event_schema.ex      # Se usado
│
├── workers/                          # Opcional
│   ├── profile_builder_worker.ex
│   └── batch_analysis_worker.ex
│
├── supervisor.ex
└── telemetry.ex
```
*(O `BehavioralAnalysisAdapter` da documentação original pode ser a própria fachada ou o `DefaultBehavioralAnalysisService`)*

### 3.3. Decisões de Design Importantes

*   **Privacidade dos Dados:** A coleta e análise de comportamento do usuário devem ser feitas com considerações de privacidade e, idealmente, com consentimento do usuário. Os dados devem ser anonimizados ou pseudoanonimizados sempre que possível.
*   **Evolução do Perfil:** Os perfis de comportamento devem ser dinâmicos e capazes de se adaptar gradualmente a mudanças legítimas no comportamento do usuário, para evitar falsos positivos.
*   **Explicabilidade (XAI):** Para anomalias detectadas, especialmente se baseadas em ML, é útil ter alguma forma de explicar por que um comportamento foi considerado anômalo.
*   **Compromisso entre Detecção e Falsos Positivos:** Ajustar a sensibilidade do sistema é crucial. Uma sensibilidade muito alta pode gerar muitos falsos positivos, irritando os usuários.

## 🛠️ 4. Casos de Uso Principais

*   **Detecção de Login Anômalo:**
    *   Usuário normalmente faz login de São Paulo entre 9h-18h em dias úteis usando Chrome em um desktop.
    *   Uma tentativa de login ocorre às 3h da manhã de um domingo, de um país diferente, usando um navegador mobile nunca antes visto para esse usuário.
    *   `BehavioralAnalysis` sinaliza múltiplos desvios do perfil normal, resultando em um alto score de anomalia.
*   **Detecção de Navegação Incomum:**
    *   Um usuário que normalmente apenas visualiza perfis e lê artigos, de repente começa a tentar acessar endpoints de administração ou realizar exclusões em massa.
    *   `BehavioralAnalysis` detecta um desvio significativo nos padrões de navegação e tipos de ação.
*   **Identificação de Conta Comprometida:**
    *   Após um login (potencialmente já sinalizado como de risco), o \"usuário\" começa a realizar ações muito diferentes do perfil estabelecido (ex: alterar rapidamente email, senha, configurações de segurança; tentar transferências para novos destinatários).
    *   `BehavioralAnalysis` contribui com um alto score de anomalia para o `RiskAssessment`, que pode levar ao bloqueio da sessão e notificação.

## 🌊 5. Fluxos Importantes

### Fluxo de Registro e Processamento de Evento Comportamental

1.  **Módulo de Domínio:** Realiza uma ação (ex: `DeeperHub.Accounts` processa um login).
2.  **Registro do Evento:** O módulo de domínio chama `DeeperHub.Security.BehavioralAnalysis.record_behavior_event(user_id, :login, %{ip: \"...\", device_type: \"...\"}, context)`.
3.  **`DefaultBehavioralAnalysisService`:**
    *   Recebe o evento.
    *   Chama o `EventStore` para persistir o evento bruto.
    *   **Análise em Tempo Real (Opcional):** Pode chamar `AnomalyDetectionService.analyze_realtime_event(user_id, event_data)` para uma verificação imediata. Se uma anomalia for detectada, pode publicar um evento ou notificar `RiskAssessment`.
    *   **Atualização de Perfil Assíncrona (Opcional):** Pode enfileirar uma tarefa para o `ProfileBuilderWorker` atualizar o perfil do usuário com base no novo evento.
4.  **`ProfileBuilderWorker` (Assíncrono):**
    *   Recupera eventos recentes para o usuário do `EventStore`.
    *   Chama `PatternAnalysisService` para extrair/atualizar padrões (ex: horários de login, dispositivos comuns).
    *   Atualiza o `BehaviorProfileSchema` do usuário no `ProfileStore`.

### Fluxo de Análise Periódica de Anomalias (em lote)

1.  **`BatchAnalysisWorker` (Agendado):** Inicia sua execução.
2.  Para cada usuário (ou um subconjunto):
    *   Recupera o perfil comportamental do `ProfileStore`.
    *   Recupera eventos recentes do `EventStore` para um determinado período.
    *   Chama `AnomalyDetectionService.analyze_events(events, profile, opts)`.
    *   Se anomalias significativas forem encontradas:
        *   Registra as anomalias (ex: em uma tabela de \"anomalias comportamentais\" ou atualizando o `BehaviorProfileSchema`).
        *   Publica um evento `behavioral_anomaly_detected` no `Core.EventBus`.
        *   Notifica o `DeeperHub.Security.Monitoring` ou `RiskAssessment`.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.BehavioralAnalysis.record_behavior_event(user_id :: String.t(), event_type :: atom(), event_data :: map(), context :: map() | nil) :: :ok | {:error, term()}`

*   **Descrição:** Registra um evento de comportamento do usuário para análise subsequente.
*   **`event_type`:** Ex: `:login_success`, `:login_failure`, `:page_view`, `:profile_update_attempt`, `:transaction_initiated`, `:api_call`.
*   **`event_data`:** Mapa com dados específicos do evento (ex: para `:page_view`, `%{path: \"/settings\", duration_ms: 5000}`).
*   **`context`:** Informações como IP, User-Agent, Session ID.
*   **Retorno:** `:ok` se o evento foi aceito para processamento.

### 6.2. `DeeperHub.Security.BehavioralAnalysis.analyze_user_behavior(user_id :: String.t(), opts :: keyword()) :: {:ok, AnomalyReport.t()} | {:error, term()}`

*   **Descrição:** Realiza uma análise sob demanda do comportamento recente de um usuário em comparação com seu perfil.
*   **`opts`:**
    *   `:time_window_hours` (Integer): Janela de tempo para buscar eventos recentes.
    *   `:sensitivity` (Float): Nível de sensibilidade para detecção de anomalias (0.0 a 1.0).
*   **`AnomalyReport.t()`:** `%{user_id: String.t(), anomaly_score: float(), anomalies_detected: list(map()), profile_confidence: float()}`.

### 6.3. `DeeperHub.Security.BehavioralAnalysis.get_user_behavioral_profile(user_id :: String.t()) :: {:ok, BehaviorProfile.t()} | {:error, :not_found | term()}`

*   **Descrição:** Recupera o perfil comportamental consolidado de um usuário.
*   **`BehaviorProfile.t()`:** `%{common_login_times: list(), common_devices: list(), typical_navigation_paths: list(), ...}`.

### 6.4. `DeeperHub.Security.BehavioralAnalysis.update_user_profile(user_id :: String.t(), opts :: keyword()) :: {:ok, BehaviorProfile.t()} | {:error, term()}` (Nova Sugestão)

*   **Descrição:** Força a reconstrução ou atualização do perfil comportamental de um usuário com base nos eventos armazenados.
*   **`opts`:**
    *   `:rebuild_from_scratch` (Boolean): Se `true`, descarta o perfil existente e reconstrói.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :behavioral_analysis, :enabled]`** (Boolean): Habilita/desabilita o módulo. (Padrão: `true`)
*   **`[:security, :behavioral_analysis, :event_retention_days]`** (Integer): Por quantos dias manter eventos de comportamento brutos. (Padrão: `30`)
*   **`[:security, :behavioral_analysis, :profile_update_interval_hours]`** (Integer): Frequência para atualização automática de perfis. (Padrão: `24`)
*   **`[:security, :behavioral_analysis, :min_events_for_profile]`** (Integer): Número mínimo de eventos necessários para construir um perfil inicial confiável. (Padrão: `100`)
*   **`[:security, :behavioral_analysis, :anomaly_thresholds]`** (Map): Limiares para diferentes tipos de anomalias (ex: `%{login_time_deviation_std: 3.0, new_device_score_penalty: 20}`).
*   **`[:security, :behavioral_analysis, :monitored_event_types]`** (List de Atoms): Lista de `event_type` que o sistema deve ativamente coletar e analisar.
*   **`[:security, :behavioral_analysis, :ml_model_path]`** (String, opcional): Caminho para um modelo de ML pré-treinado, se usado.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.EventBus`, `Core.Logger`, `Core.Metrics`, `Core.Repo`.
*   `DeeperHub.Security.LoginLocation`: Para dados de localização.
*   `DeeperHub.Security.DeviceFingerprint`: Para dados de dispositivo.
*   `DeeperHub.Biometrics` (Opcional): Para dados de anomalias biométricas.
*   `DeeperHub.Accounts`: Para informações básicas do usuário.

### 8.2. Bibliotecas Externas

*   Bibliotecas para análise estatística (ex: `Statistics`).
*   Bibliotecas de Machine Learning (se ML for usado, ex: `Nx`, `Axon`).

## 🤝 9. Como Usar / Integração

**Registro de Eventos:** Módulos de domínio devem chamar `record_behavior_event/4` quando ações relevantes do usuário ocorrem.
```elixir
# Exemplo no controller de Profile
def update(conn, params) do
  # ... lógica de atualização ...
  DeeperHub.Security.BehavioralAnalysis.record_behavior_event(
    conn.assigns.current_user.id,
    :profile_field_updated,
    %{field: \"email\", old_value_hash: \"...\", new_value_hash: \"...\"}, # Hashear valores sensíveis
    %{ip_address: conn.remote_ip, user_agent: Plug.Conn.get_req_header(conn, \"user-agent\")}
  )
  # ...
end
```

**Consumindo Análises (Ex: pelo `RiskAssessment`):**
```elixir
def get_behavioral_risk_factor(user_id, current_context) do
  case DeeperHub.Security.BehavioralAnalysis.analyze_user_behavior(user_id, time_window_hours: 24) do
    {:ok, %{anomaly_score: score}} -> score # Normalizar para a escala de fatores de risco
    _ -> 0.0 # Risco neutro se análise falhar ou não houver dados
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a construção de perfis com diferentes conjuntos de eventos.
*   Testar a detecção de anomalias para cenários conhecidos (ex: login de novo dispositivo deve gerar score X).
*   Testar a robustez dos algoritmos de `PatternAnalysisService` e `AnomalyDetectionService`.
*   Verificar se os workers de background (`ProfileBuilderWorker`, `BatchAnalysisWorker`) funcionam corretamente.
*   Localização: `test/deeper_hub/security/behavioral_analysis/`.

### 10.2. Métricas

*   `deeper_hub.security.behavioral_analysis.events_recorded.count` (tags: `event_type`)
*   `deeper_hub.security.behavioral_analysis.profiles_built.count`
*   `deeper_hub.security.behavioral_analysis.anomalies_detected.count` (tags: `anomaly_type`, `user_segment`)
*   `deeper_hub.security.behavioral_analysis.anomaly_score.distribution` (Histograma)
*   `deeper_hub.security.behavioral_analysis.profile_update.duration_ms` (Histograma)
*   `deeper_hub.security.behavioral_analysis.realtime_analysis.duration_ms` (Histograma)

### 10.3. Logs

*   **Nível INFO:** Construção/atualização de perfil bem-sucedida, início/fim de análises em lote.
*   **Nível WARNING:** Anomalias de risco médio detectadas, falha ao construir perfil por falta de dados.
*   **Nível ERROR:** Anomalias de alto risco detectadas, erros internos nos serviços de análise.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :behavioral_analysis, :event_processing, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, event_type: type}`
*   `[:deeper_hub, :security, :behavioral_analysis, :profile_build, :start | :stop | :exception]`
    *   Metadados: `%{user_id: id, event_count: count}`
*   `[:deeper_hub, :security, :behavioral_analysis, :anomaly_detection, :stop]`
    *   Metadados: `%{user_id: id, anomaly_score: score, anomalies: list_of_anomalies}`

## ❌ 11. Tratamento de Erros

*   Falhas na análise de um evento específico não devem impedir o processamento de outros.
*   Se o sistema não conseguir construir um perfil para um usuário (ex: poucos dados), ele deve operar em um modo degradado (ex: confiando mais em regras estáticas) ou atribuir um score de risco neutro/padrão.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Privacidade dos Dados Comportamentais:** Os dados de comportamento do usuário são altamente sensíveis.
    *   Anonimizar ou pseudoanonimizar dados sempre que possível.
    *   Aplicar criptografia em repouso para os perfis e eventos armazenados.
    *   Controle de acesso rigoroso aos dados e resultados da análise.
    *   Políticas claras de retenção e exclusão de dados.
*   **Viés nos Modelos:** Se modelos de ML forem usados, monitorar e mitigar vieses que possam discriminar injustamente certos grupos de usuários.
*   **Ataques de Evasão:** Invasores podem tentar manipular seu comportamento para \"treinar\" um perfil falso ou evitar a detecção. O sistema deve ter mecanismos para detectar tais tentativas.

## 🧑‍💻 13. Contribuição

*   Novas características comportamentais a serem monitoradas devem ser cuidadosamente avaliadas quanto ao seu valor para detecção de risco e impacto na privacidade.
*   Algoritmos de detecção de anomalias devem ser bem documentados e testados.
*   Priorizar a explicabilidade dos resultados da análise.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar modelos de Machine Learning mais sofisticados para detecção de anomalias e construção de perfis.
*   [ ] Adicionar \"feedback de usuário\" sobre anomalias detectadas (ex: \"Sim, fui eu\" ou \"Não, isso não fui eu\") para refinar os perfis.
*   [ ] Permitir que os usuários visualizem (de forma agregada e segura) partes de seu perfil comportamental.
*   [ ] Desenvolver mecanismos para detectar e se adaptar a mudanças graduais e legítimas no comportamento do usuário.
*   [ ] Integrar com mais fontes de eventos (ex: dados de uso de aplicações mobile).
*   [ ] Oferecer diferentes \"níveis de sensibilidade\" para a análise comportamental, configuráveis por tipo de usuário ou contexto.

---

*Última atualização: 2025-05-11*

---

A análise comportamental é um campo fascinante e complexo!

Qual será o próximo módulo? Podemos continuar na área de segurança com `DeeperHub.Security.RiskAssessment` (que consome os dados daqui) ou `DeeperHub.Security.DeviceFingerprint`, ou mudar para um módulo Core como `DeeperHub.Core.Repo`?"""),
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
                types.Part.from_text(text="""Entendido! Vamos detalhar agora o `DeeperHub.Security.RiskAssessment`, que se conecta diretamente com o `BehavioralAnalysis` e outros módulos de segurança para fornecer uma visão consolidada do risco.

---

