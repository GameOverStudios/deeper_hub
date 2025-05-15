defmodule Deeper_Hub.Core.Data.RepositoryCacheTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryCache
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  
  # Define um schema de teste
  defmodule TestSchema do
  end
  
  # Configura o ambiente de teste
  setup do
    # Limpa os namespaces de cache antes de cada teste
    Cache.create_namespace("repository:TestSchema:records", ttl: 300_000, max_size: 1000)
    Cache.create_namespace("repository:TestSchema:queries", ttl: 300_000, max_size: 1000)
    Cache.clear_namespace("repository:TestSchema:records")
    Cache.clear_namespace("repository:TestSchema:queries")
    
    :ok
  end
  
  describe "setup/1" do
    test "inicializa o cache para os schemas fornecidos" do
      # Executa a função de setup
      RepositoryCache.setup([TestSchema])
      
      # Verifica se os namespaces foram criados
      assert Cache.namespace_exists?("repository:TestSchema:records")
      assert Cache.namespace_exists?("repository:TestSchema:queries")
    end
  end
  
  describe "get_record/2 e put_record/3" do
    test "armazena e recupera um registro do cache" do
      # Define um registro de teste
      record = %{id: 123, name: "Test Record"}
      
      # Armazena o registro no cache
      assert :ok = RepositoryCache.put_record(TestSchema, 123, record)
      
      # Recupera o registro do cache
      assert {:ok, ^record} = RepositoryCache.get_record(TestSchema, 123)
    end
    
    test "retorna erro quando o registro não está no cache" do
      # Tenta recuperar um registro que não existe
      assert {:error, :not_found} = RepositoryCache.get_record(TestSchema, 456)
    end
  end
  
  describe "get_query_results/2 e put_query_results/3" do
    test "armazena e recupera resultados de consulta do cache" do
      # Define resultados de teste
      results = [%{id: 1, name: "Record 1"}, %{id: 2, name: "Record 2"}]
      
      # Gera uma chave de consulta
      query_key = RepositoryCache.generate_query_key(%{status: "active"}, limit: 10)
      
      # Armazena os resultados no cache
      assert :ok = RepositoryCache.put_query_results(TestSchema, query_key, results)
      
      # Recupera os resultados do cache
      assert {:ok, ^results} = RepositoryCache.get_query_results(TestSchema, query_key)
    end
    
    test "retorna erro quando os resultados não estão no cache" do
      # Gera uma chave de consulta
      query_key = RepositoryCache.generate_query_key(%{status: "inactive"}, limit: 20)
      
      # Tenta recuperar resultados que não existem
      assert {:error, :not_found} = RepositoryCache.get_query_results(TestSchema, query_key)
    end
  end
  
  describe "invalidate_record/2" do
    test "invalida o cache para um registro específico" do
      # Define um registro de teste
      record = %{id: 123, name: "Test Record"}
      
      # Armazena o registro no cache
      :ok = RepositoryCache.put_record(TestSchema, 123, record)
      
      # Verifica se o registro está no cache
      assert {:ok, ^record} = RepositoryCache.get_record(TestSchema, 123)
      
      # Invalida o cache para o registro
      :ok = RepositoryCache.invalidate_record(TestSchema, 123)
      
      # Verifica se o registro foi removido do cache
      assert {:error, :not_found} = RepositoryCache.get_record(TestSchema, 123)
    end
  end
  
  describe "invalidate_schema/1" do
    test "invalida todo o cache para um schema específico" do
      # Define registros de teste
      record1 = %{id: 123, name: "Test Record 1"}
      record2 = %{id: 456, name: "Test Record 2"}
      
      # Armazena os registros no cache
      :ok = RepositoryCache.put_record(TestSchema, 123, record1)
      :ok = RepositoryCache.put_record(TestSchema, 456, record2)
      
      # Gera uma chave de consulta e armazena resultados
      query_key = RepositoryCache.generate_query_key(%{status: "active"}, limit: 10)
      :ok = RepositoryCache.put_query_results(TestSchema, query_key, [record1, record2])
      
      # Verifica se os registros e resultados estão no cache
      assert {:ok, ^record1} = RepositoryCache.get_record(TestSchema, 123)
      assert {:ok, ^record2} = RepositoryCache.get_record(TestSchema, 456)
      assert {:ok, [^record1, ^record2]} = RepositoryCache.get_query_results(TestSchema, query_key)
      
      # Invalida todo o cache para o schema
      :ok = RepositoryCache.invalidate_schema(TestSchema)
      
      # Verifica se todos os registros e resultados foram removidos do cache
      assert {:error, :not_found} = RepositoryCache.get_record(TestSchema, 123)
      assert {:error, :not_found} = RepositoryCache.get_record(TestSchema, 456)
      assert {:error, :not_found} = RepositoryCache.get_query_results(TestSchema, query_key)
    end
  end
  
  describe "generate_query_key/2" do
    test "gera chaves consistentes para as mesmas condições e opções" do
      # Define condições e opções
      conditions = %{status: "active", category: "product"}
      opts = [limit: 10, order_by: :name]
      
      # Gera a chave duas vezes
      key1 = RepositoryCache.generate_query_key(conditions, opts)
      key2 = RepositoryCache.generate_query_key(conditions, opts)
      
      # Verifica se as chaves são iguais
      assert key1 == key2
      assert is_binary(key1)
      assert String.length(key1) > 0
    end
    
    test "gera chaves diferentes para condições ou opções diferentes" do
      # Define condições e opções base
      base_conditions = %{status: "active"}
      base_opts = [limit: 10]
      
      # Gera a chave base
      base_key = RepositoryCache.generate_query_key(base_conditions, base_opts)
      
      # Gera chaves com condições diferentes
      different_conditions_key = RepositoryCache.generate_query_key(
        Map.put(base_conditions, :category, "product"), 
        base_opts
      )
      
      # Gera chaves com opções diferentes
      different_opts_key = RepositoryCache.generate_query_key(
        base_conditions, 
        Keyword.put(base_opts, :order_by, :name)
      )
      
      # Verifica se as chaves são diferentes
      assert base_key != different_conditions_key
      assert base_key != different_opts_key
      assert different_conditions_key != different_opts_key
    end
  end
end
