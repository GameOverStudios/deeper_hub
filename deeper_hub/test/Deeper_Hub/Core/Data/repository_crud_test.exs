defmodule Deeper_Hub.Core.Data.RepositoryCrudTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Data.Repo

  # Configuração para testes
  setup do
    # Configurar o sandbox para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpar o cache antes de cada teste
    :ets.delete_all_objects(:repository_cache)
    
    # Criar um usuário para testes
    user_attrs = %{
      username: "crud_test_user",
      email: "crud_test@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user} = RepositoryCrud.insert(User, user_attrs)
    
    %{user: user}
  end

  describe "insert/2" do
    test "inserts a valid record" do
      attrs = %{
        username: "new_crud_user",
        email: "new_crud@example.com",
        password: "password123",
        is_active: true
      }
      
      assert {:ok, user} = RepositoryCrud.insert(User, attrs)
      assert user.username == "new_crud_user"
      assert user.email == "new_crud@example.com"
      assert user.is_active == true
      assert is_binary(user.id) # Verifica se o ID é um UUID
    end
    
    test "returns error with invalid data" do
      # Tentando inserir sem campos obrigatórios
      attrs = %{
        is_active: true
      }
      
      assert {:error, changeset} = RepositoryCrud.insert(User, attrs)
      assert changeset.errors != []
    end
  end

  describe "get/2" do
    test "retrieves a record by ID", %{user: user} do
      assert {:ok, retrieved_user} = RepositoryCrud.get(User, user.id)
      assert retrieved_user.id == user.id
      assert retrieved_user.username == user.username
    end
    
    test "returns error for non-existent ID" do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      assert {:error, :not_found} = RepositoryCrud.get(User, non_existent_id)
    end
  end

  describe "update/2" do
    test "updates a record with valid data", %{user: user} do
      update_attrs = %{username: "updated_crud_username"}
      assert {:ok, updated_user} = RepositoryCrud.update(user, update_attrs)
      assert updated_user.username == "updated_crud_username"
      
      # Verify the update persisted
      assert {:ok, retrieved_user} = RepositoryCrud.get(User, user.id)
      assert retrieved_user.username == "updated_crud_username"
    end
    
    test "returns error with invalid data", %{user: user} do
      # Tentando atualizar com dados inválidos
      update_attrs = %{email: "invalid_email"}
      assert {:error, changeset} = RepositoryCrud.update(user, update_attrs)
      assert changeset.errors != []
    end
  end

  describe "delete/1" do
    test "deletes a record", %{user: user} do
      assert {:ok, :deleted} = RepositoryCrud.delete(user)
      assert {:error, :not_found} = RepositoryCrud.get(User, user.id)
    end
  end

  describe "list/2" do
    test "returns all records of a schema" do
      assert {:ok, users} = RepositoryCrud.list(User)
      assert length(users) > 0
    end
    
    test "with pagination", %{} do
      # Insert additional users
      for i <- 1..5 do
        RepositoryCrud.insert(User, %{
          username: "crud_user_#{i}",
          email: "crud_user_#{i}@example.com",
          password: "password123",
          is_active: true
        })
      end
      
      assert {:ok, page1} = RepositoryCrud.list(User, limit: 3, offset: 0)
      assert length(page1) == 3
      
      assert {:ok, page2} = RepositoryCrud.list(User, limit: 3, offset: 3)
      assert length(page2) <= 3
    end
    
    test "with ordering" do
      # Insert users with different timestamps
      for i <- 1..3 do
        RepositoryCrud.insert(User, %{
          username: "ordered_user_#{i}",
          email: "ordered_user_#{i}@example.com",
          password: "password123",
          is_active: true
        })
        # Pequeno atraso para garantir timestamps diferentes
        :timer.sleep(10)
      end
      
      # Ordenar por inserted_at em ordem decrescente
      assert {:ok, desc_users} = RepositoryCrud.list(User, order_by: [desc: :inserted_at])
      
      # Verificar se a ordenação está correta
      if length(desc_users) >= 2 do
        [first, second | _] = desc_users
        assert NaiveDateTime.compare(first.inserted_at, second.inserted_at) in [:gt, :eq]
      end
    end
  end

  describe "find/3" do
    test "returns records matching conditions", %{user: user} do
      assert {:ok, users} = RepositoryCrud.find(User, %{username: user.username})
      assert length(users) == 1
      assert hd(users).id == user.id
    end
    
    test "with multiple conditions" do
      # Insert a user with specific conditions
      RepositoryCrud.insert(User, %{
        username: "crud_active_admin",
        email: "crud_admin@example.com",
        password: "password123",
        is_active: true
      })
      
      assert {:ok, users} = RepositoryCrud.find(User, %{
        username: {:like, "crud_active"},
        is_active: true
      })
      
      assert length(users) > 0
      assert hd(users).username == "crud_active_admin"
    end
    
    test "with special operators" do
      # Test NULL condition
      assert {:ok, _} = RepositoryCrud.find(User, %{last_login: nil})
      
      # Test NOT NULL condition
      assert {:ok, _} = RepositoryCrud.find(User, %{email: :not_nil})
      
      # Test LIKE condition
      RepositoryCrud.insert(User, %{
        username: "silva_test",
        email: "silva@example.com",
        password: "password123",
        is_active: true
      })
      
      assert {:ok, users} = RepositoryCrud.find(User, %{username: {:like, "silva"}})
      assert length(users) > 0
      
      # Test ILIKE condition (case insensitive)
      assert {:ok, users} = RepositoryCrud.find(User, %{username: {:ilike, "SILVA"}})
      assert length(users) > 0
    end
    
    test "with pagination and conditions" do
      # Insert users with same condition
      for i <- 1..5 do
        RepositoryCrud.insert(User, %{
          username: "paginated_user_#{i}",
          email: "paginated_#{i}@example.com",
          password: "password123",
          is_active: true
        })
      end
      
      assert {:ok, page1} = RepositoryCrud.find(
        User, 
        %{username: {:like, "paginated"}}, 
        limit: 2, 
        offset: 0
      )
      
      assert length(page1) == 2
      
      assert {:ok, page2} = RepositoryCrud.find(
        User, 
        %{username: {:like, "paginated"}}, 
        limit: 2, 
        offset: 2
      )
      
      assert length(page2) == 2
    end
  end
end
