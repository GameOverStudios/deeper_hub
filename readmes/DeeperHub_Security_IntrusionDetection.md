# Módulo: `DeeperHub.Security.IntrusionDetection` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.IntrusionDetection`

O módulo `DeeperHub.Security.IntrusionDetection` (IDS) funciona como um sistema de vigilância para o DeeperHub, monitorando atividades e eventos em busca de padrões que possam indicar uma tentativa de intrusão ou exploração de vulnerabilidades. Diferente da detecção de fraude (que foca em abuso de funcionalidades legítimas para ganho ilícito) ou da proteção contra força bruta (que foca em adivinhação de credenciais), o IDS procura por sinais de reconhecimento, exploração de falhas de segurança conhecidas, ou comportamento anômalo que sugira um ator malicioso tentando obter acesso não autorizado ou escalar privilégios.

Ele analisa logs, eventos de rede (se aplicável no nível da aplicação), e atividades de usuário, comparando-os com um conjunto de regras, assinaturas de ataques conhecidos e, potencialmente, com desvios de comportamento normal estabelecido. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Monitoramento de Atividades (`record_activity/2`):**
    *   Receber e registrar eventos de diversas fontes do sistema (logs de aplicação, eventos de autenticação, acesso a arquivos, chamadas de API, etc.) para análise.
*   **Detecção Baseada em Assinaturas/Regras (`analyze_activity/2`):**
    *   Comparar atividades com um conjunto de regras e assinaturas de ataques conhecidos (ex: tentativas de SQL Injection, XSS, Path Traversal, varredura de diretórios, uso de comandos suspeitos em entradas).
    *   Identificar o uso de ferramentas de hacking comuns através de padrões em User-Agents ou parâmetros.
*   **Detecção Baseada em Anomalias (Integração):**
    *   Integrar-se com `DeeperHub.Security.BehavioralAnalysis` para identificar desvios significativos do comportamento normal de um usuário que possam indicar comprometimento de conta.
    *   Monitorar sequências de ações incomuns.
*   **Análise de Logs:**
    *   Processar logs da aplicação e do sistema (se acessíveis) para encontrar padrões suspeitos ou mensagens de erro indicativas de uma tentativa de exploração.
*   **Gerenciamento de Alertas de Intrusão (`get_alerts/1`, `generate_alert` via `Security.Monitoring`):**
    *   Gerar alertas quando uma atividade suspeita ou uma intrusão potencial é detectada.
    *   Classificar alertas por severidade (baixo, médio, alto, crítico).
*   **Resposta a Incidentes (Limitada/Coordenada):**
    *   Tomar ações de resposta configuráveis (ex: bloquear IP via `IPFirewallService`, invalidar sessão do usuário via `Auth.SessionManager`, notificar administradores via `Security.Monitoring`).
    *   Fornecer informações detalhadas para auxiliar na investigação manual de incidentes.
*   **Configuração de Regras e Assinaturas (`configure_rules/1`):**
    *   Permitir a atualização e customização do conjunto de regras e assinaturas de detecção.
*   **Relatórios e Estatísticas (`get_statistics/1`):**
    *   Fornecer dados sobre intrusões detectadas, tipos de ataque, fontes, etc.
