# Guia para Criação de Novos Módulos no DeeperHub

## 1. Introdução

Este documento descreve o processo e as melhores práticas para criar novos módulos funcionais completos no sistema DeeperHub. O objetivo é garantir que todos os novos módulos sejam consistentes, robustos, bem estruturados e prontos para produção, seguindo as diretrizes estabelecidas no `system_prompt.md` e nas configurações globais do projeto.

Um "módulo funcional" completo geralmente envolve as seguintes camadas:

-   **Schema de Dados**: Definição da estrutura dos dados (usando `defstruct` para representação interna).
-   **Migração de Banco de Dados**: Para criar ou alterar tabelas no banco de dados (usando Ecto Migrations).
-   **Módulo de Dados/Repositório**: Funções para interagir com o banco de dados, utilizando `DeeperHub.Core.Data.Crud` para operações comuns ou `DeeperHub.Core.Data.Repo` para queries customizadas.
-   **Módulo de Serviço**: Contém a lógica de negócios, validações e orquestra as chamadas para a camada de dados.
-   **Módulo de Recurso (Web Interface)**: Expõe a funcionalidade através de uma API REST, utilizando `Plug.Router`.
-   **Definição de Rotas**: No roteador principal (`lib/deeper_hub/web_interface/router.ex`) para encaminhar requisições ao módulo de recurso apropriado.

## 2. Estrutura de Diretórios e Nomenclatura

Siga rigorosamente a estrutura de diretórios e as convenções de nomenclatura definidas no `system_prompt.md` e nas diretrizes globais (`MEMORY[user_global]`):

-   **Schemas**: `lib/deeper_hub/data/schemas/nome_do_schema.ex` (Módulo: `DeeperHub.Data.Schemas.NomeDoSchema`)
-   **Migrações**: `priv/repo/migrations/timestamp_create_nome_da_tabela.exs`
-   **Módulos de Dados (Repositórios específicos da entidade)**: `lib/deeper_hub/data/nome_da_entidade/nome_da_entidade_repo.ex` (Módulo: `DeeperHub.Data.NomeDaEntidade.Repo`)
    -   Alternativamente, se for um repositório mais genérico, pode seguir `lib/deeper_hub/data/repos/`. A estrutura por entidade é preferível para maior organização.
-   **Módulos de Serviço**: `lib/deeper_hub/services/nome_do_servico/nome_da_entidade_service.ex` (Módulo: `DeeperHub.Services.NomeDoServico.NomeDaEntidadeService`)
-   **Módulos de Recurso**: `lib/deeper_hub/web_interface/resources/nome_do_recurso_resource.ex` (Módulo: `DeeperHub.WebInterface.Resources.NomeDoRecursoResource`)
-   **Nomes de Módulos**: `PascalCase` (ex: `DeeperHub.Services.UserService`)
-   **Nomes de Arquivos**: `snake_case` (ex: `user_service.ex`)
-   **Nomes de Funções e Variáveis**: `snake_case` (ex: `get_user_by_id/1`)

## 3. Passo a Passo para Criar um Novo Módulo Funcional

Vamos usar o exemplo da criação de um módulo para gerenciar "Tarefas" (`Task`).

### Passo 1: Definindo o Schema da Entidade

Mesmo que `DeeperHub.Core.Data.Crud` opere com mapas, definir um `defstruct` para suas entidades ajuda a ter código mais claro e seguro nos módulos de serviço e outras camadas.

**Localização**: `lib/deeper_hub/data/schemas/task.ex`
```elixir
# lib/deeper_hub/data/schemas/task.ex
defmodule DeeperHub.Data.Schemas.Task do
  @moduledoc """
  Define a estrutura de uma Tarefa.
  """
  defstruct [
    id: nil,
    title: nil,
    description: nil,
    status: :pending, # :pending, :in_progress, :completed
    due_date: nil,
    assignee_id: nil,
    inserted_at: nil,
    updated_at: nil
  ]

  @type t :: %__MODULE__{
          id: String.t() | integer() | nil,
          title: String.t() | nil,
          description: String.t() | nil,
          status: :pending | :in_progress | :completed,
          due_date: Date.t() | nil,
          assignee_id: String.t() | integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
```

