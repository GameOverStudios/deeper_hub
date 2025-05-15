defmodule Deeper_Hub.Core.Data.ResilientRepositoryTest do
  @moduledoc """
  Testes para o módulo ResilientRepository que integra CircuitBreaker e Cache com o Repository.
  """
  
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.ResilientRepository, as: RRepo
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB
  
  # Definição de um schema de teste para os testes
  defmodule TestUser do
    use Ecto.Schema
    
    schema "users" do
      field :name, :string
      field :email, :string
      
      timestamps()
    end
  end
  
  # Nome do cache para os testes
  @data_cache :data_cache
  
  # Nome do serviço para o CircuitBreaker
  @db_service :database_service
  
  setup do
    # Inicializa o ResilientRepository
    RRepo.init([
      failure_threshold: 2,
      reset_timeout_ms: 1000
    ])
    
    # Limpa o cache antes de cada teste
    Cache.clear(@data_cache)
    
    # Reseta o circuit breaker antes de cada teste
    CB.reset(@db_service)
    
    :ok
  end
  
  describe "get/3" do
    test "retorna o resultado do Repository quando bem-sucedido e armazena no cache" do
      # Mock do resultado do Repository.get
      user = %TestUser{id: 1, name: "Test User", email: "test@example.com"}
      
      # Stub para Repository.get
      expect_repository_get(TestUser, 1, {:ok, user})
      
      # Executa a operação
      result = RRepo.get(TestUser, 1)
      
      # Verifica se o resultado está correto
      assert result == {:ok, user}
      
      # Verifica se o valor foi armazenado no cache
      cache_key = "#{TestUser}_1"
      assert {:ok, ^user} = Cache.get(@data_cache, cache_key)
    end
    
    test "usa o cache como fallback quando o Repository falha" do
      # Valor a ser armazenado no cache
      user = %TestUser{id: 2, name: "Cached User", email: "cached@example.com"}
      
      # Armazena o valor no cache
      cache_key = "#{TestUser}_2"
      Cache.put(@data_cache, cache_key, user)
      
      # Stub para Repository.get que falha
      expect_repository_get(TestUser, 2, {:error, :database_error})
      
      # Executa a operação
      result = RRepo.get(TestUser, 2)
      
      # Verifica se o resultado veio do cache
      assert result == {:ok, user}
    end
    
    test "força atualização do cache quando force_refresh é true" do
      # Valor inicial no cache
      cached_user = %TestUser{id: 3, name: "Old User", email: "old@example.com"}
      
      # Novo valor do banco de dados
      db_user = %TestUser{id: 3, name: "New User", email: "new@example.com"}
      
      # Armazena o valor inicial no cache
      cache_key = "#{TestUser}_3"
      Cache.put(@data_cache, cache_key, cached_user)
      
      # Stub para Repository.get
      expect_repository_get(TestUser, 3, {:ok, db_user})
      
      # Executa a operação com force_refresh
      result = RRepo.get(TestUser, 3, [force_refresh: true])
      
      # Verifica se o resultado veio do banco de dados
      assert result == {:ok, db_user}
      
      # Verifica se o cache foi atualizado
      assert {:ok, ^db_user} = Cache.get(@data_cache, cache_key)
    end
  end
  
  describe "list/3" do
    test "retorna o resultado do Repository quando bem-sucedido e armazena no cache" do
      # Mock do resultado do Repository.list
      users = [
        %TestUser{id: 1, name: "User 1", email: "user1@example.com"},
        %TestUser{id: 2, name: "User 2", email: "user2@example.com"}
      ]
      
      # Filtros para o teste
      filters = [active: true]
      
      # Stub para Repository.list
      expect_repository_list(TestUser, filters, {:ok, users})
      
      # Executa a operação
      result = RRepo.list(TestUser, filters)
      
      # Verifica se o resultado está correto
      assert result == {:ok, users}
      
      # Verifica se o valor foi armazenado no cache
      filters_hash = :erlang.phash2(filters)
      pagination_hash = :erlang.phash2([])
      cache_key = "#{TestUser}_list_#{filters_hash}_#{pagination_hash}"
      assert {:ok, ^users} = Cache.get(@data_cache, cache_key)
    end
  end
  
  describe "insert/3" do
    test "insere um registro com proteção de CircuitBreaker" do
      # Atributos para o novo registro
      attrs = %{name: "New User", email: "new@example.com"}
      
      # Resultado esperado
      inserted_user = %TestUser{id: 4, name: "New User", email: "new@example.com"}
      
      # Stub para Repository.insert
      expect_repository_insert(TestUser, attrs, {:ok, inserted_user})
      
      # Executa a operação
      result = RRepo.insert(TestUser, attrs)
      
      # Verifica se o resultado está correto
      assert result == {:ok, inserted_user}
    end
    
    test "tenta novamente após falha temporária" do
      # Atributos para o novo registro
      attrs = %{name: "Retry User", email: "retry@example.com"}
      
      # Resultado esperado após retry
      inserted_user = %TestUser{id: 5, name: "Retry User", email: "retry@example.com"}
      
      # Stub para Repository.insert que falha na primeira tentativa e depois sucede
      expect_repository_insert_with_retry(TestUser, attrs, {:ok, inserted_user})
      
      # Executa a operação
      result = RRepo.insert(TestUser, attrs)
      
      # Verifica se o resultado está correto após retry
      assert result == {:ok, inserted_user}
    end
  end
  
  describe "update/3" do
    test "atualiza um registro e invalida o cache" do
      # Registro a ser atualizado
      user = %TestUser{id: 6, name: "Old Name", email: "old@example.com"}
      
      # Novos atributos
      attrs = %{name: "New Name"}
      
      # Resultado esperado
      updated_user = %TestUser{id: 6, name: "New Name", email: "old@example.com"}
      
      # Armazena o valor inicial no cache
      cache_key = "#{TestUser}_6"
      Cache.put(@data_cache, cache_key, user)
      
      # Stub para Repository.update
      expect_repository_update(user, attrs, {:ok, updated_user})
      
      # Executa a operação
      result = RRepo.update(user, attrs)
      
      # Verifica se o resultado está correto
      assert result == {:ok, updated_user}
      
      # Verifica se o cache foi invalidado
      assert {:ok, nil} = Cache.get(@data_cache, cache_key)
    end
  end
  
  describe "delete/2" do
    test "deleta um registro e invalida o cache" do
      # Registro a ser deletado
      user = %TestUser{id: 7, name: "Delete User", email: "delete@example.com"}
      
      # Armazena o valor inicial no cache
      cache_key = "#{TestUser}_7"
      Cache.put(@data_cache, cache_key, user)
      
      # Stub para Repository.delete
      expect_repository_delete(user, {:ok, user})
      
      # Executa a operação
      result = RRepo.delete(user)
      
      # Verifica se o resultado está correto
      assert result == {:ok, user}
      
      # Verifica se o cache foi invalidado
      assert {:ok, nil} = Cache.get(@data_cache, cache_key)
    end
  end
  
  # Funções auxiliares para stub do Repository
  
  defp expect_repository_get(schema, id, result) do
    # Define a expectativa para Repository.get
    :meck.expect(Repository, :get, fn s, i ->
      assert s == schema
      assert i == id
      result
    end)
  end
  
  defp expect_repository_list(schema, filters, result) do
    # Define a expectativa para Repository.list
    :meck.expect(Repository, :list, fn s, f ->
      assert s == schema
      assert Keyword.equal?(f, filters) or Enum.all?(filters, fn {k, v} -> Keyword.get(f, k) == v end)
      result
    end)
  end
  
  defp expect_repository_insert(schema, attrs, result) do
    # Define a expectativa para Repository.insert
    :meck.expect(Repository, :insert, fn s, a ->
      assert s == schema
      assert a == attrs
      result
    end)
  end
  
  defp expect_repository_insert_with_retry(schema, attrs, final_result) do
    # Contador para controlar o número de chamadas
    counter = :counters.new(1, [])
    
    # Define a expectativa para Repository.insert que falha na primeira tentativa
    :meck.expect(Repository, :insert, fn s, a ->
      assert s == schema
      assert a == attrs
      
      # Incrementa o contador
      :counters.add(counter, 1, 1)
      count = :counters.get(counter, 1)
      
      if count == 1 do
        # Primeira chamada, retorna erro
        {:error, :temporary_failure}
      else
        # Segunda chamada, retorna sucesso
        final_result
      end
    end)
  end
  
  defp expect_repository_update(struct, attrs, result) do
    # Define a expectativa para Repository.update
    :meck.expect(Repository, :update, fn s, a ->
      assert s == struct
      assert a == attrs
      result
    end)
  end
  
  defp expect_repository_delete(struct, result) do
    # Define a expectativa para Repository.delete
    :meck.expect(Repository, :delete, fn s ->
      assert s == struct
      result
    end)
  end
  
  setup_all do
    # Inicia o mock para Repository
    :meck.new(Repository, [:passthrough])
    
    on_exit(fn ->
      # Limpa os mocks após todos os testes
      :meck.unload()
    end)
    
    :ok
  end
end