*   **Verificação de Reputação (IP/Usuário) (`check_ip/1`, `check_user/1`):**
    *   Manter um histórico de atividades suspeitas por IP ou usuário para auxiliar na avaliação de risco contínua.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.IntrusionDetection` (Fachada Pública):**
    *   Ponto de entrada para registrar atividades e consultar o status do IDS.
    *   Delega para o `IntrusionDetectionService`.
2.  **`DeeperHub.Security.IntrusionDetection.Services.IntrusionDetectionService` (GenServer):**
    *   **Responsabilidade:** Processo central que recebe eventos de atividade, aplica regras de detecção, gerencia o estado das ameaças percebidas e coordena respostas.
    *   **Estado Interno:**
        *   Conjunto de regras/assinaturas ativas.
        *   Contadores de atividades suspeitas por IP/usuário/tipo de ataque.
        *   Estado de alertas ativos.
    *   **Interações:**
        *   `RuleEngine`: Para aplicar regras de detecção.
        *   `AnomalyDetector` (pode ser parte de `BehavioralAnalysis`): Para detecção baseada em anomalias.
        *   `DeeperHub.Security.IPFirewallService`: Para bloquear IPs.
        *   `DeeperHub.Auth.SessionManager`: Para invalidar sessões.
        *   `DeeperHub.Security.Monitoring`: Para gerar alertas.
        *   `DeeperHub.Audit`: Para registrar intrusões e ações.
        *   `DeeperHub.Core.ConfigManager` / `SecurityPolicyManager`: Para obter regras e configurações.
3.  **`DeeperHub.Security.IntrusionDetection.RuleEngine` (Módulo Funcional):**
    *   **Responsabilidade:** Aplicar o conjunto de regras e assinaturas aos eventos de atividade recebidos.
    *   Pode usar regex, correspondência de padrões, ou lógica mais complexa.
4.  **`DeeperHub.Security.IntrusionDetection.SignatureDatabase` (Módulo/ETS/Arquivo):**
    *   **Responsabilidade:** Armazenar as assinaturas de ataques conhecidos e regras de detecção. Pode ser atualizável.
5.  **Fontes de Eventos (Módulos da Aplicação):**
    *   Diversos módulos (`API`, `Auth`, `FileHandler`, etc.) enviam eventos de atividade para o `IntrusionDetectionService` através de `record_activity/2`.
6.  **`DeeperHub.Security.IntrusionDetection.Supervisor`:**
    *   Supervisiona o `IntrusionDetectionService` e quaisquer workers associados.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/security/intrusion_detection/
├── intrusion_detection.ex            # Fachada Pública
│
├── services/
│   └── intrusion_detection_service.ex # GenServer principal
│
├── rule_engine.ex                    # Lógica de aplicação de regras
├── signature_database.ex             # Módulo para acesso a assinaturas/regras
│
├── rules/                            # (Opcional) Onde definições de regras podem ser armazenadas
│   └── sql_injection_signatures.exs
│
├── supervisor.ex
└── telemetry.ex
```
*(O `IntrusionDetectionAdapter` e `IntrusionDetectionBehaviour` da documentação original são consolidados aqui.)*

### 3.3. Decisões de Design Importantes

*   **Performance:** A análise de atividades deve ser eficiente para não sobrecarregar o sistema, especialmente se for síncrona em alguns pontos. Muitas análises podem ser assíncronas.
*   **Taxa de Falsos Positivos/Negativos:** Balancear a sensibilidade para detectar ameaças reais sem gerar um volume excessivo de falsos alertas é crucial.
*   **Atualização de Regras/Assinaturas:** O sistema deve permitir a fácil atualização do conjunto de regras e assinaturas para se adaptar a novas ameaças.
*   **Resposta Automatizada vs. Manual:** Definir claramente quais tipos de detecção justificam uma resposta automatizada (ex: bloqueio de IP) versus aquelas que requerem análise manual.

## 🛠️ 4. Casos de Uso Principais

*   **Detecção de Tentativa de SQL Injection na API:**
    *   O `DeeperHub.API` (ou um plug de validação) envia um parâmetro de requisição suspeito para `IntrusionDetection.record_activity(%{type: :api_param, value: \" ' OR 1=1 --\", ...}, context)`.
    *   `IntrusionDetectionService` usa `RuleEngine` que identifica a assinatura de SQLi.
    *   Uma intrusão é registrada, um alerta é gerado para `Security.Monitoring`, e o IP pode ser enviado para `IPFirewallService` para bloqueio.
*   **Múltiplas Tentativas de Acesso a Arquivos Inexistentes (Varredura):**
    *   Um módulo que serve arquivos registra múltiplas tentativas falhas de acesso (404s) de um mesmo IP para caminhos que não existem, mas que parecem ser tentativas de encontrar vulnerabilidades (ex: `/.git/config`, `/admin.php`).
    *   Essas atividades são enviadas para `IntrusionDetection.record_activity/2`.
    *   `RuleEngine` ou `PatternAnalyzer` (dentro do `IntrusionDetectionService`) detecta o padrão de varredura.
    *   O IP é bloqueado e um alerta é gerado.
