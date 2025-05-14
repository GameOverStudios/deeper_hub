defmodule Deeper_Hub.Core.Data.IntegrationTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Data.Repo

  # Definimos um segundo schema User para simular joins entre tabelas
  # Isso evita a necessidade de criar uma nova tabela no banco de dados
  defmodule UserExtended do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "users" do
      field :username, :string
      field :email, :string
      field :password_hash, :string
      field :is_active, :boolean, default: true
      field :last_login, :naive_datetime
      field :password, :string, virtual: true

      timestamps()
    end

    def changeset(user, attrs) do
      user
      |> cast(attrs, [:username, :email, :password, :is_active])
      |> validate_required([:username, :email])
      |> validate_format(:email, ~r/@/)
    end
  end

  setup do
    # Configurar o sandbox para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpar o cache antes de cada teste
    :ets.delete_all_objects(:repository_cache)
    :ets.delete_all_objects(:repository_cache_stats)
    
    # Inicializar estatísticas de cache
    :ets.insert(:repository_cache_stats, {:hits, 0})
    :ets.insert(:repository_cache_stats, {:misses, 0})
    
    :ok
  end

  test "fluxo completo de CRUD e consultas" do
    # 1. Inserir um novo usuário
    user_attrs = %{
      username: "integration_user",
      email: "integration@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user} = Repository.insert(User, user_attrs)
    assert user.username == "integration_user"
    
    # 2. Buscar o usuário pelo ID
    {:ok, fetched_user} = Repository.get(User, user.id)
    assert fetched_user.id == user.id
    
    # 3. Verificar estatísticas de cache após a segunda busca
    {:ok, _} = Repository.get(User, user.id)
    stats = Repository.get_cache_stats()
    assert stats.hits >= 1
    
    # 4. Atualizar o usuário
    {:ok, updated_user} = Repository.update(user, %{username: "updated_integration_user"})
    assert updated_user.username == "updated_integration_user"
    
    # 5. Verificar se o cache foi invalidado após a atualização
    {:ok, refetched_user} = Repository.get(User, user.id)
    assert refetched_user.username == "updated_integration_user"
    
    # 6. Inserir mais usuários para testar listagem e paginação
    for i <- 1..5 do
      Repository.insert(User, %{
        username: "list_user_#{i}",
        email: "list_user_#{i}@example.com",
        password: "password123",
        is_active: true
      })
    end
    
    # 7. Testar listagem com paginação
    {:ok, page1} = Repository.list(User, limit: 3, offset: 0)
    assert length(page1) == 3
    
    {:ok, page2} = Repository.list(User, limit: 3, offset: 3)
    assert length(page2) >= 1
    
    # 8. Testar busca com condições
    {:ok, active_users} = Repository.find(User, %{is_active: true})
    assert length(active_users) >= 6 # O usuário original + 5 novos
    
    # 9. Testar busca com LIKE
    {:ok, integration_users} = Repository.find(User, %{username: {:like, "integration"}})
    assert length(integration_users) >= 1
    
    # 10. Criar outro usuário para testar joins (simulando relacionamentos)
    {:ok, user2} = Repository.insert(UserExtended, %{
      username: "related_user",
      email: "related@example.com",
      password: "password123",
      is_active: true
    })
    
    # 11. Testar inner join (usando a mesma tabela users para simular um join)
    {:ok, join_results} = Repository.join_inner(
      User,
      UserExtended,
      [:id, :username, :email],
      %{is_active: true},
      join_on: {:is_active, :is_active}
    )
    
    assert length(join_results) >= 1
    # Verificamos se o usuário original está nos resultados
    join_result = Enum.find(join_results, fn r -> r.id == user.id end)
    assert join_result != nil
    
    # 12. Testar left join (usando a mesma tabela users para simular um join)
    {:ok, left_results} = Repository.join_left(
      User,
      UserExtended,
      [:id, :username],
      %{},
      join_on: {:is_active, :is_active}
    )
    
    assert length(left_results) >= 6 # Todos os usuários, mesmo sem perfil
    
    # 13. Excluir o usuário e verificar se foi removido
    {:ok, :deleted} = Repository.delete(user)
    assert {:error, :not_found} = Repository.get(User, user.id)
    
    # 14. Verificar se o segundo usuário ainda existe após excluir o primeiro
    {:ok, user2_check} = Repository.get(UserExtended, user2.id)
    assert user2_check.id == user2.id
  end

  test "tratamento de erros" do
    # 1. Tentar inserir com dados inválidos
    invalid_user = %{
      username: "", # Inválido, muito curto
      email: "invalid" # Inválido, sem @
    }
    
    assert {:error, changeset} = Repository.insert(User, invalid_user)
    assert changeset.errors != []
    
    # 2. Tentar buscar um ID inexistente
    non_existent_id = "00000000-0000-0000-0000-000000000000"
    assert {:error, :not_found} = Repository.get(User, non_existent_id)
    
    # 3. Tentar atualizar um registro que não existe
    non_existent_user = %User{id: non_existent_id}
    assert {:error, _} = Repository.update(non_existent_user, %{username: "new_name"})
    
    # 4. Tentar excluir um registro que não existe
    # Usamos um try/rescue para capturar o StaleEntryError
    error_result = try do
      Repository.delete(non_existent_user)
    rescue
      Ecto.StaleEntryError -> {:error, :stale_entry}
    end
    
    assert {:error, _} = error_result
  end

  test "desempenho do cache" do
    # 1. Inserir um usuário para teste
    {:ok, user} = Repository.insert(User, %{
      username: "cache_test_user",
      email: "cache@example.com",
      password: "password123",
      is_active: true
    })
    
    # 2. Primeira busca (miss)
    # Limpamos o cache antes para garantir que será um miss
    :ok = Repository.invalidate_cache(User, user.id)
    {:ok, _} = Repository.get(User, user.id)
    
    # 3. Segunda busca (hit)
    {:ok, _} = Repository.get(User, user.id)
    
    # 4. Verificar estatísticas
    stats = Repository.get_cache_stats()
    assert stats.hits >= 1
    assert stats.misses >= 1
    
    # 5. Invalidar cache
    :ok = Repository.invalidate_cache(User, user.id)
    
    # 6. Próxima busca deve ser miss
    {:ok, _} = Repository.get(User, user.id)
    
    # 7. Verificar estatísticas atualizadas
    new_stats = Repository.get_cache_stats()
    assert new_stats.misses > stats.misses
  end
end