### Passo 2: Criando a Migração do Banco de Dados

Use o gerador de migrações do Ecto (assumindo que Ecto está configurado para migrações).

1.  **Gerar a migração**:
    ```bash
    mix ecto.gen.migration create_tasks_table
    ```

2.  **Editar o arquivo de migração gerado** (ex: `priv/repo/migrations/YYYYMMDDHHMMSS_create_tasks_table.exs`):
    ```elixir
    defmodule DeeperHub.Repo.Migrations.CreateTasksTable do
      use Ecto.Migration

      def change do
        create table(:tasks, primary_key: false) do
          add :id, :uuid, primary_key: true
          add :title, :string, null: false
          add :description, :text
          add :status, :string, default: "pending", null: false
          add :due_date, :date
          add :assignee_id, :uuid # Ou :references(:users, type: :uuid) se houver tabela de usuários

          timestamps()
        end

        create index(:tasks, [:status])
        create index(:tasks, [:assignee_id])
      end
    end
    ```

3.  **Executar a migração**:
    ```bash
    mix ecto.migrate
    ```

### Passo 3: Módulo de Dados (TaskRepo)

Este módulo encapsula a lógica de acesso a dados para Tarefas.

**Localização**: `lib/deeper_hub/data/task/task_repo.ex`
```elixir
# lib/deeper_hub/data/task/task_repo.ex
defmodule DeeperHub.Data.Task.Repo do
  @moduledoc """
  Módulo de repositório para operações de dados da entidade Task.
  """

  alias DeeperHub.Core.Data.Crud
  alias DeeperHub.Core.Data.Repo, as CoreRepo # Para queries complexas
  alias DeeperHub.Data.Schemas.Task

  @table_name "tasks"

  @doc """
  Cria uma nova tarefa.
  Espera um mapa de atributos.
  """
  @spec create_task(map()) :: {:ok, map()} | {:error, any()}
  def create_task(attrs) do
    # O Crud.ex espera e retorna mapas. A conversão para struct Task pode ser feita no serviço.
    # Adicionar timestamps se não existirem
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    attrs_with_timestamps = 
      attrs
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)
      # Garantir que o ID seja gerado se não fornecido (UUID)
      |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)

    Crud.create(@table_name, attrs_with_timestamps)
  end

  @doc """
  Busca uma tarefa pelo ID.
  """
  @spec get_task_by_id(String.t() | integer()) :: {:ok, map() | nil} | {:error, any()}
  def get_task_by_id(id) do
    Crud.get_by_id(@table_name, id)
  end

  @doc """
  Lista todas as tarefas (com paginação básica opcional).
  """
  @spec list_tasks(keyword()) :: {:ok, list(map())} | {:error, any()}
  def list_tasks(opts \ []) do
    # O Crud.list/2 atual é muito básico. Para filtros, ordenação, paginação, usar CoreRepo.query
    # Exemplo simples usando Crud.list/1 (que não existe, mas ilustra a ideia)
    # Crud.list(@table_name, opts)
    # Exemplo real com CoreRepo para mais controle:
    query = "SELECT * FROM #{@table_name} ORDER BY inserted_at DESC LIMIT $1 OFFSET $2"
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    CoreRepo.query(query, [limit, offset])
  end

  @doc """
  Atualiza uma tarefa.
  Espera o ID e um mapa de atributos para atualizar.
  """
  @spec update_task(String.t() | integer(), map()) :: {:ok, map()} | {:error, any()}
  def update_task(id, attrs) do
    attrs_with_timestamp = Map.put(attrs, :updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
    Crud.update(@table_name, id, attrs_with_timestamp)
  end

  @doc """
  Deleta uma tarefa pelo ID.
  """
  @spec delete_task(String.t() | integer()) :: {:ok, map()} | {:error, any()} | {:ok, nil}
  def delete_task(id) do
    Crud.delete(@table_name, id)
  end
end
```

