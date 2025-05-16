# Módulo: `Deeper_Hub.Core.Repo` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Core.Repo`

O módulo `Deeper_Hub.Core.Repo` é a **implementação principal do Ecto.Repo** para o sistema Deeper_Hub. Ele serve como a interface de banco de dados para toda a aplicação, gerenciando conexões, transações e a execução de consultas Ecto.

Através deste módulo, todos os outros componentes do sistema interagem com o banco de dados (ou bancos de dados, se houver múltiplos repositórios configurados para diferentes propósitos) de forma consistente e segura. Ele encapsula a configuração do adaptador de banco de dados (PostgreSQL, MySQL, etc.) e fornece as funcionalidades padrão do Ecto para CRUD (Create, Read, Update, Delete) e consultas complexas. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Interface Ecto.Repo Padrão:**
    *   Implementar o comportamento `Ecto.Repo`.
    *   Fornecer todas as funções padrão do Ecto: `insert/2`, `update/2`, `delete/2`, `get/3`, `get_by/3`, `all/2`, `one/2`, `transaction/2`, `preload/3`, etc.
*   **Gerenciamento de Conexão com Banco de Dados:**
    *   Configurar e gerenciar o pool de conexões com o(s) banco(s) de dados.
    *   Lidar com reconexões e falhas de conexão.
*   **Execução de Consultas Ecto:**
    *   Executar Ecto queries construídas com `Ecto.Query`.
    *   Converter resultados do banco de dados em structs Ecto.
*   **Gerenciamento de Transações:**
    *   Fornecer a capacidade de executar múltiplas operações de banco de dados dentro de uma única transação atômica (`transaction/2`).
    *   Garantir rollback em caso de erro dentro da transação.
*   **Suporte a Migrações Ecto:**
    *   Ser o repositório usado para executar migrações de schema do banco de dados.
*   **Configuração do Adaptador de Banco de Dados:**
    *   Carregar a configuração do adaptador de banco de dados (PostgreSQL, MySQL, SQLite, etc.) a partir das configurações da aplicação.
*   **Observabilidade (via Ecto.LogEntry e Telemetria):**
    *   Ecto já emite eventos de telemetria para consultas (`[:my_app, :repo, :query]`). `Deeper_Hub.Core.Metrics` e `Deeper_Hub.Core.Logger` devem ter handlers para capturar esses eventos e registrar métricas de DB (latência, contagem de queries) e logs de queries (especialmente em dev ou para queries lentas).
*   **Suporte a Múltiplos Repositórios (Opcional, se necessário):**
    *   Se a aplicação usar múltiplos bancos de dados para diferentes propósitos, pode haver múltiplos módulos Repo (ex: `Core.Repo.Primary`, `Core.Repo.Analytics`). Este README focará no principal.
*   **Integração com `QueryHelper` e `QueryOptimizer` (Opcional):**
    *   As funções de serviço que usam o `Repo` podem utilizar os utilitários `Deeper_Hub.Shared.Database.QueryHelper` para aplicar filtros, paginação e ordenação de forma consistente, e `QueryOptimizer` para caching de queries.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Core.Repo` (Módulo Ecto.Repo):**
    *   **Responsabilidade:** É a própria implementação do repositório.
    *   **Configuração:** `use Ecto.Repo, otp_app: :deeper_hub, adapter: Ecto.Adapters.Postgres` (ou outro adaptador).
    *   A configuração detalhada (hostname, username, password, database, pool_size) é geralmente carregada de `config/config.exs`, `config/runtime.exs` ou variáveis de ambiente.
2.  **Adaptador de Banco de Dados Ecto (ex: `Ecto.Adapters.Postgres`):**
    *   Biblioteca externa que lida com a comunicação específica do banco de dados.
3.  **Pool de Conexões (ex: `DBConnection` ou `Postgrex` pool):**
    *   Gerenciado pelo Ecto/adaptador para reutilizar conexões de banco de dados eficientemente.
4.  **Schemas Ecto (Definidos nos módulos de domínio):**
    *   Ex: `Deeper_Hub.Accounts.Schema.User`, `Deeper_Hub.Servers.Schema.Server`.
    *   São usados pelo `Repo` para mapear dados de/para o banco de dados.
5.  **`Deeper_Hub.Release` (ou `application.ex`):**
    *   Responsável por garantir que o `Repo` seja iniciado como parte da árvore de supervisão da aplicação e que as migrações sejam executadas durante o deploy.

### 3.2. Estrutura de Diretórios (Proposta)

```
core/repo.ex          # Implementação do Ecto.Repo principal