*   **Comportamento Anômalo de Usuário Após Login:**
    *   `BehavioralAnalysis` detecta um desvio significativo no comportamento de um usuário recém-logado.
    *   `BehavioralAnalysis` envia um evento de \"alta anomalia comportamental\" para o `IntrusionDetectionService`.
    *   `IntrusionDetectionService` pode correlacionar isso com outros fatores (ex: login de IP novo) e escalar para um alerta de possível comprometimento de conta, sugerindo a invalidação da sessão.

## 🌊 5. Fluxos Importantes

### Fluxo de Análise de Atividade Suspeita

1.  **Registro de Atividade:** Um módulo da aplicação (ex: um plug de firewall de aplicação web no nível da API) observa uma atividade (ex: uma requisição HTTP com parâmetros suspeitos) e chama `DeeperHub.Security.IntrusionDetection.record_activity(activity_details, context)`.
2.  **`IntrusionDetectionService` (GenServer):**
    *   Recebe a atividade.
    *   (Opcional) Persiste a atividade bruta para análise forense ou em lote.
    *   Envia a atividade para o `RuleEngine`.
3.  **`RuleEngine`:**
    *   Compara a atividade com o conjunto de regras e assinaturas carregadas da `SignatureDatabase`.
    *   **Regra Acionada:** Se uma ou mais regras/assinaturas corresponderem (ex: padrão de SQLi encontrado):
        *   Retorna os detalhes da(s) regra(s) acionada(s) e uma severidade associada para o `IntrusionDetectionService`.
    *   **Nenhuma Regra Acionada:** Retorna que nenhuma ameaça baseada em assinatura foi encontrada.
4.  **`IntrusionDetectionService` (Continuação):**
    *   **Se Ameaça Detectada:**
        *   Registra a intrusão (`record_intrusion/2`).
        *   Gera um alerta para `DeeperHub.Security.Monitoring` com a severidade e detalhes.
        *   Com base na severidade e na política configurada, toma ações de resposta:
            *   Chama `DeeperHub.Security.IPFirewallService.block_ip(...)`.
            *   Chama `DeeperHub.Auth.SessionManager.invalidate_session_for_user(...)`.
    *   (Opcional) Se nenhuma ameaça baseada em assinatura, mas a atividade for de um tipo que `BehavioralAnalysis` monitora, pode encaminhar para lá.
