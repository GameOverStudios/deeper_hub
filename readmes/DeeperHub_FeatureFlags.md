# Módulo: `DeeperHub.FeatureFlags` 🚩

## 📜 1. Visão Geral do Módulo `DeeperHub.FeatureFlags`

O módulo `DeeperHub.FeatureFlags` é responsável pelo gerenciamento e avaliação de feature flags (também conhecidas como feature toggles) dentro do sistema DeeperHub. Ele permite que funcionalidades sejam habilitadas ou desabilitadas dinamicamente em tempo de execução, sem a necessidade de um novo deploy de código. Isso facilita o lançamento gradual de novas features (canary releases, A/B testing), o controle de acesso a funcionalidades beta, a rápida desativação de features problemáticas e a personalização da experiência do usuário. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Definição e Registro de Feature Flags:**
    *   Permitir o registro de novas feature flags com nome, descrição e estado padrão (habilitada/desabilitada).
    *   Suporte a metadados adicionais para cada flag (ex: data de criação, dono, tags).
*   **Avaliação de Feature Flags:**
    *   Verificar se uma feature flag está habilitada para um determinado contexto (global, por usuário, por grupo de usuários, por tenant, por porcentagem de rollout, etc.).
    *   Suporte a regras de segmentação complexas (ex: habilitar para usuários em um país específico com um plano premium).
*   **Gerenciamento de Estado das Flags:**
    *   Habilitar e desabilitar flags globalmente ou para contextos específicos.
    *   Configurar porcentagens de rollout para lançamento gradual.
*   **Persistência de Configuração das Flags:**
    *   Armazenar a configuração das flags e suas regras (ex: via `Core.ConfigManager` ou banco de dados dedicado).
*   **Cache de Avaliação de Flags:**
    *   Implementar cache para otimizar a performance da avaliação de flags, especialmente para flags frequentemente consultadas.
*   **Notificação de Mudanças:**
    *   Publicar eventos (via `Core.EventBus`) quando o estado de uma flag é alterado, permitindo que componentes interessados reajam.
*   **Integração com RBAC (Role-Based Access Control):**
    *   Permitir que o acesso a certas features seja controlado por papéis de usuário definidos no `DeeperHub.RBAC`.
*   **Auditoria:**
    *   Registrar todas as alterações no estado das feature flags (quem alterou, quando, qual flag, qual o novo estado) no `DeeperHub.Audit`.
*   **Interface de Gerenciamento (Opcional):**
    *   Fornecer uma interface (via `DeeperHub.Console` ou UI de admin) para gerenciar as flags.

## 🏗️ 3. Arquitetura e Design

O `DeeperHub.FeatureFlags` atuará como uma fachada que interage com um serviço de gerenciamento de flags e um sistema de cache.

*   **Interface Pública (`DeeperHub.FeatureFlags.FeatureFlagFacade` ou `DeeperHub.FeatureFlags`):** Funções como `enabled?/3`, `register_feature/3`, `enable/3`.
*   **Serviço de Feature Flags (`DeeperHub.FeatureFlags.Services.DefaultFeatureFlagService`):**
    *   Implementa a lógica de negócio para gerenciar e avaliar flags.
    *   Lida com a persistência das configurações das flags (possivelmente via `Core.ConfigManager` para configurações mais estáticas ou um banco de dados para configurações dinâmicas).
    *   Contém a lógica para avaliar regras de segmentação.
*   **Cache de Flags (`DeeperHub.FeatureFlags.Cache.FlagCache`):**
    *   Armazena o estado avaliado das flags para contextos específicos para acesso rápido.
    *   Utiliza o `DeeperHub.Core.Cache` ou uma implementação ETS dedicada.
*   **Integrações:**
    *   `DeeperHub.Core.ConfigManager`: Para armazenar/recuperar configurações de flags.
    *   `DeeperHub.Core.EventBus`: Para notificar mudanças.
    *   `DeeperHub.Audit`: Para registrar alterações.
    *   `DeeperHub.RBAC`: Para controle de acesso baseado em papéis.

**Padrões de Design:**

*   **Fachada (Facade):** Interface simplificada para o sistema de flags.
*   **Strategy (Opcional):** Para diferentes mecanismos de avaliação de regras de segmentação.
*   **Observer (via EventBus):** Para notificar outros módulos sobre mudanças nas flags.