priv/repo/
├── migrations/                     # Migrações Ecto
│   └── 20230101000000_create_users.exs
│   └── ...
└── seeds.exs                       # (Opcional) Script para popular dados iniciais
```

### 3.3. Decisões de Design Importantes

*   **Repositório Único vs. Múltiplos:** Para a maioria das aplicações, um único `Repo` principal é suficiente. Múltiplos repos podem ser usados para conectar a diferentes bancos de dados ou para isolar contextos delimitados muito distintos, mas adicionam complexidade.
*   **Consultas Explícitas:** As funções de serviço devem construir e passar `Ecto.Query` explícitas para o `Repo`, em vez de o `Repo` conter lógica de consulta complexa.
*   **Transações para Múltiplas Gravações:** Qualquer operação que envolva múltiplas escritas no banco de dados que devem ser atômicas (ou seja, todas bem-sucedidas ou todas falham) deve ser encapsulada em uma `Repo.transaction/2`.
*   **Segurança:** Nunca construir fragmentos SQL por concatenação de strings. Sempre usar consultas parametrizadas, que o Ecto faz por padrão quando usado corretamente.

## 🛠️ 4. Casos de Uso Principais

*   **Criar um Novo Usuário:**
    *   `Deeper_Hub.Accounts.UserService` constrói um changeset para um novo usuário.
    *   Chama `Deeper_Hub.Core.Repo.insert(changeset)`.
*   **Buscar um Servidor pelo ID:**
    *   `Deeper_Hub.Servers.Storage` chama `Deeper_Hub.Core.Repo.get(Deeper_Hub.Servers.Schema.Server, server_id)`.
*   **Listar Todas as Avaliações Ativas para um Servidor (com paginação e ordenação):**
    *   `Deeper_Hub.ServerReviews.Storage` constrói uma `Ecto.Query`:
        ```elixir
        from(r in Review,
          where: r.server_id == ^server_id and r.is_active == true,
          order_by: [desc: r.inserted_at],
          limit: ^limit,
          offset: ^offset
        ) |> Deeper_Hub.Core.Repo.all()
        ```
*   **Registrar um Usuário e seu Perfil Atomicamente:**
    *   `Deeper_Hub.Accounts.RegistrationService` usa `Deeper_Hub.Core.Repo.transaction(fn -> ... end)` para garantir que tanto o usuário quanto o perfil sejam criados, ou nenhum deles se ocorrer um erro.

## 🌊 5. Fluxos Importantes

### Fluxo de uma Consulta `Repo.all/2`

1.  **Módulo de Serviço/Storage:** Constrói uma `Ecto.Query.t()` (ex: `query = from(u in User, where: u.active == true)`).
2.  **Chamada ao Repo:** Chama `Deeper_Hub.Core.Repo.all(query)`.
3.  **`Deeper_Hub.Core.Repo`:**
    *   Obtém uma conexão do pool de conexões.
    *   O adaptador Ecto (ex: `Postgrex`) traduz a `Ecto.Query` para uma consulta SQL parametrizada.
    *   Envia a consulta SQL para o servidor de banco de dados.
4.  **Banco de Dados:** Executa a consulta e retorna os resultados.
5.  **`Deeper_Hub.Core.Repo`:**
    *   O adaptador Ecto recebe os resultados brutos.
    *   Converte os resultados em uma lista de structs Ecto (ex: `[%User{}, %User{}, ...]`).
    *   Libera a conexão de volta para o pool.
    *   Retorna a lista de structs para o chamador.
    *   Eventos Telemetry (`[:deeper_hub, :repo, :query]`) são emitidos pelo Ecto.

### Fluxo de uma `Repo.transaction/2`

1.  **Módulo de Serviço:** Chama `Deeper_Hub.Core.Repo.transaction(fn repo_inside_transaction -> ... end)`.
2.  **`Deeper_Hub.Core.Repo`:**
    *   Obtém uma conexão do pool e a marca como estando em uma transação.
    *   Inicia uma transação no banco de dados (ex: `BEGIN`).
    *   Executa a função anônima passada, fornecendo uma instância do `Repo` que opera dentro dessa transação (`repo_inside_transaction`).
3.  **Função Anônima:**
    *   Executa múltiplas operações de banco de dados usando `repo_inside_transaction` (ex: `repo_inside_transaction.insert(cs1)`, `repo_inside_transaction.update(cs2)`).
    *   Se todas as operações forem bem-sucedidas, a função retorna `{:ok, result_value}`.
    *   Se qualquer operação falhar (ex: changeset inválido, erro do DB), a função pode retornar `{:error, reason}` ou o `Repo` pode levantar uma exceção. É comum usar `Repo.insert!/update!/delete!` dentro de transações para que um erro cause um rollback automático.
4.  **`Deeper_Hub.Core.Repo` (Conclusão da Transação):**
    *   Se a função retornou `{:ok, result_value}`:
        *   Confirma a transação no banco de dados (ex: `COMMIT`).
        *   Retorna `{:ok, result_value}` para o chamador original.
    *   Se a função retornou `{:error, reason}` ou levantou uma exceção que o `Repo.transaction` captura:
        *   Cancela a transação no banco de dados (ex: `ROLLBACK`).
        *   Retorna `{:error, reason}` (ou propaga a exceção, dependendo de como a transação foi configurada).
    *   Libera a conexão de volta para o pool.
    *   Eventos Telemetry são emitidos para o início, fim (commit/rollback) da transação.

## 📡 6. API (Funções Ecto.Repo Padrão)

O `Deeper_Hub.Core.Repo` expõe todas as funções padrão do `Ecto.Repo`. As mais comuns incluem:

*   `insert(changeset_or_struct, opts \\\\ [])`
*   `insert!(changeset_or_struct, opts \\\\ [])`
*   `update(changeset_or_struct, opts \\\\ [])`
*   `update!(changeset_or_struct, opts \\\\ [])`
*   `delete(struct, opts \\\\ [])`
*   `delete!(struct, opts \\\\ [])`
*   `get(schema_module, id, opts \\\\ [])`
*   `get!(schema_module, id, opts \\\\ [])`
*   `get_by(schema_module, clauses, opts \\\\ [])`
*   `get_by!(schema_module, clauses, opts \\\\ [])`
*   `all(queryable, opts \\\\ [])`
*   `one(queryable, opts \\\\ [])`
*   `one!(queryable, opts \\\\ [])`
*   `transaction(fun, opts \\\\ [])`
*   `preload(structs_or_struct, preloads, opts \\\\ [])`
*   `exists?(queryable)`
*   `aggregate(queryable, aggregate_op, field, opts \\\\ [])`

*Para a documentação completa de cada função, consulte a documentação oficial do Ecto.*

## ⚙️ 7. Configuração

A configuração do `Deeper_Hub.Core.Repo` é feita principalmente através dos arquivos de configuração do Elixir (`config/config.exs`, `config/dev.exs`, `config/prod.exs`, `config/runtime.exs`) e variáveis de ambiente.

**Exemplo (`config/runtime.exs` para produção):**
```elixir
import Config

