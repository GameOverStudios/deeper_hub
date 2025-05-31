defmodule DeeperHub.Core.Data.UsersCrudTest do
  @moduledoc """
  Módulo para testar operações CRUD (Create, Read, Update, Delete) da tabela users.

  Este módulo fornece testes abrangentes para todas as operações básicas
  de manipulação de dados de usuários no sistema DeeperHub.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Repo
  alias Jason

  @doc """
  Executa todos os testes CRUD para a tabela users.

  ## Retorno

  - `:ok` - Todos os testes passaram
  - `{:error, failed_tests}` - Lista de testes que falharam
  """
  @spec run_all_crud_tests() :: :ok | {:error, list()}
  def run_all_crud_tests do
    Logger.info("Iniciando testes CRUD da tabela users...")

    tests = [
      {"CREATE - Inserir usuário", &test_create_user/0},
      {"READ - Buscar usuário por ID", &test_read_user_by_id/0},
      {"READ - Buscar usuário por email", &test_read_user_by_email/0},
      {"READ - Buscar usuário por username", &test_read_user_by_username/0},
      {"READ - Listar todos os usuários", &test_read_all_users/0},
      {"UPDATE - Atualizar dados do usuário", &test_update_user/0},
      {"UPDATE - Atualizar status do usuário", &test_update_user_status/0},
      {"DELETE - Remover usuário", &test_delete_user/0},
      {"CRUD - Teste completo de ciclo", &test_full_crud_cycle/0},
      {"VALIDAÇÃO - Teste de constraints", &test_constraints/0}
    ]

    # Limpa dados de teste antes de começar
    cleanup_test_data()

    failed_tests = run_tests(tests, [])

    # Limpa dados de teste após os testes
    cleanup_test_data()

    case failed_tests do
      [] ->
        Logger.info("Todos os testes CRUD da tabela users passaram com sucesso!")
        :ok
      failed ->
        Logger.error("Testes CRUD falharam: #{inspect(failed)}")
        {:error, failed}
    end
  end

  @doc """
  Demonstra operações CRUD básicas com a tabela users.
  """
  @spec demo_users_crud() :: :ok
  def demo_users_crud do
    Logger.info("Demonstrando operações CRUD da tabela users...")

    # Limpa dados anteriores
    cleanup_test_data()

    # CREATE - Criar usuário
    user_data = %{
      id: "demo_user_001",
      username: "joao_demo",
      email: "joao.demo@deeperhub.com",
      password_hash: "$2b$12$demo_hash_for_testing_purposes",
      full_name: "João da Silva Demo",
      bio: "Usuário de demonstração do sistema DeeperHub",
      avatar_url: "https://avatar.example.com/joao_demo.jpg",
      status: "online",
      last_seen: DateTime.utc_now() |> DateTime.to_iso8601(),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case create_user(user_data) do
      {:ok, _} ->
        Logger.info("✅ Usuário criado: #{user_data.username}")

        # READ - Buscar usuário
        case get_user_by_id(user_data.id) do
          {:ok, user} ->
            Logger.info("✅ Usuário encontrado: #{inspect(user)}")

            # UPDATE - Atualizar usuário
            updates = %{
              bio: "Bio atualizada para demonstração",
              status: "away",
              updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
            }

            case update_user(user_data.id, updates) do
              {:ok, _} ->
                Logger.info("✅ Usuário atualizado com sucesso")

                # READ novamente para verificar atualização
                case get_user_by_id(user_data.id) do
                  {:ok, updated_user} ->
                    Logger.info("✅ Dados atualizados verificados: #{inspect(updated_user)}")
                  {:error, reason} ->
                    Logger.error("❌ Erro ao verificar atualização: #{inspect(reason)}")
                end

              {:error, reason} ->
                Logger.error("❌ Erro ao atualizar usuário: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.error("❌ Erro ao buscar usuário: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.error("❌ Erro ao criar usuário: #{inspect(reason)}")
    end

    # Listar todos os usuários
    case list_all_users() do
      {:ok, users} ->
        Logger.info("✅ Total de usuários no sistema: #{length(users)}")
      {:error, reason} ->
        Logger.error("❌ Erro ao listar usuários: #{inspect(reason)}")
    end

    # Limpa dados de demonstração
    cleanup_test_data()

    Logger.info("Demonstração CRUD concluída!")
    :ok
  end

  # Funções CRUD

  @doc """
  Cria um novo usuário na tabela.
  """
  @spec create_user(map()) :: {:ok, any()} | {:error, any()}
  def create_user(user_data) do
    sql = """
    INSERT INTO users (id, username, email, password_hash, full_name, bio, avatar_url, status, last_seen, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    params = [
      user_data.id,
      user_data.username,
      user_data.email,
      user_data.password_hash,
      user_data[:full_name],
      user_data[:bio],
      user_data[:avatar_url],
      user_data[:status] || "offline",
      user_data[:last_seen],
      user_data.created_at,
      user_data.updated_at
    ]

    Repo.execute(sql, params)
  end

  @doc """
  Busca um usuário por ID.
  """
  @spec get_user_by_id(String.t()) :: {:ok, map()} | {:error, any()}
  def get_user_by_id(user_id) do
    sql = "SELECT * FROM users WHERE id = ? LIMIT 1"

    case Repo.query(sql, [user_id]) do
      {:ok, []} -> {:error, :not_found}
      {:ok, [user_row]} -> {:ok, row_to_user_map(user_row)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Busca um usuário por email.
  """
  @spec get_user_by_email(String.t()) :: {:ok, map()} | {:error, any()}
  def get_user_by_email(email) do
    sql = "SELECT * FROM users WHERE email = ? LIMIT 1"

    case Repo.query(sql, [email]) do
      {:ok, []} -> {:error, :not_found}
      {:ok, [user_row]} -> {:ok, row_to_user_map(user_row)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Busca um usuário por username.
  """
  @spec get_user_by_username(String.t()) :: {:ok, map()} | {:error, any()}
  def get_user_by_username(username) do
    sql = "SELECT * FROM users WHERE username = ? LIMIT 1"

    case Repo.query(sql, [username]) do
      {:ok, []} -> {:error, :not_found}
      {:ok, [user_row]} -> {:ok, row_to_user_map(user_row)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lista todos os usuários.
  """
  @spec list_all_users() :: {:ok, list(map())} | {:error, any()}
  def list_all_users do
    sql = "SELECT * FROM users ORDER BY created_at DESC"

    case Repo.query(sql) do
      {:ok, rows} ->
        users = Enum.map(rows, &row_to_user_map/1)
        {:ok, users}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Atualiza dados de um usuário.
  """
  @spec update_user(String.t(), map()) :: {:ok, any()} | {:error, any()}
  def update_user(user_id, updates) do
    # Constrói dinamicamente a query UPDATE baseada nos campos fornecidos
    {set_clauses, params} = build_update_clauses(updates)

    sql = "UPDATE users SET #{set_clauses}, updated_at = ? WHERE id = ?"

    # Adiciona timestamp de atualização e ID do usuário aos parâmetros
    final_params = params ++ [DateTime.utc_now() |> DateTime.to_iso8601(), user_id]

    Repo.execute(sql, final_params)
  end

  @doc """
  Remove um usuário da tabela.
  """
  @spec delete_user(String.t()) :: {:ok, any()} | {:error, any()}
  def delete_user(user_id) do
    sql = "DELETE FROM users WHERE id = ?"
    Repo.execute(sql, [user_id])
  end

  @doc """
  Conta o total de usuários na tabela.
  """
  @spec count_users() :: {:ok, integer()} | {:error, any()}
  def count_users do
    sql = "SELECT COUNT(*) as total FROM users"

    case Repo.query(sql) do
      {:ok, [[count]]} -> {:ok, count}
      {:error, reason} -> {:error, reason}
    end
  end

  # Funções privadas para testes

  defp run_tests([], failed), do: failed
  defp run_tests([{name, test_fn} | rest], failed) do
    Logger.info("Executando teste: #{name}")

    case test_fn.() do
      :ok ->
        Logger.info("✅ #{name} - PASSOU")
        run_tests(rest, failed)
      {:error, reason} ->
        Logger.error("❌ #{name} - FALHOU: #{inspect(reason)}")
        run_tests(rest, [name | failed])
    end
  end

  defp test_create_user do
    try do
      user_data = %{
        id: "test_user_001",
        username: "test_user",
        email: "test@example.com",
        password_hash: "$2b$12$test_hash",
        full_name: "Test User",
        bio: "Test bio",
        avatar_url: "https://example.com/avatar.jpg",
        status: "online",
        last_seen: DateTime.utc_now() |> DateTime.to_iso8601(),
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      case create_user(user_data) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_read_user_by_id do
    try do
      case get_user_by_id("test_user_001") do
        {:ok, user} when is_map(user) -> :ok
        {:error, :not_found} -> {:error, :user_not_found}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_read_user_by_email do
    try do
      case get_user_by_email("test@example.com") do
        {:ok, user} when is_map(user) -> :ok
        {:error, :not_found} -> {:error, :user_not_found}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_read_user_by_username do
    try do
      case get_user_by_username("test_user") do
        {:ok, user} when is_map(user) -> :ok
        {:error, :not_found} -> {:error, :user_not_found}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_read_all_users do
    try do
      case list_all_users() do
        {:ok, users} when is_list(users) -> :ok
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_update_user do
    try do
      updates = %{
        bio: "Updated bio for testing",
        status: "away"
      }

      case update_user("test_user_001", updates) do
        {:ok, _} ->
          # Verifica se a atualização foi aplicada
          case get_user_by_id("test_user_001") do
            {:ok, user} ->
              if user.bio == "Updated bio for testing" and user.status == "away" do
                :ok
              else
                {:error, :update_not_applied}
              end
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_update_user_status do
    try do
      updates = %{status: "offline"}

      case update_user("test_user_001", updates) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_delete_user do
    try do
      case delete_user("test_user_001") do
        {:ok, _} ->
          # Verifica se o usuário foi realmente removido
          case get_user_by_id("test_user_001") do
            {:error, :not_found} -> :ok
            {:ok, _} -> {:error, :user_still_exists}
            {:error, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_full_crud_cycle do
    try do
      # CREATE
      user_data = %{
        id: "cycle_test_user",
        username: "cycle_test",
        email: "cycle@test.com",
        password_hash: "$2b$12$cycle_test_hash",
        full_name: "Cycle Test User",
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      {:ok, _} = create_user(user_data)

      # READ
      {:ok, _user} = get_user_by_id("cycle_test_user")

      # UPDATE
      {:ok, _} = update_user("cycle_test_user", %{bio: "Cycle test bio"})

      # READ novamente
      {:ok, _updated_user} = get_user_by_id("cycle_test_user")

      # DELETE
      {:ok, _} = delete_user("cycle_test_user")

      # Verifica se foi deletado
      case get_user_by_id("cycle_test_user") do
        {:error, :not_found} -> :ok
        _ -> {:error, :delete_failed}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp test_constraints do
    try do
      # Testa constraint de email único
      user1 = %{
        id: "constraint_test_1",
        username: "constraint1",
        email: "constraint@test.com",
        password_hash: "$2b$12$constraint_hash",
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      user2 = %{
        id: "constraint_test_2",
        username: "constraint2",
        email: "constraint@test.com", # Email duplicado
        password_hash: "$2b$12$constraint_hash",
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      # Primeiro usuário deve ser criado com sucesso
      {:ok, _} = create_user(user1)

      # Segundo usuário deve falhar devido ao email duplicado
      case create_user(user2) do
        {:error, _} ->
          # Limpa o primeiro usuário
          delete_user("constraint_test_1")
          :ok
        {:ok, _} ->
          # Se não falhou, limpa ambos e retorna erro
          delete_user("constraint_test_1")
          delete_user("constraint_test_2")
          {:error, :constraint_not_working}
      end
    rescue
      error -> {:error, error}
    end
  end

  # Funções auxiliares

  defp row_to_user_map([id, username, email, password_hash, full_name, bio, avatar_url, status, last_seen, created_at, updated_at]) do
    %{
      id: id,
      username: username,
      email: email,
      password_hash: password_hash,
      full_name: full_name,
      bio: bio,
      avatar_url: avatar_url,
      status: status,
      last_seen: last_seen,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  defp build_update_clauses(updates) do
    updates
    |> Enum.reduce({[], []}, fn {field, value}, {clauses, params} ->
      clause = "#{field} = ?"
      {[clause | clauses], [value | params]}
    end)
    |> then(fn {clauses, params} ->
      {Enum.reverse(clauses) |> Enum.join(", "), Enum.reverse(params)}
    end)
  end

  defp cleanup_test_data do
    test_ids = [
      "test_user_001",
      "cycle_test_user",
      "constraint_test_1",
      "constraint_test_2",
      "demo_user_001"
    ]

    Enum.each(test_ids, fn id ->
      delete_user(id)
    end)

    # Remove usuários de teste por padrão de email
    Repo.execute("DELETE FROM users WHERE email LIKE '%@test.com' OR email LIKE '%@example.com'")
  end
end