### Passo 4: Módulo de Serviço (TaskService)

Contém a lógica de negócios para Tarefas.

**Localização**: `lib/deeper_hub/services/task_management/task_service.ex`
```elixir
# lib/deeper_hub/services/task_management/task_service.ex
defmodule DeeperHub.Services.TaskManagement.TaskService do
  @moduledoc """
  Serviço para gerenciar a lógica de negócios de Tarefas.
  """

  alias DeeperHub.Data.Task.Repo, as TaskRepo
  alias DeeperHub.Data.Schemas.Task

  @doc """
  Cria uma nova tarefa.
  Recebe um mapa de atributos, valida e passa para o repositório.
  Retorna um struct Task.t() em caso de sucesso.
  """
  @spec create_task(map()) :: {:ok, Task.t()} | {:error, atom() | list()}
  def create_task(params) do
    # Aqui podem entrar validações (ex: usando Vex ou customizadas)
    # Exemplo de validação simples:
    with {:ok, valid_params} <- validate_task_params(params) do
      case TaskRepo.create_task(valid_params) do
        {:ok, task_map} -> {:ok, struct!(Task, task_map)}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, errors} -> {:error, errors}
    end
  end

  @doc """
  Busca uma tarefa pelo ID.
  Retorna um struct Task.t() ou nil em caso de sucesso.
  """
  @spec get_task(String.t() | integer()) :: {:ok, Task.t() | nil} | {:error, any()}
  def get_task(id) do
    case TaskRepo.get_task_by_id(id) do
      {:ok, nil} -> {:ok, nil}
      {:ok, task_map} -> {:ok, struct!(Task, task_map)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lista tarefas.
  Retorna uma lista de structs Task.t().
  """
  @spec list_tasks(keyword()) :: {:ok, list(Task.t())} | {:error, any()}
  def list_tasks(opts \ []) do
    case TaskRepo.list_tasks(opts) do
      {:ok, tasks_maps} -> 
        tasks_structs = Enum.map(tasks_maps, &struct!(Task, &1))
        {:ok, tasks_structs}
      {:error, reason} -> {:error, reason}
    end
  end

  # Função de validação privada (exemplo)
  defp validate_task_params(params) do
    required_fields = [:title]
    missing_fields = Enum.reject(required_fields, &Map.has_key?(params, &1))

    if Enum.empty?(missing_fields) do
      # Adicionar mais validações aqui (tipo, formato, etc.)
      {:ok, params}
    else
      {:error, [validation: "Campos obrigatórios ausentes: #{inspect(missing_fields)}"]}
    end
  end
  
  # Implementar update_task/2 e delete_task/1 de forma similar, 
  # convertendo para/de structs Task.t() e mapas conforme necessário.
end
```

### Passo 5: Módulo de Recurso (TaskResource)

Expõe as operações de Tarefa via API REST.

**Localização**: `lib/deeper_hub/web_interface/resources/task_resource.ex`
```elixir
# lib/deeper_hub/web_interface/resources/task_resource.ex
defmodule DeeperHub.WebInterface.Resources.TaskResource do
  @moduledoc """
  Recurso Plug para gerenciar Tarefas via API.
  """
  use Plug.Router
  alias DeeperHub.Services.TaskManagement.TaskService

  plug(:match)
  plug(:dispatch)

  # POST /api/tasks (ou o caminho base definido no router.ex)
  post "/" do
    # Plug.Parsers já deve ter populado conn.body_params
    case TaskService.create_task(conn.body_params) do
      {:ok, task} ->
        conn
        |> put_resp_header("location", "/api/tasks/#{task.id}") # Ajustar caminho conforme necessário
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{data: task}))
      {:error, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{errors: errors})) # Unprocessable Entity
    end
  end

  # GET /api/tasks/:id
  get "/:id" do
    task_id = conn.params["id"]
    case TaskService.get_task(task_id) do
      {:ok, nil} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{error: "Tarefa não encontrada"}))
      {:ok, task} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: task}))
      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "Erro interno ao buscar tarefa"}))
    end
  end

  # GET /api/tasks
  get "/" do
    # Adicionar suporte a query params para paginação, filtros, etc.
    # Ex: opts = conn.query_params |> Map.to_list() |> Keyword.new()
    case TaskService.list_tasks() do
      {:ok, tasks} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: tasks}))
      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "Erro interno ao listar tarefas"}))
    end
  end

  # Implementar PUT /:id, DELETE /:id de forma similar.

  # Fallback para rotas não encontradas dentro deste recurso
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{erro: "Ação não encontrada para este recurso"}))
  end
end
```

