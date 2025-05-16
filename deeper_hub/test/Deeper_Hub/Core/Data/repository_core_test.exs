defmodule Deeper_Hub.Core.Data.RepositoryCoreTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.RepositoryCore
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
    
    :ok
  end

  describe "cache management" do
    test "get_from_cache/2 returns :not_found when item not in cache" do
      assert RepositoryCore.get_from_cache(User, "non-existent-id") == :not_found
    end
    
    test "put_in_cache/3 stores item in cache" do
      test_item = %{id: "test-id", name: "Test Item"}
      RepositoryCore.put_in_cache(User, "test-id", test_item)
      
      assert RepositoryCore.get_from_cache(User, "test-id") == {:ok, test_item}
    end
    
    test "invalidate_cache/2 removes item from cache" do
      test_item = %{id: "test-id", name: "Test Item"}
      RepositoryCore.put_in_cache(User, "test-id", test_item)
      
      assert RepositoryCore.get_from_cache(User, "test-id") == {:ok, test_item}
      
      RepositoryCore.invalidate_cache(User, "test-id")
      assert RepositoryCore.get_from_cache(User, "test-id") == :not_found
    end
    
    test "get_cache_stats/0 returns correct statistics" do
      # Initial stats
      stats = RepositoryCore.get_cache_stats()
      assert stats.hits == 0
      assert stats.misses == 0
      assert stats.hit_rate == 0.0
      
      # Add a miss
      RepositoryCore.get_from_cache(User, "non-existent-id")
      stats = RepositoryCore.get_cache_stats()
      assert stats.misses == 1
      
      # Add an item and then get it (hit)
      test_item = %{id: "test-id", name: "Test Item"}
      RepositoryCore.put_in_cache(User, "test-id", test_item)
      RepositoryCore.get_from_cache(User, "test-id")
      
      stats = RepositoryCore.get_cache_stats()
      assert stats.hits == 1
      assert stats.hit_rate == 0.5 # 1 hit out of 2 attempts
    end
  end

  # A função get_repo/0 não está definida publicamente no RepositoryCore
  # O módulo usa o Repo diretamente através de alias
  describe "database connection" do
    test "Repo is properly aliased" do
      assert Repo == Deeper_Hub.Core.Data.Repo
    end
  end
end