### 3.1. Componentes Principais

*   **`DeeperHub.FeatureFlags.FeatureFlagFacade` (ou `DeeperHub.FeatureFlags`):** O ponto de entrada principal.
*   **`DeeperHub.FeatureFlags.Services.DefaultFeatureFlagService`:** O motor de gerenciamento e avaliação de flags.
*   **`DeeperHub.FeatureFlags.Cache.FlagCache`:** Cache para avaliações de flags.
*   **`DeeperHub.FeatureFlags.Schema.FeatureFlag` (se persistido em DB):** Schema para armazenar a definição da flag.
*   **`DeeperHub.FeatureFlags.Schema.FeatureRule` (se persistido em DB):** Schema para armazenar regras de segmentação.
*   **`DeeperHub.FeatureFlags.Integrations.*`:** Módulos para integração com Auditoria, Eventos, RBAC.
*   **`DeeperHub.FeatureFlags.Supervisor`:** Supervisiona os processos do módulo.

### 3.3. Decisões de Design Importantes

*   **Fonte da Verdade das Configurações:** Decidir onde as configurações das flags (definições, estado, regras) são armazenadas (ConfigManager, banco de dados dedicado, serviço externo de feature flags). Um sistema híbrido pode ser usado, onde definições são mais estáticas e o estado/regras são dinâmicos.
*   **Granularidade do Contexto:** Definir a granularidade dos contextos de avaliação (usuário, tenant, IP, versão da app, etc.) e como esses contextos são passados para a função de avaliação.
*   **Estratégia de Cache e Invalidação:** Como o cache será invalidado quando uma flag for alterada (ex: via eventos do EventBus).

## 🛠️ 4. Casos de Uso Principais

*   **Lançamento de Nova Feature para Usuários Beta:** Uma nova feature \"Dashboard V2\" é habilitada apenas para usuários no grupo \"beta_testers\".
    *   `FeatureFlags.enabled?(\"dashboard_v2\", %{user_id: current_user.id, groups: [\"beta_testers\"]})`
*   **Teste A/B de um Novo Algoritmo:** 50% dos usuários veem o algoritmo antigo, 50% veem o novo.
    *   `FeatureFlags.enabled?(\"new_search_algorithm\", %{user_id: current_user.id, rollout_percentage: true})` (a lógica de porcentagem fica dentro do serviço).
*   **Desabilitar Feature com Problemas em Produção:** Um administrador desabilita rapidamente a feature \"realtime_chat\" via console ou UI de admin porque ela está causando instabilidade.
*   **Feature Específica para Plano Premium:** A feature \"advanced_analytics\" só está disponível para usuários com o plano \"premium\".
    *   `FeatureFlags.enabled?(\"advanced_analytics\", %{user_plan: \"premium\"})`

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Avaliação de uma Feature Flag (`enabled?/3`):**

1.  O código da aplicação chama `DeeperHub.FeatureFlags.enabled?(\"feature_x\", context_map, default_value)`.
2.  A fachada delega para `DeeperHub.FeatureFlags.Services.DefaultFeatureFlagService.is_enabled?/3`.
3.  O serviço primeiro tenta buscar o resultado da avaliação do `FlagCache` usando a `feature_name` e uma chave derivada do `context_map`.
4.  **Cache Hit:** Se encontrado e não expirado, o valor booleano é retornado.
5.  **Cache Miss:**
    *   O serviço busca a definição da `feature_x` e suas regras de segmentação (do ConfigManager ou DB).
    *   Se a flag não existir, retorna `default_value`.
    *   Avalia as regras de segmentação com base no `context_map` fornecido.
    *   Determina se a flag está habilitada (true/false) para o contexto.
    *   Armazena o resultado no `FlagCache` com um TTL.
    *   Retorna o resultado da avaliação.
