# Módulo: `Elixir.DeeperHub.Security.FraudDetection.Workers.AnalysisWorker` 🕵️

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.FraudDetection.Workers.AnalysisWorker`

O `AnalysisWorker` é um processo GenServer dentro do módulo `DeeperHub.Security.FraudDetection`. Sua principal responsabilidade é executar análises periódicas e assíncronas sobre os dados de eventos e detecções de fraude acumulados. O objetivo é identificar padrões complexos, tendências e anomalias de longo prazo que podem não ser evidentes em análises em tempo real, contribuindo para uma detecção de fraude mais robusta. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Execução Periódica de Análises:**
    *   Rodar em intervalos configuráveis (ex: a cada hora, diariamente) para analisar dados de fraude.
*   **Análise de Padrões e Tendências:**
    *   Identificar padrões de fraude emergentes ou em evolução.
    *   Analisar tendências de tipos específicos de fraude ou em grupos de usuários.
*   **Detecção de Anomalias de Longo Prazo:**
    *   Comparar atividades atuais com baselines históricos mais longos.
    *   Detectar desvios sutis que se acumulam ao longo do tempo.
*   **Agregação de Dados:**
    *   Processar e agregar grandes volumes de dados de eventos de segurança e detecções prévias.
*   **Geração de Relatórios (Potencial):**
    *   Pode ser responsável por preparar dados para relatórios de análise de fraude.
*   **Atualização de Modelos (Potencial, se usar ML):**
    *   Se o sistema de fraude usar modelos de Machine Learning, este worker pode periodicamente acionar o retreinamento ou atualização desses modelos com novos dados.
*   **Integração com Alertas:**
    *   Disparar alertas de maior nível se padrões de fraude significativos forem identificados.

## 🏗️ 3. Arquitetura e Design

*   **Tipo:** GenServer.
*   **Supervisão:** Supervisionado pelo `DeeperHub.Security.FraudDetection.Supervisor`.
*   **Agendamento:** Utiliza `Process.send_after/3` ou um scheduler mais robusto (como `Quantum` integrado via `Core.BackgroundTaskManager`) para execuções periódicas.
*   **Interações:**
    *   Consulta dados de fraude através do `DeeperHub.Security.FraudDetection.Services.DetectionRecorderService` ou diretamente do `Core.Repo`.
    *   Pode interagir com `DeeperHub.Security.FraudDetection.Services.RiskCalculatorService` para reavaliar riscos.
    *   Pode disparar notificações/alertas via `DeeperHub.Notifications` ou `Core.EventBus`.

### 3.1. Componentes Principais

*   **`handle_info(:analyze_now, state)`:** Função principal que dispara o ciclo de análise.
*   Funções privadas para cada tipo de análise (ex: `p_analyze_login_patterns/1`, `p_analyze_transaction_velocity/1`).

### 3.3. Decisões de Design Importantes

*   **Intervalo de Análise:** Definir um intervalo que equilibre a necessidade de detecção com o custo computacional da análise.
*   **Tipos de Análise:** Decidir quais análises de longo prazo são mais valiosas.
*   **Estado do Worker:** Se o worker precisa manter algum estado entre as análises (ex: baselines estatísticos).

## 🛠️ 4. Casos de Uso Principais (como ele opera)

*   **Análise Diária de Fraude:** O worker roda uma vez ao dia para analisar todas as detecções e eventos do dia anterior, buscando por anéis de fraude, usuários com comportamento consistentemente anômalo, etc.
*   **Atualização de Limiares de Risco:** Com base nas tendências observadas, o worker pode sugerir ou automaticamente ajustar limiares de risco no `RiskCalculatorService`.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Análise Periódica:**

1.  O `AnalysisWorker` recebe a mensagem `:analyze_now` (enviada por `Process.send_after`).
2.  Consulta os dados relevantes do período configurado (ex: logs de transações, detecções de login das últimas 24h).
3.  Executa diversos algoritmos de análise:
    *   Agregação de eventos por usuário/IP.
    *   Cálculo de frequências, médias, desvios padrão.
    *   Comparação com perfis históricos.
    *   Busca por padrões conhecidos de fraude.
4.  Se anomalias ou padrões significativos são encontrados:
    *   Novas detecções de fraude podem ser registradas.
    *   Alertas podem ser enviados para a equipe de segurança.
    *   O score de risco de usuários pode ser atualizado.
5.  O worker registra métricas sobre a análise (duração, anomalias encontradas).
6.  Agenda a próxima execução.

## 📡 6. API (Interna do Módulo `FraudDetection`)

Este worker geralmente não expõe uma API pública para outros módulos, mas pode ter mensagens que podem ser enviadas a ele:

*   **`{:run_analysis, options}` (via `GenServer.call` ou `cast`):** Para disparar uma análise manualmente com opções específicas.

## ⚙️ 7. Configuração

*   **ConfigManager (`DeeperHub.Core.ConfigManager`):**
    *   `[:security, :fraud_detection, :analysis_worker, :interval_minutes]`: Intervalo entre as execuções automáticas. (Padrão: `1440` - 24 horas)
    *   `[:security, :fraud_detection, :analysis_worker, :data_window_hours]`: Janela de dados a ser analisada em cada execução. (Padrão: `24`)
    *   `[:security, :fraud_detection, :analysis_worker, :alert_thresholds, :high_risk_user_count]`: Limiar para alertar se muitos usuários de alto risco forem detectados.

## 🔗 8. Dependências

*   `DeeperHub.Core.Repo`
*   `DeeperHub.Security.FraudDetection.Services.DetectionRecorderService`
*   `DeeperHub.Security.FraudDetection.Services.RiskCalculatorService`
*   `DeeperHub.Notifications` ou `DeeperHub.Core.EventBus`
*   `DeeperHub.Core.Logger`, `DeeperHub.Core.Metrics`, `DeeperHub.Core.ConfigManager`

## ✅ 10. Testes e Observabilidade

*   **Testes:** Testar a lógica de análise com conjuntos de dados simulados, verificando se anomalias conhecidas são detectadas. Testar o agendamento e a execução periódica. Local: `test/deeper_hub/security/fraud_detection/workers/analysis_worker_test.exs`.
*   **Métricas:**
    *   `deeper_hub.security.fraud_detection.analysis_worker.run.duration_ms` (Histograma)
    *   `deeper_hub.security.fraud_detection.analysis_worker.anomalies_found.count` (Contador)
    *   `deeper_hub.security.fraud_detection.analysis_worker.last_run_timestamp.gauge` (Gauge)
*   **Logs:** Logar início e fim de cada ciclo de análise, anomalias importantes encontradas, e quaisquer erros durante o processamento.

---

*Última atualização: YYYY-MM-DD*

---

**Exemplo 3: Submódulo de Schema (dentro de `DeeperHub.Tokens`)**

