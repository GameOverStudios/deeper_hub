# Módulo: `DeeperHub.Core.Cache` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.Cache`

O módulo `DeeperHub.Core.Cache` fornece uma **fachada e um serviço de caching genérico** para o sistema DeeperHub. Seu propósito é melhorar o desempenho da aplicação armazenando temporariamente dados frequentemente acessados ou resultados de operações custosas, reduzindo a latência e a carga sobre fontes de dados primárias (como bancos de dados ou APIs externas).

Ele oferece uma API simples para operações de cache como `put`, `get`, `delete`, e `get_or_store`, abstraindo a implementação de cache subjacente (que pode ser ETS, Redis, Memcached, etc., através de um `CacheAdapter`). 😊

*(Nota: A documentação original tem `DeeperHub.Shared.Cache` e `DeeperHub.Shared.Cache.CacheService` e `CacheAdapter`. Esta documentação consolida a fachada principal em `DeeperHub.Core.Cache` e assume que a lógica de serviço e adaptação reside em `DeeperHub.Shared.Cache.*` ou é diretamente gerenciada pela fachada se for uma implementação simples como ETS.)*

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Armazenamento Chave-Valor:**
    *   Armazenar dados associados a uma chave única (`put/4`).
    *   Recuperar dados com base em uma chave (`get/3`).
*   **Expiração de Cache (TTL - Time To Live):**
    *   Permitir a definição de um tempo de vida para cada entrada de cache.
    *   Automaticamente considerar entradas expiradas como \"misses\".
*   **Invalidação de Cache:**
    *   Remover entradas específicas do cache (`delete/2`).
    *   Remover todas as entradas de um namespace (se suportado) ou o cache inteiro (`clear/1`).
    *   Remover entradas que correspondem a um padrão de chave (`delete_pattern/2`).
*   **Operação \"Get-Or-Store\" (`get_or_store/4`):**
    *   Tentar obter um valor do cache; se for um \"miss\" (não encontrado ou expirado), executar uma função fornecida para gerar o valor, armazená-lo no cache e então retorná-lo.
*   **Suporte a Namespaces (Opcional):**
    *   Permitir a organização de chaves de cache em namespaces para evitar colisões e facilitar a invalidação em grupo.
*   **Operações Atômicas (Opcional, dependendo do backend):**
    *   Suporte para operações como `increment/4` e `decrement/4` para contadores em cache.
    *   Suporte para operações em conjuntos (ex: `add_to_set/3`).
*   **Abstração de Backend de Cache:**
    *   Fornecer uma interface (`CacheBehaviour`) para que diferentes backends de cache (ETS, Redis, etc.) possam ser usados de forma intercambiável.
*   **Métricas e Observabilidade:**
    *   Registrar métricas como taxa de acerto (hit rate), taxa de erro (miss rate), tamanho do cache, latência das operações de cache.