6.  O resultado booleano é retornado ao chamador.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.FeatureFlags.enabled?/2` ou `enabled?/3`

*   **Descrição:** Verifica se uma feature flag está habilitada para um determinado contexto.
*   **`@spec`:**
    *   `enabled?(feature_name :: atom() | String.t(), context :: map()) :: boolean()`
    *   `enabled?(feature_name :: atom() | String.t(), context :: map(), default_value :: boolean()) :: boolean()`
*   **Parâmetros:**
    *   `feature_name` (atom | String): O nome da feature flag.
    *   `context` (map): Um mapa contendo dados contextuais para avaliação da flag (ex: `%{user_id: \"123\", tenant_id: \"abc\", ip_address: \"1.2.3.4\"}`).
    *   `default_value` (boolean, opcional): Valor a ser retornado se a flag não for encontrada ou não puder ser avaliada. (Padrão: `false`).
*   **Retorno:** `true` se a feature estiver habilitada para o contexto, `false` caso contrário.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    user_context = %{user_id: current_user.id, country: current_user.country}
    if DeeperHub.FeatureFlags.enabled?(:new_billing_page, user_context) do
      # Mostrar nova página de faturamento
    else
      # Mostrar página antiga
    end

    # Usando com valor padrão
    show_beta_feature = DeeperHub.FeatureFlags.enabled?(:super_beta_feature, %{}, false)
    ```

### 6.2. `DeeperHub.FeatureFlags.register_feature/3` (Para Admin/Dev)

*   **Descrição:** Registra uma nova feature flag no sistema.
*   **`@spec`:** `register_feature(feature_name :: atom() | String.t(), description :: String.t(), opts :: Keyword.t()) :: :ok | {:error, reason}`
*   **Parâmetros:**
    *   `feature_name`: Nome único da feature flag.
    *   `description`: Descrição da feature flag.
    *   `opts`: Opções adicionais.
        *   `:default_state` (boolean): Estado inicial da flag (`true` para habilitada, `false` para desabilitada). (Padrão: `false`)
        *   `:rules` (list): Lista de regras de segmentação iniciais.
*   **Retorno:** `:ok` ou `{:error, reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    DeeperHub.FeatureFlags.register_feature(:new_dashboard, \"Nova dashboard com widgets personalizáveis\", default_state: true)
    ```

### 6.3. `DeeperHub.FeatureFlags.enable/3` (Para Admin/Dev)

*   **Descrição:** Habilita uma feature flag para um contexto específico ou globalmente.
*   **`@spec`:** `enable(feature_name :: atom() | String.t(), context_rules :: map() | :global, opts :: Keyword.t()) :: :ok | {:error, reason}`
*   **Parâmetros:**
    *   `feature_name`: Nome da feature flag.
    *   `context_rules`: Mapa definindo as regras para habilitar (ex: `%{user_ids: [\"1\", \"2\"]}`) ou `:global` para habilitar para todos.
    *   `opts`: Opções adicionais.
*   **Retorno:** `:ok` ou `{:error, reason}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    # Habilitar globalmente
    DeeperHub.FeatureFlags.enable(:new_dashboard, :global)

    # Habilitar para um grupo de usuários
    DeeperHub.FeatureFlags.enable(:beta_feature, %{user_group: \"testers\"})
    ```

*(Funções `disable/3`, `update_rules/3`, etc., seriam documentadas similarmente)*

## ⚙️ 7. Configuração

*   **ConfigManager:**
    *   `[:feature_flags, :default_evaluation_result]`: Resultado padrão se uma flag não for encontrada. (Padrão: `false`)
    *   `[:feature_flags, :cache_ttl_seconds]`: TTL para o cache de avaliação de flags. (Padrão: `60`)
    *   `[:feature_flags, :storage_backend]`: Módulo backend para persistência das configurações de flags (ex: `DeeperHub.FeatureFlags.Backends.DatabaseBackend` ou `DeeperHub.FeatureFlags.Backends.ConfigManagerBackend`).
    *   `[:feature_flags, :log_evaluation_level]`: Nível de log para avaliações de flags (ex: `:debug`, `:info`). (Padrão: `:info`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para configurações e/ou armazenamento de flags.
*   `DeeperHub.Core.Cache`: Para cache de avaliações.
*   `DeeperHub.Core.EventBus`: Para notificar sobre mudanças de flags.
*   `DeeperHub.Core.Logger`: Para logging.
*   `DeeperHub.Audit`: Para registrar alterações nas flags.
*   `DeeperHub.RBAC` (Opcional): Para integração com controle de acesso.

### 8.2. Bibliotecas Externas

*   Nenhuma dependência externa obrigatória, mas pode usar bibliotecas para parsing de regras complexas se necessário.

## 🤝 9. Como Usar / Integração

O uso primário é verificar se uma feature está habilitada antes de executar um bloco de código.

```elixir
defmodule DeeperHub.MyModule.MyFeature do
  alias DeeperHub.FeatureFlags

  def render_component(user_context) do
    if FeatureFlags.enabled?(:shiny_new_button, user_context) do
      render_shiny_button()
    else
      render_old_button()
    end
  end

  defp render_shiny_button, do: # ...
  defp render_old_button, do: # ...
end
```

Outros módulos podem se inscrever a eventos de mudança de flags via `Core.EventBus` para reagir dinamicamente (ex: limpar caches locais quando uma flag muda).

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a avaliação de flags para diferentes contextos e regras.
*   Testar a habilitação/desabilitação de flags.
*   Testar o funcionamento do cache e sua invalidação.
*   Testar o fallback para valores padrão.
*   Localização: `test/deeper_hub/feature_flags/`

### 10.2. Métricas

*   `deeper_hub.feature_flags.evaluation.count` (Contador): Número de avaliações de flags. Tags: `feature_name`, `result` (true/false), `context_type` (user, global, etc.).
*   `deeper_hub.feature_flags.evaluation.duration_ms` (Histograma): Duração da avaliação de uma flag. Tags: `feature_name`.
*   `deeper_hub.feature_flags.cache.hit_ratio` (Gauge): Taxa de acerto do cache de flags.
*   `deeper_hub.feature_flags.changed.count` (Contador): Número de vezes que o estado de uma flag foi alterado. Tags: `feature_name`, `action` (enabled/disabled).

### 10.3. Logs

*   `Logger.info(\"Feature flag '#{name}' avaliada como '#{result}' para o contexto #{inspect(context)}\", module: DeeperHub.FeatureFlags.Services.DefaultFeatureFlagService)`
*   `Logger.info(\"Feature flag '#{name}' alterada para '#{new_state}' por '#{admin_id}'\", module: DeeperHub.FeatureFlags.Services.DefaultFeatureFlagService)`

### 10.4. Telemetria

*   `[:deeper_hub, :feature_flags, :evaluation]`: Evento para cada avaliação de flag. Payload: `%{feature_name: name, context: ctx, result: res, duration: dur}`.
*   `[:deeper_hub, :feature_flags, :changed]`: Evento quando uma flag é alterada. Payload: `%{feature_name: name, old_state: old, new_state: new, admin_id: id}`.

## ❌ 11. Tratamento de Erros

*   Se uma flag não for encontrada durante a avaliação, o valor `default_value` (ou `false`) deve ser retornado e um aviso logado.
*   Falhas ao persistir alterações em flags devem retornar `{:error, reason}` e serem logadas como erro.

## 🛡️ 12. Considerações de Segurança

*   **Acesso ao Gerenciamento de Flags:** A capacidade de alterar flags deve ser restrita a administradores com as devidas permissões (controlado via RBAC e auditado).
*   **Impacto de Mudanças:** Alterar uma flag pode ter um impacto significativo no comportamento do sistema. Mudanças devem ser feitas com cautela, especialmente em produção.
*   **Consistência:** Em sistemas distribuídos, garantir que todos os nós tenham a visão mais recente do estado das flags pode ser um desafio (cache distribuído ou invalidação via PubSub são importantes).

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas regras de segmentação, garanta que sejam eficientes e testáveis.
*   Considere o impacto no desempenho ao adicionar flags em caminhos críticos do código.
*   Mantenha a documentação das flags atualizada.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Interface de UI para gerenciamento de Feature Flags.
*   [ ] Suporte a \"kill switches\" globais que podem desabilitar múltiplas features de uma vez.
*   [ ] Integração com ferramentas de A/B testing.
*   [ ] Histórico de alterações de flags e a capacidade de reverter para estados anteriores.
*   [ ] Suporte para dependências entre feature flags (ex: feature B só pode ser habilitada se feature A estiver habilitada).

---

*Última atualização: YYYY-MM-DD*

---

Seguimos para `DeeperHub.Console`?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos agora detalhar o README para o módulo `DeeperHub.Console`.

---

