defmodule Deeper_Hub.Core.Data.CacheTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Cache
  alias Deeper_Hub.Core.Data.Repository

  setup do
    # O cache já está iniciado pela aplicação, apenas limpamos para cada teste
    Cache.clear()
    # Obtemos o PID do processo de cache existente
    pid = Process.whereis(Deeper_Hub.Core.Data.Cache)
    %{cache_pid: pid}
  end

  describe "operações básicas de cache" do
    test "armazena e recupera valores" do
      # Armazena um valor no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      
      # Recupera o valor do cache
      assert {:ok, {:ok, {:users, 1, "Alice", "alice@example.com"}}} = Cache.get(:users, :find, 1)
    end

    test "retorna :not_found para chaves inexistentes" do
      assert :not_found = Cache.get(:users, :find, 999)
    end

    test "invalida entradas específicas do cache" do
      # Armazena múltiplos valores no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.put(:users, :find, 2, {:ok, {:users, 2, "Bob", "bob@example.com"}})
      Cache.put(:products, :find, 1, {:ok, {:products, 1, "Laptop", 1200.00}})
      
      # Invalida uma entrada específica
      Cache.invalidate(:users, :find, 1)
      
      # Verifica que apenas a entrada específica foi invalidada
      assert :not_found = Cache.get(:users, :find, 1)
      assert {:ok, _} = Cache.get(:users, :find, 2)
      assert {:ok, _} = Cache.get(:products, :find, 1)
    end

    test "invalida todas as entradas de uma tabela" do
      # Armazena múltiplos valores no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.put(:users, :all, nil, {:ok, [{:users, 1, "Alice", "alice@example.com"}]})
      Cache.put(:products, :find, 1, {:ok, {:products, 1, "Laptop", 1200.00}})
      
      # Invalida todas as entradas da tabela users
      Cache.invalidate(:users)
      
      # Verifica que todas as entradas da tabela users foram invalidadas
      assert :not_found = Cache.get(:users, :find, 1)
      assert :not_found = Cache.get(:users, :all, nil)
      assert {:ok, _} = Cache.get(:products, :find, 1)
    end

    test "limpa todo o cache" do
      # Armazena múltiplos valores no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.put(:products, :find, 1, {:ok, {:products, 1, "Laptop", 1200.00}})
      
      # Limpa todo o cache
      Cache.clear()
      
      # Verifica que todas as entradas foram removidas
      assert :not_found = Cache.get(:users, :find, 1)
      assert :not_found = Cache.get(:products, :find, 1)
    end
    
    test "armazena e recupera valores com chaves complexas" do
      # Armazena valores com chaves complexas
      complex_key = %{id: 1, type: :user}
      Cache.put(:users, :find_by, complex_key, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      
      # Recupera o valor usando a chave complexa
      assert {:ok, {:ok, {:users, 1, "Alice", "alice@example.com"}}} = Cache.get(:users, :find_by, complex_key)
    end
    
    test "armazena e recupera valores com resultados nil" do
      # Armazena um valor nil no cache
      Cache.put(:users, :find_settings, 1, {:ok, nil})
      
      # Recupera o valor nil do cache
      assert {:ok, {:ok, nil}} = Cache.get(:users, :find_settings, 1)
    end
  end

  describe "expiração de cache" do
    test "valores expiram após o TTL" do
      # Armazena um valor com TTL curto (100ms)
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}}, 100)
      
      # Verifica que o valor está disponível imediatamente
      assert {:ok, _} = Cache.get(:users, :find, 1)
      
      # Espera o TTL expirar
      :timer.sleep(150)
      
      # Verifica que o valor expirou
      assert :not_found = Cache.get(:users, :find, 1)
    end
    
    test "valores com TTL diferentes expiram independentemente" do
      # Armazena valores com TTLs diferentes
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}}, 300)
      Cache.put(:users, :find, 2, {:ok, {:users, 2, "Bob", "bob@example.com"}}, 100)
      
      # Verifica que ambos os valores estão disponíveis imediatamente
      assert {:ok, _} = Cache.get(:users, :find, 1)
      assert {:ok, _} = Cache.get(:users, :find, 2)
      
      # Espera o TTL menor expirar
      :timer.sleep(150)
      
      # Verifica que apenas o valor com TTL menor expirou
      assert {:ok, _} = Cache.get(:users, :find, 1)  # ainda válido
      assert :not_found = Cache.get(:users, :find, 2)  # expirado
      
      # Espera o TTL maior expirar
      :timer.sleep(200)
      
      # Verifica que ambos os valores expiraram
      assert :not_found = Cache.get(:users, :find, 1)
      assert :not_found = Cache.get(:users, :find, 2)
    end
  end

  describe "estatísticas de cache" do
    test "registra hits e misses" do
      # Captura as estatísticas iniciais
      initial_stats = Cache.stats()
      initial_hits = initial_stats.hits
      initial_misses = initial_stats.misses
      
      # Armazena um valor no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      
      # Gera alguns hits e misses
      Cache.get(:users, :find, 1)  # hit
      Cache.get(:users, :find, 1)  # hit
      Cache.get(:users, :find, 2)  # miss
      Cache.get(:users, :find, 3)  # miss
      
      # Verifica as estatísticas
      final_stats = Cache.stats()
      
      # Verifica o incremento em relação aos valores iniciais
      assert final_stats.hits - initial_hits == 2
      assert final_stats.misses - initial_misses == 2
      
      # A taxa de acerto é calculada com base em todos os hits e misses,
      # não apenas os deste teste, então não podemos testar um valor exato
      assert final_stats.hit_rate >= 0.0 && final_stats.hit_rate <= 1.0
    end
    
    test "reseta estatísticas corretamente" do
      # Gera alguns hits e misses
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.get(:users, :find, 1)  # hit
      Cache.get(:users, :find, 2)  # miss
      
      # Reseta as estatísticas
      Cache.reset_stats()
      
      # Verifica que as estatísticas foram resetadas
      stats = Cache.stats()
      assert stats.hits == 0
      assert stats.misses == 0
      assert stats.hit_rate == 0.0
    end
  end
  
  describe "integração com o repositório" do
    test "cache é atualizado após operações de escrita" do
      # Cria um registro de teste
      test_user = {:users, 100, "cache_test_user", "cache_test@example.com", "hash", DateTime.utc_now()}
      
      # Insere o registro e verifica se o cache está vazio inicialmente
      {:ok, _} = Repository.insert(:users, test_user)
      assert :not_found = Cache.get(:users, :find, 100)
      
      # Busca o registro para armazenar no cache
      {:ok, found_user} = Repository.find(:users, 100)
      
      # Verifica se o registro foi armazenado no cache
      assert {:ok, {:ok, ^found_user}} = Cache.get(:users, :find, 100)
      
      # Atualiza o registro
      updated_user = put_elem(test_user, 2, "updated_user")
      {:ok, _} = Repository.update(:users, updated_user)
      
      # Verifica se o cache foi invalidado após a atualização
      assert :not_found = Cache.get(:users, :find, 100)
      
      # Busca novamente para atualizar o cache
      {:ok, updated_found} = Repository.find(:users, 100)
      assert elem(updated_found, 2) == "updated_user"
      
      # Verifica se o cache foi atualizado
      assert {:ok, {:ok, ^updated_found}} = Cache.get(:users, :find, 100)
      
      # Remove o registro
      {:ok, _} = Repository.delete(:users, 100)
      
      # Verifica se o cache foi invalidado após a remoção
      assert :not_found = Cache.get(:users, :find, 100)
    end
    
    test "cache de operação all é invalidado após modificações" do
      # Limpa o cache e a tabela
      Cache.clear()
      :mnesia.clear_table(:users)
      
      # Insere registros iniciais
      user1 = {:users, 101, "user1", "user1@example.com", "hash1", DateTime.utc_now()}
      user2 = {:users, 102, "user2", "user2@example.com", "hash2", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user1)
      {:ok, _} = Repository.insert(:users, user2)
      
      # Busca todos os registros para armazenar no cache
      {:ok, all_users} = Repository.all(:users)
      assert length(all_users) == 2
      
      # Verifica se o resultado foi armazenado no cache
      assert {:ok, {:ok, cached_users}} = Cache.get(:users, :all, nil)
      assert length(cached_users) == 2
      
      # Insere um novo registro
      user3 = {:users, 103, "user3", "user3@example.com", "hash3", DateTime.utc_now()}
      {:ok, _} = Repository.insert(:users, user3)
      
      # Verifica se o cache de all foi invalidado
      assert :not_found = Cache.get(:users, :all, nil)
      
      # Busca novamente todos os registros
      {:ok, updated_all} = Repository.all(:users)
      assert length(updated_all) == 3
      
      # Verifica se o cache foi atualizado
      assert {:ok, {:ok, cached_updated}} = Cache.get(:users, :all, nil)
      assert length(cached_updated) == 3
    end
  end
  
  describe "comportamento em situações de concorrência" do
    test "múltiplas operações concorrentes mantêm consistência" do
      # Cria uma lista de tarefas concorrentes
      tasks = for i <- 1..10 do
        Task.async(fn -> 
          # Cada tarefa armazena e recupera um valor diferente
          Cache.put(:concurrent, :test, i, {:ok, i})
          Cache.get(:concurrent, :test, i)
        end)
      end
      
      # Aguarda todas as tarefas terminarem
      results = Task.await_many(tasks)
      
      # Verifica se todas as operações foram bem-sucedidas
      for i <- 1..10 do
        assert Enum.member?(results, {:ok, {:ok, i}})
      end
    end
  end
end