### Passo 6: Adicionando Rotas no Router Principal

Edite `lib/deeper_hub/web_interface/router.ex` para encaminhar um caminho base para o novo `TaskResource`.

```elixir
# Em lib/deeper_hub/web_interface/router.ex

defmodule DeeperHub.WebInterface.Router do
  # ... (outro código do router)

  # API Routes
  forward("/api/status", to: DeeperHub.WebInterface.Resources.StatusResource)
  forward("/api/info", to: DeeperHub.WebInterface.Resources.ServerInfoResource)
  forward("/api/routes", to: DeeperHub.WebInterface.Resources.RoutesResource)

  forward("/api/terminal", to: DeeperHub.WebInterface.Resources.TerminalResource)
  forward("/api/console", to: DeeperHub.WebInterface.Resources.ConsoleResource)

  # Nova rota para Tarefas
  forward("/api/tasks", to: DeeperHub.WebInterface.Resources.TaskResource)

  # ... (resto do código do router)
end
```

## 4. Melhores Práticas e Considerações Adicionais

-   **Documentação**: Adicione `@moduledoc` a todos os módulos e `@doc` com `@spec` a todas as funções públicas. Inclua exemplos se possível.
-   **Testes**: Escreva testes unitários para os módulos de serviço e de dados. Escreva testes de integração (ou de controller/recurso) para a camada web.
-   **Tratamento de Erros**: Use o padrão `{:ok, resultado}` e `{:error, razao}` consistentemente. Forneça mensagens de erro claras e úteis na API.
-   **Validações**: Implemente validações robustas nos módulos de serviço. Considere usar bibliotecas como `Vex` para validações complexas se necessário.
-   **Segurança**: Pense em autenticação e autorização. Embora não coberto neste guia, é crucial para APIs de produção. As rotas podem precisar de plugs de autenticação.
-   **Logging**: Utilize `DeeperHub.Core.Logger` para registrar informações importantes, especialmente em pontos de decisão ou erro.
-   **Conformidade com Diretrizes**: Sempre consulte o `system_prompt.md` e `MEMORY[user_global]` para as diretrizes gerais do projeto.
-   **Limite de Linhas**: Mantenha os arquivos concisos e bem focados. Refatore módulos ou funções grandes conforme as diretrizes.
-   **Coesão e Baixo Acoplamento**: Projete módulos com responsabilidades claras e minimize dependências desnecessárias entre eles.
-   **Atomicidade**: Use transações (`DeeperHub.Core.Data.Repo.transaction/2`) em operações de serviço que envolvem múltiplas escritas no banco de dados.
-   **Configuração**: Externalize configurações (URLs de serviços externos, chaves de API, etc.) usando o sistema de configuração do Elixir (`config/config.exs`, etc.).

## 5. Conclusão

Seguindo estes passos e melhores práticas, você poderá construir módulos funcionais robustos e bem integrados ao sistema DeeperHub. Lembre-se de que este é um guia base, e dependendo da complexidade do módulo, adaptações podem ser necessárias. A chave é manter a consistência, clareza e aderência às diretrizes do projeto.