5.  **Resposta (Assíncrona):** A função `record_activity` geralmente retorna `:ok` rapidamente para não bloquear o chamador. As análises e respostas são tratadas em background.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.IntrusionDetection.record_activity(activity_data :: map(), context :: map() | nil) :: :ok`

*   **Descrição:** Registra uma atividade do sistema para análise pelo IDS. Esta é a principal forma de alimentar o IDS com dados.
*   **`activity_data`:** Mapa descrevendo a atividade. Deve incluir:
    *   `:type` (atom): Tipo de atividade (ex: `:http_request`, `:api_call`, `:file_access_attempt`, `:auth_attempt`).
    *   `:source_ip` (String.t | nil).
    *   `:user_id` (String.t | nil).
    *   `:timestamp` (DateTime.t).
    *   Outros campos específicos do tipo (ex: para `:http_request`, `%{path: \"/\", params: %{...}, headers: %{...}}`).
*   **`context`:** Metadados adicionais.

### 6.2. `DeeperHub.Security.IntrusionDetection.analyze_activity(activity_data :: map(), context :: map() | nil) :: {:ok, :normal | :suspicious | :intrusion_detected, details :: map() | nil}`

*   **Descrição:** Realiza uma análise síncrona de uma atividade específica. Usado quando uma decisão imediata é necessária.
*   **Retorno:** O nível de ameaça percebido e detalhes (ex: regras acionadas).

### 6.3. `DeeperHub.Security.IntrusionDetection.check_ip_reputation(ip_address :: String.t()) :: {:ok, %{risk_score: float(), known_threats: list(atom())}}` (Nova Sugestão)

*   **Descrição:** Consulta a base de dados interna do IDS (e potencialmente feeds externos) sobre a reputação de um IP.
*   **Retorno:** Score de risco e ameaças conhecidas associadas ao IP.

### 6.4. `DeeperHub.Security.IntrusionDetection.get_alerts(opts :: keyword()) :: {:ok, list(Alert.t())}`

*   **Descrição:** Lista os alertas de intrusão ativos ou recentes.
*   **`opts`:** `:severity_threshold` (atom), `:since` (DateTime.t), `:limit`.
*   **`Alert.t()`:** `%{id: String.t(), timestamp: DateTime.t(), type: atom(), severity: atom(), source_ip: String.t(), user_id: String.t(), description: String.t(), details: map(), status: :new | :acknowledged | :resolved}`.

### 6.5. `DeeperHub.Security.IntrusionDetection.configure_rules(rules_list :: list(map())) :: :ok | {:error, term()}`

*   **Descrição:** Atualiza ou substitui o conjunto de regras de detecção. Requer permissão de administrador.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :intrusion_detection, :enabled]`** (Boolean): Habilita/desabilita o IDS. (Padrão: `true`)
*   **`[:security, :intrusion_detection, :rules_source]`** (String | Module): Fonte das regras/assinaturas (ex: path de arquivo, módulo Elixir, tabela de DB).
*   **`[:security, :intrusion_detection, :default_action_on_detection, <severity>]`** (Map): Ação padrão para cada nível de severidade de intrusão.
    *   Ex: `%{critical: [:block_ip_permanent, :invalidate_session, :alert_admin_urgent], high: [:block_ip_temporary, :alert_admin]}`
*   **`[:security, :intrusion_detection, :ip_block_duration_on_intrusion_seconds]`** (Integer): Duração padrão para bloqueios de IP por intrusão.
*   **`[:security, :intrusion_detection, :event_log_retention_days]`** (Integer): Retenção para logs de atividade bruta.
*   **`[:security, :intrusion_detection, :alert_aggregation_window_seconds]`** (Integer): Janela para agregar múltiplos alertas similares em um único.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`, `Core.Logger`, `Core.Metrics`, `Core.EventBus`.
*   `DeeperHub.Security.IPFirewallService`: Para bloquear IPs.
*   `DeeperHub.Auth.SessionManager`: Para invalidar sessões.
*   `DeeperHub.Security.Monitoring`: Para gerar e encaminhar alertas.
*   `DeeperHub.Audit`: Para registrar intrusões confirmadas.
*   `DeeperHub.Security.BehavioralAnalysis`: Como uma fonte de eventos de anomalia.
*   `DeeperHub.Security.SqlInjectionProtection`, `XssProtection`, `PathTraversalProtection`: Podem alimentar o IDS com suas detecções.

### 8.2. Bibliotecas Externas

*   Bibliotecas de parsing de logs (se aplicável).
*   Bibliotecas para análise de padrões ou regex avançado.

## 🤝 9. Como Usar / Integração

*   **Plugs de Segurança:** Plugs no pipeline Phoenix podem chamar `IntrusionDetection.record_activity/2` com detalhes da requisição.
    ```elixir
    # Exemplo de Plug
    def call(conn, _opts) do
      activity = %{
        type: :http_request,
        source_ip: inspect(conn.remote_ip),
        path: conn.request_path,
        method: conn.method,
        headers: conn.req_headers,
        params: conn.params # Cuidado com dados sensíveis aqui! Sanitize antes.
      }
      user_id = conn.assigns.current_user_id # Se já autenticado
      context = %{user_id: user_id, session_id: Plug.Conn.get_session(conn, :session_id)}
      DeeperHub.Security.IntrusionDetection.record_activity(activity, context)
      conn
    end
    ```
*   **Módulos de Serviço:** Qualquer serviço que lide com operações sensíveis ou entradas do usuário deve registrar atividades relevantes.
    *   Ex: `DeeperHub.Accounts` pode registrar `:auth_attempt_failed`.
    *   Serviços de upload de arquivos podem registrar `:file_access_attempt`.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o `RuleEngine` com várias atividades e verificar se as regras corretas são acionadas.