if config_env() == :prod do
  database_url =
    System.get_env(\"DATABASE_URL\") ||
      raise \"\"\"
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      \"\"\"

  config :deeper_hub, Deeper_Hub.Core.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env(\"POOL_SIZE\") || \"10\"),
    ssl: String.to_atom(System.get_env(\"DATABASE_SSL\") || \"false\"), # ex: true, ou [certfile: \"path/to/cert.pem\"]
    # Outras opções de produção, como timeouts
    socket_options: maybe_ipv6(System.get_env(\"DATABASE_SOCKET_OPTIONS\"))

  # Helper para socket_options
  defp maybe_ipv6(nil), do: []
  defp maybe_ipv6(\"ipv6\"), do: [:inet6]
  defp maybe_ipv6(_), do: []
end
```

**Configurações Chave:**
*   `:otp_app`: `:deeper_hub` (indica que as configurações do repo estão sob a app `:deeper_hub`).
*   `:adapter`: (ex: `Ecto.Adapters.Postgres`).
*   `:url` ou `:hostname`, `:username`, `:password`, `:database`: Credenciais de conexão.
*   `:pool_size`: Número de conexões no pool.
*   `:ssl`: Configurações de SSL para a conexão.
*   Outras opções específicas do adaptador e do pool.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   Todos os módulos que definem `Ecto.Schema`.
*   Todos os módulos de serviço/storage que executam operações de banco de dados.
*   `Deeper_Hub.Core.ConfigManager`: Para obter a string de conexão e outras configurações do Repo em tempo de execução (se usando `Config.Provider`).

### 8.2. Bibliotecas Externas

*   `Ecto` (especificamente `ecto_sql` para bancos SQL).
*   O adaptador de banco de dados específico (ex: `postgrex` para PostgreSQL, `myxql` para MySQL).
*   `DBConnection`: Para gerenciamento do pool de conexões.

## 🤝 9. Como Usar / Integração

O `Deeper_Hub.Core.Repo` é usado em toda a aplicação onde a persistência de dados é necessária.

**Exemplo em um módulo de serviço:**
```elixir
defmodule Deeper_Hub.Accounts.UserService do
  alias Deeper_Hub.Core.Repo
  alias Deeper_Hub.Accounts.Schema.User
  import Ecto.Query

  def get_user_by_id(user_id) do
    Repo.get(User, user_id) # Retorna %User{} ou nil
  end

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert() # Retorna {:ok, %User{}} ou {:error, %Ecto.Changeset{}}
  end

  def list_active_users() do
    from(u in User, where: u.is_active == true)
    |> Repo.all()
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Os testes para o `Repo` em si são geralmente cobertos pelos testes do Ecto.
*   Os testes dos módulos de serviço/storage que *usam* o `Repo` devem verificar se os dados são persistidos e recuperados corretamente.
*   Usar o `Ecto.Adapters.SQL.Sandbox` para testes de banco de dados é a prática padrão para garantir isolamento e limpeza automática.
*   Localização: Os testes que interagem com o Repo estarão nos diretórios de teste dos módulos que o utilizam (ex: `test/deeper_hub/accounts/user_service_test.exs`).

### 10.2. Métricas

Ecto emite eventos Telemetry que podem ser usados para derivar métricas (via `Deeper_Hub.Core.Metrics` com handlers apropriados):
*   `deeper_hub.core.repo.query.total.count` (tags: `source` (nome da tabela/schema), `action` (`select`, `insert`, `update`, `delete`))
*   `deeper_hub.core.repo.query.duration_ms` (Histograma, tags: `source`, `action`)
*   `deeper_hub.core.repo.query.idle_time_ms` (Histograma): Tempo que uma conexão ficou ociosa antes de ser usada.
*   `deeper_hub.core.repo.query.queue_time_ms` (Histograma): Tempo que uma query esperou por uma conexão disponível.
*   `deeper_hub.core.repo.transaction.duration_ms` (Histograma)
*   `deeper_hub.core.repo.pool.size.gauge` (Gauge): Tamanho atual do pool.
*   `deeper_hub.core.repo.pool.checked_out.gauge` (Gauge): Conexões em uso.
*   `deeper_hub.core.repo.pool.overflow.count` (Contador): Número de vezes que o pool excedeu o tamanho.

### 10.3. Logs

*   Ecto pode ser configurado para logar todas as queries SQL executadas (`log_queries: true` na configuração do Repo, geralmente apenas para desenvolvimento).
*   Queries lentas podem ser logadas com um nível mais alto (ex: WARNING) se um limiar for excedido.
*   Erros de conexão com o banco de dados.
*   Erros de transação (rollbacks).

### 10.4. Telemetria

Ecto emite eventos Telemetry padrão para operações de banco de dados. Os principais são:
*   `[:your_app, :repo, :query]` (onde `:your_app` é `:deeper_hub`):
    *   **Medições:** `:query_time`, `:decode_time`, `:queue_time`, `:idle_time`, `:total_time` (todos em `native` time units).
    *   **Metadados:** `:repo`, `:type` (`:ecto_sql | :ecto_mongodb | ...`), `:source` (nome da tabela/schema), `:action` (`:select | :insert | ...`), `:result` (`{:ok, term} | {:error, term}`), `:query` (a query Ecto), `:params`, `:stacktrace`.
*   Para transações, eventos como `[:your_app, :repo, :transaction]` são emitidos.

## ❌ 11. Tratamento de Erros

*   Funções do `Repo` como `insert`, `update`, `delete` retornam `{:ok, struct}` ou `{:error, changeset}`.
*   Funções \"bang\" (`insert!`, `update!`, `delete!`, `get!`, `one!`) levantam exceções em caso de erro (ex: `Ecto.InvalidChangesetError`, `Ecto.NoResultsError`). Estas são úteis dentro de transações para forçar um rollback.
*   Erros de conexão com o banco de dados podem levantar exceções como `DBConnection.ConnectionError`. A aplicação (ou o pool de conexões) geralmente tenta reconectar.
*   `Repo.transaction` retorna `{:ok, value}` se a função interna retornar `{:ok, value}`, e `{:error, reason}` se a função interna retornar `{:error, reason}` ou `Repo.rollback(reason)`.

## 🛡️ 12. Considerações de Segurança

*   **Prevenção de Injeção de SQL:** A principal responsabilidade de segurança do `Repo` é facilitar o uso de consultas parametrizadas. **Nunca interpolar dados de entrada do usuário diretamente em strings de consulta SQL.** Use `^` para interpolar variáveis em queries Ecto ou passe parâmetros para `Ecto.Adapters.SQL.query/4`.
*   **Credenciais de Acesso:** As credenciais do banco de dados devem ser gerenciadas de forma segura (ex: variáveis de ambiente, cofres de segredos) e não hardcoded.
*   **Permissões do Usuário do Banco de Dados:** O usuário do banco de dados configurado para a aplicação deve ter apenas as permissões necessárias (princípio do menor privilégio).
*   **Dados Sensíveis:** Se o banco de dados armazenar dados sensíveis, considere criptografia em nível de coluna (usando tipos Ecto customizados como `Deeper_Hub.Shared.Encryption.EncryptedType`) ou criptografia em nível de banco de dados (TDE).

## 🧑‍💻 13. Contribuição

*   Mantenha a lógica de consulta complexa fora do módulo `Repo`. Coloque-a em módulos de contexto/serviço.
*   Sempre use changesets para validar dados antes de `insert` ou `update`.
*   Use transações para operações que envolvem múltiplas escritas atômicas.
*   Monitore a performance das queries e adicione índices no banco de dados conforme necessário.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Configurar read replicas e um `Repo.ReadOnly` para desviar tráfego de leitura e aliviar o banco de dados primário, se a carga justificar.
*   [ ] Implementar estratégias de retry mais sofisticadas para operações de banco de dados em caso de deadlocks ou falhas transitórias.
*   [ ] Explorar o uso de `Ecto.Multi` para compor operações de banco de dados mais complexas de forma transacional.
*   [ ] Adicionar uma camada de \"data sharding\" se a aplicação precisar escalar para volumes de dados muito grandes.
*   [ ] Melhorar a observabilidade com tracing distribuído para queries Ecto, ligando-as a traces de requisições HTTP.

---

*Última atualização: 2025-05-12*

---

Com o `Core.Repo` documentado, cobrimos a principal interface de persistência.

Para o próximo, podemos voltar para a camada de segurança e abordar `Deeper_Hub.Security.DataMasking` ou `ResponseSanitizer`, ou talvez começar a detalhar um módulo de domínio como `Deeper_Hub.Servers`?"""),
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
                types.Part.from_text(text="""Ok, vamos seguir com `Deeper_Hub.Security.DataMasking`. Este módulo é crucial para proteger dados sensíveis quando eles precisam ser exibidos ou logados.

---

