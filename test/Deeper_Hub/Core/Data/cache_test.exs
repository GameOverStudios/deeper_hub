defmodule Deeper_Hub.Core.Data.RepositoryCacheTest do
  @moduledoc """
  Testes para o sistema de cache integrado no Repository.
  
  Este módulo testa as funcionalidades do sistema de cache integrado,
  garantindo que o cache funcione corretamente para melhorar o desempenho
  das consultas ao banco de dados.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Schemas.User
  
  # Configuração para cada teste
  setup do
    # Inicia uma transação para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    
    # Permite o uso de transações aninhadas
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpa o cache antes de cada teste
    Repository.clear_cache()
    
    # Limpa a tabela para garantir um estado conhecido
    Repo.delete_all(User)
    
    # Dados de teste
    valid_user = %{
      username: "testuser",
      email: "test@example.com",
      password: "password123"
    }
    
    # Insere um usuário para testes
    {:ok, user} = Repository.insert(User, valid_user)
    
    # Retorna os dados para uso nos testes
    {:ok, %{user: user, valid_user: valid_user}}
  end
  
  describe "cache no Repository" do
    @tag timeout: 120_000  # Aumenta o timeout para 2 minutos
    test "verifica a funcionalidade do cache", %{user: user} do
      # Limpa o cache para garantir um estado conhecido
      Repository.clear_cache()
      
      # Verifica se o registro não está no cache inicialmente
      # Primeira consulta (sem cache)
      {:ok, user_from_db} = Repository.get(User, user.id)
      assert user_from_db.id == user.id
      
      # Verifica se o registro está no cache após a primeira consulta
      # Obtem estatísticas do cache
      stats_after_first_query = Repository.get_cache_stats()
      assert stats_after_first_query.misses >= 1
      
      # Segunda consulta (com cache)
      {:ok, user_from_cache} = Repository.get(User, user.id)
      assert user_from_cache.id == user.id
      
      # Verifica se o cache foi usado na segunda consulta
      stats_after_second_query = Repository.get_cache_stats()
      assert stats_after_second_query.hits >= 1
      assert stats_after_second_query.hits > stats_after_first_query.hits
      
      # Limpa o cache
      Repository.clear_cache()
      
      # Verifica se as estatísticas foram reiniciadas
      stats_after_clear = Repository.get_cache_stats()
      assert stats_after_clear.hits == 0
      assert stats_after_clear.misses == 0
    end
    
    test "cache é atualizado após inserção", %{valid_user: _valid_user} do
      # Cria um novo usuário com dados diferentes
      new_user_data = %{
        username: "newuser",
        email: "new@example.com",
        password: "newpassword"
      }
      
      # Insere o novo usuário
      {:ok, new_user} = Repository.insert(User, new_user_data)
      
      # Consulta o usuário - deve vir do cache
      {:ok, cached_user} = Repository.get(User, new_user.id)
      
      # Verifica que o usuário retornado é o mesmo que foi inserido
      assert cached_user.id == new_user.id
      assert cached_user.username == "newuser"
    end
    
    test "cache é invalidado após atualização", %{user: user} do
      # Consulta inicial para garantir que o usuário está no cache
      {:ok, cached_user} = Repository.get(User, user.id)
      assert cached_user.username == "testuser"
      
      # Atualiza o usuário
      {:ok, _updated_user} = Repository.update(user, %{username: "updated_username"})
      
      # Consulta novamente - deve retornar o usuário atualizado, não o em cache
      {:ok, fetched_user} = Repository.get(User, user.id)
      
      # Verifica que o usuário retornado é o atualizado
      assert fetched_user.username == "updated_username"
      assert fetched_user.username != cached_user.username
    end
    
    test "cache é invalidado após remoção", %{user: user} do
      # Consulta inicial para garantir que o usuário está no cache
      {:ok, _} = Repository.get(User, user.id)
      
      # Remove o usuário
      {:ok, :deleted} = Repository.delete(user)
      
      # Consulta novamente - deve retornar not_found
      result = Repository.get(User, user.id)
      
      # Verifica que o usuário foi removido
      assert result == {:error, :not_found}
    end
  end
  
  describe "estatísticas de cache" do
    test "registra hits e misses corretamente", %{user: user} do
      # Limpa o cache e as estatísticas
      Repository.clear_cache()
      
      # Primeira consulta (miss)
      Repository.get(User, "nonexistent_id")
      
      # Consulta o usuário existente (primeiro miss, depois armazenado no cache)
      Repository.get(User, user.id)
      
      # Segunda consulta (hit)
      Repository.get(User, user.id)
      
      # Obtém as estatísticas
      stats = Repository.get_cache_stats()
      
      # Verifica as estatísticas
      assert stats.hits >= 1
      assert stats.misses >= 1
      assert stats.hit_rate > 0
    end
    
    test "calcula a taxa de acertos corretamente" do
      # Limpa o cache e as estatísticas
      Repository.clear_cache()
      
      # Cria vários usuários para testar o cache
      users = for i <- 1..3 do
        {:ok, user} = Repository.insert(User, %{
          username: "user#{i}",
          email: "user#{i}@example.com",
          password: "password"
        })
        user
      end
      
      # Consulta cada usuário duas vezes (primeira vez miss, segunda vez hit)
      Enum.each(users, fn user ->
        Repository.get(User, user.id) # Primeira consulta (miss ou hit, dependendo da inserção)
        Repository.get(User, user.id) # Segunda consulta (hit)
      end)
      
      # Consulta um usuário inexistente (miss)
      Repository.get(User, "nonexistent_id")
      
      # Obtém as estatísticas
      stats = Repository.get_cache_stats()
      
      # Verifica que as estatísticas foram registradas
      assert stats.hits > 0
      assert stats.misses > 0
      assert stats.hit_rate > 0
    end
    
    test "clear_cache limpa o cache e reinicia as estatísticas", %{user: user} do
      # Garante que há algo no cache
      Repository.get(User, user.id)
      
      # Verifica que há estatísticas registradas
      stats_before = Repository.get_cache_stats()
      assert stats_before.hits + stats_before.misses > 0
      
      # Limpa o cache
      Repository.clear_cache()
      
      # Verifica que as estatísticas foram reiniciadas
      stats_after = Repository.get_cache_stats()
      assert stats_after.hits == 0
      assert stats_after.misses == 0
      assert stats_after.hit_rate == 0.0
    end
  end
end
