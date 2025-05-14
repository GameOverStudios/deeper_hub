defmodule Deeper_Hub.Core.Data.CacheTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Cache

  setup do
    # O cache já está iniciado pela aplicação, apenas limpamos para cada teste
    Cache.clear()
    # Obtemos o PID do processo de cache existente
    pid = Process.whereis(Deeper_Hub.Core.Data.Cache)
    %{cache_pid: pid}
  end

  describe "operau00e7u00f5es bu00e1sicas de cache" do
    test "armazena e recupera valores" do
      # Armazena um valor no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      
      # Recupera o valor do cache
      assert {:ok, {:ok, {:users, 1, "Alice", "alice@example.com"}}} = Cache.get(:users, :find, 1)
    end

    test "retorna :not_found para chaves inexistentes" do
      assert :not_found = Cache.get(:users, :find, 999)
    end

    test "invalida entradas especu00edficas do cache" do
      # Armazena mu00faltiplos valores no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.put(:users, :find, 2, {:ok, {:users, 2, "Bob", "bob@example.com"}})
      Cache.put(:products, :find, 1, {:ok, {:products, 1, "Laptop", 1200.00}})
      
      # Invalida uma entrada especu00edfica
      Cache.invalidate(:users, :find, 1)
      
      # Verifica que apenas a entrada especu00edfica foi invalidada
      assert :not_found = Cache.get(:users, :find, 1)
      assert {:ok, _} = Cache.get(:users, :find, 2)
      assert {:ok, _} = Cache.get(:products, :find, 1)
    end

    test "invalida todas as entradas de uma tabela" do
      # Armazena mu00faltiplos valores no cache
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
      # Armazena mu00faltiplos valores no cache
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}})
      Cache.put(:products, :find, 1, {:ok, {:products, 1, "Laptop", 1200.00}})
      
      # Limpa todo o cache
      Cache.clear()
      
      # Verifica que todas as entradas foram removidas
      assert :not_found = Cache.get(:users, :find, 1)
      assert :not_found = Cache.get(:products, :find, 1)
    end
  end

  describe "expirau00e7u00e3o de cache" do
    test "valores expiram apu00f3s o TTL" do
      # Armazena um valor com TTL curto (100ms)
      Cache.put(:users, :find, 1, {:ok, {:users, 1, "Alice", "alice@example.com"}}, 100)
      
      # Verifica que o valor estu00e1 disponu00edvel imediatamente
      assert {:ok, _} = Cache.get(:users, :find, 1)
      
      # Espera o TTL expirar
      :timer.sleep(150)
      
      # Verifica que o valor expirou
      assert :not_found = Cache.get(:users, :find, 1)
    end
  end

  describe "estatu00edsticas de cache" do
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
  end
end