*   Simular sequências de atividades que deveriam disparar uma detecção de padrão.
*   Testar as ações de resposta (bloqueio de IP, invalidação de sessão) com mocks.
*   Verificar se os alertas são gerados corretamente.
*   Localização: `test/deeper_hub/security/intrusion_detection/`.

### 10.2. Métricas

*   `deeper_hub.security.ids.activities_recorded.count` (tags: `activity_type`)
*   `deeper_hub.security.ids.intrusions_detected.count` (tags: `rule_id`, `severity`, `source_ip_masked`)
*   `deeper_hub.security.ids.alerts_generated.count` (tags: `severity`)
*   `deeper_hub.security.ids.actions_taken.count` (tags: `action_type` (`block_ip`, `invalidate_session`))
*   `deeper_hub.security.ids.rule_engine.processing_time_ms` (Histograma)

### 10.3. Logs

*   **Nível INFO:** Atividades normais sendo processadas (se em modo de depuração verboso).
*   **Nível WARNING:** Atividade suspeita detectada que acionou uma regra de baixa/média severidade.
*   **Nível ERROR/CRITICAL:** Intrusão de alta/crítica severidade detectada. Ação de bloqueio executada. Falha no próprio serviço IDS.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :ids, :activity_analyzed]`
    *   Metadados: `%{activity_type: type, source_ip: ip, user_id: id, rules_triggered: list_of_rule_ids, detection_severity: severity}`
*   `[:deeper_hub, :security, :ids, :response_action_taken]`
    *   Metadados: `%{action: type, target_ip: ip, target_user_id: id, rule_id: id, severity: severity}`

## ❌ 11. Tratamento de Erros

*   Se o `IntrusionDetectionService` falhar ou ficar sobrecarregado, ele não deve impedir o funcionamento normal da aplicação. As chamadas para `record_activity` devem ser \"fire-and-forget\" ou ter timeouts curtos.
*   Falhas na aplicação de uma ação de resposta (ex: erro ao bloquear IP) devem ser logadas e, possivelmente, gerar um alerta secundário.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Segurança das Regras:** O repositório de regras/assinaturas deve ser protegido contra modificações não autorizadas.
*   **Evasão:** Atacantes podem tentar ofuscar suas atividades para evitar a detecção pelas regras atuais. As regras precisam ser atualizadas.
*   **Performance:** Processar um grande volume de atividades em tempo real pode ser custoso. Otimizações, amostragem ou processamento assíncrono para algumas análises podem ser necessários.

## 🧑‍💻 13. Contribuição

*   Novas regras e assinaturas devem ser bem testadas para evitar falsos positivos.
*   A integração de novas fontes de eventos de atividade deve fornecer contexto suficiente para uma análise eficaz.
*   Considere o impacto na performance ao adicionar regras muito complexas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar um mecanismo de aprendizado para que o IDS possa se adaptar a novos padrões de ataque ou ao comportamento normal do sistema.
*   [ ] Permitir que administradores criem e testem regras customizadas através de uma UI.
*   [ ] Integração com feeds de Threat Intelligence para obter assinaturas de ataques atualizadas.
*   [ ] Desenvolver análises de correlação mais sofisticadas entre diferentes tipos de atividades e ao longo do tempo.
*   [ ] Adicionar a capacidade de \"simular\" a aplicação de regras em dados históricos para testar sua eficácia antes de ativá-las.
*   [ ] Suporte para análise de tráfego de rede mais profunda (requereria integração em nível de infraestrutura, não apenas aplicação).

---

*Última atualização: 2025-05-12*

---

Este módulo IDS é um componente de defesa bastante ativo!

Para o próximo, podemos ir para `DeeperHub.Core.Repo` como sugerido anteriormente, ou talvez outro módulo de segurança como o `DeeperHub.Security.DataMasking` para ver como os dados são protegidos em logs e UI?"""),
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
                types.Part.from_text(text="""Perfeito! Dado que já documentamos o `DeeperHub.Core.Repo`, e ele é uma dependência fundamental para quase todos os outros módulos, vamos prosseguir com ele.

---

