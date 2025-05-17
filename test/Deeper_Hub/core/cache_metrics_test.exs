defmodule Deeper_Hub.Core.CacheMetricsTest do
  @moduledoc """
  Testes para o sistema de cache e métricas.
  """
  
  use ExUnit.Case
  import Deeper_Hub.Factory
  
  alias Deeper_Hub.Core.Cache
  
  setup do
    # Limpa o cache antes de cada teste
    Cache.clear()
    :ok
  end
  
  describe "cache operations" do
    test "put and get operations" do
      # Cria uma entrada de cache usando o factory
      entry = build(:cache_entry)
      
      # Insere no cache
      assert {:ok, true} = Cache.put(entry.key, entry.value, entry.ttl)
      
      # Verifica se está no cache
      assert {:ok, true} = Cache.exists?(entry.key)
      
      # Recupera do cache
      {:ok, value} = Cache.get(entry.key)
      assert value == entry.value
    end
    
    test "cache miss" do
      # Tenta recuperar uma chave inexistente
      assert {:ok, nil} = Cache.get("non_existent_key")
    end
    
    test "delete operation" do
      # Cria e insere uma entrada de cache
      entry = build(:cache_entry)
      {:ok, true} = Cache.put(entry.key, entry.value, entry.ttl)
      
      # Verifica se existe
      assert {:ok, true} = Cache.exists?(entry.key)
      
      # Remove do cache
      assert {:ok, true} = Cache.del(entry.key)
      
      # Verifica que não existe mais
      assert {:ok, false} = Cache.exists?(entry.key)
    end
    
    test "clear operation" do
      # Insere múltiplas entradas no cache
      entries = build_list(3, :cache_entry)
      
      Enum.each(entries, fn entry ->
        Cache.put(entry.key, entry.value, entry.ttl)
      end)
      
      # Verifica que todas existem
      Enum.each(entries, fn entry ->
        assert {:ok, true} = Cache.exists?(entry.key)
      end)
      
      # Limpa o cache
      {:ok, result} = Cache.clear()
      # O resultado é o número de chaves removidas
      assert is_integer(result)
      
      # Verifica que nenhuma existe mais
      Enum.each(entries, fn entry ->
        assert {:ok, false} = Cache.exists?(entry.key)
      end)
    end
    
    test "fetch operation with cache miss" do
      key = "fetch_test_key"
      value = %{data: "fetched_data"}
      
      # Define uma função para gerar o valor
      fetch_fun = fn -> value end
      
      # Fetch deve executar a função e armazenar o resultado
      {:ok, fetched_value} = Cache.fetch(key, fetch_fun)
      assert fetched_value == value
      
      # Agora deve estar no cache
      assert {:ok, true} = Cache.exists?(key)
      {:ok, cached_value} = Cache.get(key)
      assert cached_value == value
    end
    
    test "fetch operation with cache hit" do
      key = "fetch_test_key"
      value = %{data: "original_data"}
      new_value = %{data: "new_data"}
      
      # Insere no cache
      {:ok, true} = Cache.put(key, value)
      
      # Define uma função que não deve ser chamada
      fetch_fun = fn -> new_value end
      
      # Fetch deve retornar o valor do cache sem chamar a função
      {:ok, fetched_value} = Cache.fetch(key, fetch_fun)
      assert fetched_value == value
      
      # Valor não deve ter mudado
      {:ok, cached_value} = Cache.get(key)
      assert cached_value == value
      refute cached_value == new_value
    end
  end
  
  describe "cache statistics" do
    test "stats returns basic cache information" do
      # Insere algumas entradas no cache
      entries = build_list(3, :cache_entry)
      
      Enum.each(entries, fn entry ->
        Cache.put(entry.key, entry.value, entry.ttl)
      end)
      
      # Obtém estatísticas
      {:ok, stats} = Cache.stats()
      
      # Verifica se as estatísticas contêm informações básicas
      assert is_map(stats)
      assert Map.has_key?(stats, :size)
      assert stats.size >= 3
    end
  end
end