*   **Limpeza de Entradas Expiradas (para backends que não fazem isso automaticamente):**
    *   Implementar ou configurar um mecanismo para remover periodicamente entradas expiradas para liberar memória (especialmente para caches em memória como ETS).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Core.Cache` (Fachada Pública):**
    *   Ponto de entrada para todas as operações de cache.
    *   Delega chamadas para o `DeeperHub.Shared.Cache.CacheAdapter` configurado.
2.  **`DeeperHub.Shared.Cache.CacheAdapter` (GenServer):**
    *   **Responsabilidade:** Gerencia a lógica de interação com a implementação de cache escolhida.
    *   **Interações:** Recebe chamadas da fachada e as traduz para operações no backend de cache (ex: `EtsCache`).
    *   Pode lidar com a lógica de serialização/desserialização se o backend de cache exigir.
3.  **`DeeperHub.Shared.Cache.CacheBehaviour` (Behaviour):**
    *   Define a interface que todas as implementações de backend de cache devem seguir.
4.  **Implementações de Backend de Cache (Exemplos):**
    *   **`DeeperHub.Shared.Cache.Implementations.EtsCache` (GenServer ou módulo funcional usando ETS):**
        *   Implementação de cache em memória usando tabelas ETS.
        *   Gerencia TTLs e limpeza de entradas expiradas.
    *   **`DeeperHub.Shared.Cache.Implementations.RedisAdapter` (Módulo):**
        *   Adaptador para interagir com um servidor Redis externo (usando uma biblioteca como `Redix`).
    *   **`DeeperHub.Shared.Cache.Implementations.NoOpCache` (Módulo Funcional):**
        *   Uma implementação que não faz nada, efetivamente desabilitando o cache. Útil para desenvolvimento ou testes.
5.  **`DeeperHub.Shared.Cache.MetricsReporter` (GenServer):**
    *   Coleta e armazena métricas sobre o desempenho do cache.
6.  **`DeeperHub.Shared.Cache.Supervisor`:**
    *   Supervisiona os processos relacionados ao cache (ex: `CacheAdapter`, `EtsCache GenServer`, `MetricsReporter`).
7.  **Configurações (via `DeeperHub.Core.ConfigManager`):**
    *   Qual adaptador de cache usar, TTL padrão, configurações específicas do backend (ex: URL do Redis).

### 3.2. Estrutura de Diretórios (Proposta para `Shared.Cache`)

```
lib/deeper_hub/shared/cache/
├── cache_adapter.ex                # GenServer que delega para a implementação
├── cache_behaviour.ex              # Behaviour para implementações de cache
│
├── implementations/                # Ou apenas no mesmo nível se forem poucos
│   ├── ets_cache.ex                # Implementação com ETS (pode ser GenServer)
│   ├── redis_adapter.ex            # Adaptador para Redis
│   └── no_op_cache.ex              # Cache que não faz nada
│
├── metrics_reporter.ex             # GenServer para coletar métricas de cache
├── supervisor.ex                   # Supervisor para os GenServers do cache
└── telemetry.ex                    # Para emitir eventos de telemetria do cache
```
E a fachada em:
```
lib/deeper_hub/core/cache.ex        # Fachada Pública
```

### 3.3. Decisões de Design Importantes

*   **Abstração de Backend:** A capacidade de trocar o backend de cache (ex: de ETS para Redis) sem alterar o código da aplicação é uma grande vantagem.
*   **Consistência de Chaves:** Definir uma estratégia clara para nomeação de chaves de cache, incluindo namespaces, para evitar colisões.
*   **Estratégias de Invalidação:** Além do TTL, considerar estratégias de invalidação baseadas em eventos (ex: quando um dado no DB é atualizado, invalidar a entrada de cache correspondente).
*   **Tratamento de Falhas no Cache:** Falhas no serviço de cache não devem impedir o funcionamento da aplicação. O sistema deve ser capaz de operar (com degradação de performance) se o cache estiver indisponível, buscando os dados da fonte primária.

## 🛠️ 4. Casos de Uso Principais

*   **Caching de Dados de Usuário Frequentemente Acessados:**
    *   Ao buscar o perfil de um usuário, o `DeeperHub.Accounts.ProfileService` primeiro verifica o cache: `Cache.get(\"user_profile:#{user_id}\")`.
    *   Se for um \"miss\", busca no DB, e depois armazena no cache: `Cache.put(\"user_profile:#{user_id}\", profile_data, ttl: 3600)`.
*   **Caching de Resultados de Consultas Complexas:**
    *   Um serviço que gera um relatório custoso pode usar `Cache.get_or_store(\"reports:monthly_sales:#{month}\", fn -> generate_sales_report(month) end, ttl: 86400)`.
*   **Contadores em Cache:**
    *   Rastrear o número de visualizações de um post: `Cache.increment(\"post_views:#{post_id}\")`.
*   **Invalidação de Cache Baseada em Eventos:**
    *   O `DeeperHub.Accounts.ProfileService`, ao atualizar um perfil, publica um evento `profile_updated`.
    *   Um assinante desse evento (poderia ser o próprio `ProfileService` ou um worker dedicado) chama `Cache.delete(\"user_profile:#{updated_user_id}\")`.

## 🌊 5. Fluxos Importantes

### Fluxo de `get_or_store/4`

1.  **Chamador:** Um serviço chama `DeeperHub.Core.Cache.get_or_store(key, generator_fun, opts)`.
    *   `opts` pode conter `:ttl_seconds` e `:namespace`.
2.  **`Core.Cache` (Fachada):** Delega para `Shared.Cache.CacheAdapter.get_or_store(...)`.
3.  **`Shared.Cache.CacheAdapter`:**
    *   Chama `get(key, opts_com_namespace)` na implementação de backend configurada (ex: `EtsCache`).
4.  **Backend de Cache (ex: `EtsCache`):**
    *   Verifica se a `key` existe e não está expirada.
    *   **Cache Hit:** Se sim, retorna `{:ok, cached_value}` para o `CacheAdapter`.
    *   **Cache Miss:** Se não, retorna `{:error, :not_found}` para o `CacheAdapter`.
5.  **`Shared.Cache.CacheAdapter`:**
    *   **Se Cache Hit:** Retorna o `cached_value` para a fachada, que retorna para o chamador.
    *   **Se Cache Miss:**
        *   Executa a `generator_fun.()`.
        *   Se a função retornar `{:ok, new_value}`:
            *   Chama `put(key, new_value, opts_com_ttl_e_namespace)` na implementação de backend.
            *   Retorna `new_value` para a fachada.
        *   Se a função retornar `{:error, reason}`:
            *   Loga o erro.
            *   Retorna `{:error, reason}` para a fachada (e não armazena no cache).
6.  **`Core.Cache` (Fachada):** Retorna o valor (do cache ou gerado) ou o erro para o chamador.

## 📡 6. API (Funções Públicas da Fachada `DeeperHub.Core.Cache`)

*(Baseado na API do `DeeperHub.Shared.Cache.CacheService` e `CacheAdapter` da documentação original, consolidando e usando TTLs em segundos para consistência).*

### 6.1. `DeeperHub.Core.Cache.get(key :: String.t() | atom(), default_value :: term() | nil, opts :: keyword()) :: {:ok, term()} | {:error, :not_found | term()}`

*   **Descrição:** Recupera um valor do cache.
*   **`opts`:**
    *   `:namespace` (atom | String.t): Namespace opcional para a chave.
*   **Retorno:** `{:ok, value}` se encontrado e não expirado, `{:ok, default_value}` se não encontrado e default fornecido, senão `{:error, :not_found}`.

### 6.2. `DeeperHub.Core.Cache.put(key :: String.t() | atom(), value :: term(), opts :: keyword()) :: :ok | {:error, term()}`

*   **Descrição:** Armazena um valor no cache.
*   **`opts`:**
    *   `:ttl_seconds` (integer | `:infinity`): Tempo de vida em segundos. (Padrão: config global `cache.default_ttl_seconds`)
    *   `:namespace` (atom | String.t): Namespace opcional.

### 6.3. `DeeperHub.Core.Cache.delete(key :: String.t() | atom(), opts :: keyword()) :: :ok | {:error, term()}`

*   **Descrição:** Remove uma entrada do cache.
*   **`opts`:** `:namespace`.

### 6.4. `DeeperHub.Core.Cache.get_or_store(key :: String.t() | atom(), generator_fun :: (() -> {:ok, term()} | {:error, term()}), opts :: keyword()) :: {:ok, term()} | {:error, term()}`

*   **Descrição:** Obtém do cache ou executa `generator_fun`, armazena e retorna o resultado.
*   **`opts`:** `:ttl_seconds`, `:namespace`.
*   **Retorno:** `{:ok, value}` ou `{:error, reason_from_generator_or_cache_error}`.

### 6.5. `DeeperHub.Core.Cache.increment(key :: String.t() | atom(), amount :: integer() | nil, opts :: keyword()) :: {:ok, new_value :: integer()} | {:error, term()}`

*   **Descrição:** Incrementa atomicamente um valor numérico no cache. Se a chave não existir, geralmente é inicializada com `amount`.
*   **`amount`:** (Padrão: `1`)
*   **`opts`:** `:ttl_seconds`, `:namespace`.

### 6.6. `DeeperHub.Core.Cache.decrement(key :: String.t() | atom(), amount :: integer() | nil, opts :: keyword()) :: {:ok, new_value :: integer()} | {:error, term()}`

*   **Descrição:** Decrementa atomicamente um valor numérico.
*   *(Parâmetros e retorno similares a `increment/4`)*

### 6.7. `DeeperHub.Core.Cache.clear(opts :: keyword()) :: :ok | {:error, term()}`

*   **Descrição:** Limpa o cache.
*   **`opts`:** `:namespace` (para limpar apenas um namespace).

### 6.8. `DeeperHub.Core.Cache.delete_pattern(key_pattern :: String.t(), opts :: keyword()) :: {:ok, count_deleted :: integer()} | {:error, term()}`

*   **Descrição:** Remove entradas do cache que correspondem a um padrão de chave (ex: `\"user_profiles:*\"`, a sintaxe do padrão depende do backend).
*   **`opts`:** `:namespace`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager`:

*   **`[:core, :cache, :enabled]`** (Boolean): Habilita/desabilita o sistema de cache globalmente. (Padrão: `true`)
*   **`[:core, :cache, :default_adapter]`** (Module): Módulo adaptador de cache padrão a ser usado (ex: `DeeperHub.Shared.Cache.Implementations.EtsCache`, `DeeperHub.Shared.Cache.Implementations.RedisAdapter`).
*   **`[:core, :cache, :default_ttl_seconds]`** (Integer): TTL padrão em segundos para novas entradas de cache se não especificado. (Padrão: `3600` - 1 hora)
*   **`[:core, :cache, :ets_cache, :cleanup_interval_ms]`** (Integer): Intervalo para limpeza de entradas expiradas no `EtsCache`. (Padrão: `60000`)
*   **`[:core, :cache, :redis_adapter, :url]`** (String): URL de conexão para o Redis, se usado.
*   **`[:core, :cache, :redis_adapter, :pool_size]`** (Integer): Tamanho do pool de conexões Redis.
*   **`[:core, :cache, :metrics_reporter, :report_interval_ms]`** (Integer): Intervalo para o `MetricsReporter` coletar/logar estatísticas do cache.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter configurações do cache.
*   `DeeperHub.Core.Logger`: Para logging de operações e erros do cache.
*   `DeeperHub.Core.Metrics`: Para registrar métricas de desempenho do cache.
*   `DeeperHub.Core.Supervisor` (indireta): Para supervisionar os processos do `Shared.Cache`.

### 8.2. Bibliotecas Externas

*   Depende da implementação do backend:
    *   Nenhuma para ETS (nativo).
    *   `Redix` (ou similar) se `RedisAdapter` for usado.
    *   Outras bibliotecas cliente para outros backends (Memcached, etc.).

## 🤝 9. Como Usar / Integração

Qualquer módulo que precise de caching pode usar a fachada `DeeperHub.Core.Cache`.

```elixir
defmodule MyApp.UserProfileService do
  alias DeeperHub.Core.Cache
  alias DeeperHub.Core.Repo
  alias MyApp.User

  def get_user_profile(user_id) do
    cache_key = \"user_profile:#{user_id}\"
    
    Cache.get_or_store(cache_key, fn ->
      case Repo.get(User, user_id) do
        nil -> {:error, :not_found} # Não armazena :not_found no cache por padrão
        user -> {:ok, Map.from_struct(user)} # Armazena o mapa
      end
    end, ttl_seconds: 1800) # Cache por 30 minutos
  end

  def update_user_profile(user, attrs) do
    # ... lógica de atualização ...
    case Repo.update(changeset) do
      {:ok, updated_user} ->
        Cache.delete(\"user_profile:#{updated_user.id}\") # Invalida o cache
        {:ok, updated_user}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada função da API do cache (`get`, `put`, `delete`, `get_or_store`, `increment`).
*   Testar a lógica de TTL e expiração.
*   Testar a invalidação por chave e por padrão.
*   Testar o comportamento com diferentes adaptadores de backend (mockeados ou reais em ambiente de teste).
*   Testar o tratamento de falhas do backend de cache (o cache não deve quebrar a aplicação).
*   Localização: `test/deeper_hub/core/cache/` e `test/deeper_hub/shared/cache/`.

### 10.2. Métricas (via `Shared.Cache.MetricsReporter` ou `Core.Metrics`)

*   `deeper_hub.core.cache.operations.count` (tags: `operation` (`get`, `put`, `delete`), `namespace`, `status` (`hit`, `miss`, `success`, `error`))
*   `deeper_hub.core.cache.operation.duration_ms` (Histograma, tags: `operation`, `namespace`)
*   `deeper_hub.core.cache.size.items.gauge` (Gauge, tags: `namespace`): Número de itens no cache.
*   `deeper_hub.core.cache.size.bytes.gauge` (Gauge, tags: `namespace`, opcional): Tamanho estimado em bytes.
*   `deeper_hub.core.cache.hit_ratio.gauge` (Gauge, tags: `namespace`): Taxa de acerto (hits / (hits + misses)).
*   `deeper_hub.core.cache.evictions.count` (Contador, tags: `namespace`, `reason` (`ttl`, `manual`, `lru`)): Número de itens removidos.

### 10.3. Logs

*   **Nível DEBUG:** Detalhes de operações de cache (get, put, delete) com chaves e namespaces.
*   **Nível INFO:** Limpeza de cache iniciada/concluída. Inicialização do adaptador de cache.
*   **Nível WARNING:** Alta taxa de \"cache miss\". Cache se aproximando da capacidade máxima (se aplicável).
*   **Nível ERROR:** Falha ao conectar ao backend de cache (ex: Redis). Erros persistentes em operações de cache.

### 10.4. Telemetria (via `Shared.Cache.Telemetry`)

*   `[:deeper_hub, :core, :cache, :operation, :start | :stop | :exception]`
    *   Metadados: `%{operation: :get | :put | :delete, key: key, namespace: ns, backend_adapter: adapter}`
    *   No `:stop`: `%{result: :hit | :miss | :success, value_size: bytes_if_applicable}`
*   `[:deeper_hub, :core, :cache, :cleanup, :start | :stop]`
    *   Medições: `%{items_removed: count}`

## ❌ 11. Tratamento de Erros

*   **Cache Indisponível:** Se o backend de cache (ex: Redis) estiver offline, as operações de cache devem falhar graciosamente. `get_or_store` deve executar a função geradora e retornar seu resultado diretamente, sem tentar armazenar. `put` e `delete` podem simplesmente logar o erro e retornar `:ok` (ou um erro não bloqueante) para não quebrar o fluxo da aplicação.
*   **Erro de Serialização:** Se os dados não puderem ser serializados para o cache, um erro deve ser logado e a operação de cache deve falhar.

## 🛡️ 12. Considerações de Segurança

*   **Não Armazenar Dados Extremamente Sensíveis em Cache (a menos que o cache seja seguro):** Se o backend de cache não for tão seguro quanto o banco de dados primário (ex: Redis sem criptografia em trânsito/repouso vs. DB com TDE), evite cachear dados altamente sensíveis.
*   **Cache Poisoning:** Embora menos comum para caches de servidor, esteja ciente da possibilidade se as chaves de cache puderem ser influenciadas diretamente por entradas de usuário não sanitizadas. Use chaves bem definidas e prefixadas.
*   **Segurança do Backend de Cache:** Se usar Redis/Memcached, proteja o acesso a esses servidores (firewall, autenticação).

## 🧑‍💻 13. Contribuição

*   Use chaves de cache consistentes e com namespaces para evitar colisões.
*   Defina TTLs apropriados para os dados cacheados. Dados que mudam raramente podem ter TTLs longos; dados voláteis, TTLs curtos ou invalidação baseada em eventos.
*   Considere o tamanho dos dados armazenados em cache para não esgotar a memória (especialmente com ETS).

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar \"cache stampede protection\" (ou \"dog-piling effect\" prevention) para `get_or_store`, onde apenas um processo regenera um item de cache expirado enquanto outros esperam ou recebem o valor antigo por um curto período.
*   [ ] Adicionar suporte para diferentes estratégias de remoção (eviction policies) no `EtsCache` (ex: LRU, LFU) se ele se tornar muito grande.
*   [ ] Desenvolver um `CacheWarmer` que possa pré-carregar dados importantes no cache durante a inicialização da aplicação.
*   [ ] Suporte para cache em camadas (ex: ETS local como L1, Redis como L2).
*   [ ] Interface administrativa para visualizar o conteúdo do cache, estatísticas e invalidar entradas manualmente.

---

*Última atualização: 2025-05-12*

---

Caching é fundamental para aplicações de alta performance.

O próximo módulo? Talvez `DeeperHub.Core.Repo` para fechar a parte de infraestrutura básica, ou podemos voltar para algum módulo de segurança como `DDoSProtection`?"""),
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
                types.Part.from_text(text="""Perfeito! Vamos então ao `DeeperHub.Core.Repo`, o coração da persistência de dados no sistema.

---

