defmodule Deeper_Hub.Core.Data.RepositoryTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Data.Repo
  
  # Configuração para testes
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
    
    # Criar um usuário para testes
    user_attrs = %{
      username: "test_user",
      email: "test@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user} = Repository.insert(User, user_attrs)
    
    %{user: user}
  end

  describe "CRUD operations" do
    test "insert/2 inserts a new record", %{} do
      attrs = %{
        username: "new_user",
        email: "new@example.com",
        password: "password123",
        is_active: true
      }
      
      assert {:ok, user} = Repository.insert(User, attrs)
      assert user.username == "new_user"
      assert user.email == "new@example.com"
      assert user.is_active == true
    end
    
    test "get/2 retrieves a record by ID", %{user: user} do
      assert {:ok, retrieved_user} = Repository.get(User, user.id)
      assert retrieved_user.id == user.id
      assert retrieved_user.username == user.username
    end
    
    test "get/2 returns error for non-existent ID" do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      assert {:error, :not_found} = Repository.get(User, non_existent_id)
    end
    
    test "update/2 updates a record", %{user: user} do
      update_attrs = %{username: "updated_username"}
      assert {:ok, updated_user} = Repository.update(user, update_attrs)
      assert updated_user.username == "updated_username"
      
      # Verify the update persisted
      assert {:ok, retrieved_user} = Repository.get(User, user.id)
      assert retrieved_user.username == "updated_username"
    end
    
    test "delete/1 deletes a record", %{user: user} do
      assert {:ok, :deleted} = Repository.delete(user)
      assert {:error, :not_found} = Repository.get(User, user.id)
    end
  end

  describe "list and find operations" do
    test "list/2 returns all records of a schema" do
      assert {:ok, users} = Repository.list(User)
      assert length(users) > 0
    end
    
    test "list/2 with pagination", %{} do
      # Insert additional users
      for i <- 1..5 do
        Repository.insert(User, %{
          username: "user_#{i}",
          email: "user_#{i}@example.com",
          password: "password123",
          is_active: true
        })
      end
      
      assert {:ok, page1} = Repository.list(User, limit: 3, offset: 0)
      assert length(page1) == 3
      
      assert {:ok, page2} = Repository.list(User, limit: 3, offset: 3)
      assert length(page2) <= 3
    end
    
    test "find/3 returns records matching conditions", %{user: user} do
      assert {:ok, users} = Repository.find(User, %{username: user.username})
      assert length(users) == 1
      assert hd(users).id == user.id
    end
    
    test "find/3 with multiple conditions" do
      # Insert a user with specific conditions
      Repository.insert(User, %{
        username: "active_admin",
        email: "admin@example.com",
        password: "password123",
        is_active: true
      })
      
      assert {:ok, users} = Repository.find(User, %{
        username: {:like, "admin"},
        is_active: true
      })
      
      assert length(users) > 0
      assert hd(users).username == "active_admin"
    end
    
    test "find/3 with special operators" do
      # Test NULL condition
      assert {:ok, _} = Repository.find(User, %{last_login: nil})
      
      # Test NOT NULL condition
      assert {:ok, _} = Repository.find(User, %{email: :not_nil})
      
      # Test IN condition
      {:ok, users} = Repository.list(User)
      ids = Enum.map(users, & &1.id)
      
      if length(ids) >= 2 do
        test_ids = Enum.take(ids, 2)
        assert {:ok, found_users} = Repository.find(User, %{id: {:in, test_ids}})
        assert length(found_users) == 2
      end
    end
  end

  describe "cache management" do
    test "get/2 caches results", %{user: user} do
      # First call should miss cache
      assert {:ok, _} = Repository.get(User, user.id)
      
      # Get initial stats
      initial_stats = Repository.get_cache_stats()
      
      # Second call should hit cache
      assert {:ok, _} = Repository.get(User, user.id)
      
      # Get updated stats
      updated_stats = Repository.get_cache_stats()
      
      # Verify cache hit increased
      assert updated_stats.hits > initial_stats.hits
    end
    
    test "invalidate_cache/2 removes item from cache", %{user: user} do
      # Ensure item is in cache
      assert {:ok, _} = Repository.get(User, user.id)
      
      # Invalidate cache
      assert :ok = Repository.invalidate_cache(User, user.id)
      
      # Get stats before second call
      stats_before = Repository.get_cache_stats()
      
      # Call again should miss cache
      assert {:ok, _} = Repository.get(User, user.id)
      
      # Get updated stats
      stats_after = Repository.get_cache_stats()
      
      # Verify cache miss increased
      assert stats_after.misses > stats_before.misses
    end
  end
end
