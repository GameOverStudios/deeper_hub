defmodule Deeper_Hub.Core.CircuitBreaker.CacheIntegrationTest do
  @moduledoc """
  Testes para o módulo CacheIntegration que integra CircuitBreaker com Cache.
  """
  
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.CircuitBreaker.CacheIntegration
  alias Deeper_Hub.Core.CircuitBreaker.CircuitBreakerFacade, as: CB
  alias Deeper_Hub.Core.Cache.CacheFacade, as: Cache
  
  # Constantes para os testes
  @service_name :test_service
  @cache_name :test_cache
  @operation_name "test_operation"
  
  setup do
    # Inicializa o cache para testes
    Cache.start_cache(@cache_name)
    
    # Limpa o cache antes de cada teste
    Cache.clear(@cache_name)
    
    # Registra um circuit breaker para testes
    CB.register(@service_name, %{
      failure_threshold: 2,
      reset_timeout_ms: 1000
    })
    
    # Reseta o circuit breaker antes de cada teste
    CB.reset(@service_name)
    
    :ok
  end
  
  describe "with_cache_fallback/6" do
    test "retorna resultado da operação quando bem-sucedida e armazena no cache" do
      cache_key = "test_key_1"
      test_value = %{id: 1, name: "Test User"}
      
      # Executa a operação com fallback para cache
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:ok, test_value} end,
        @cache_name
      )
      
      # Verifica se o resultado está correto
      assert result == {:ok, test_value, :origin}
      
      # Verifica se o valor foi armazenado no cache
      assert {:ok, ^test_value} = Cache.get(@cache_name, cache_key)
    end
    
    test "usa o cache como fallback quando a operação falha" do
      cache_key = "test_key_2"
      test_value = %{id: 2, name: "Cached User"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, test_value)
      
      # Executa a operação com fallback para cache, mas a operação falha
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:error, :service_unavailable} end,
        @cache_name
      )
      
      # Verifica se o resultado veio do cache
      assert result == {:ok, test_value, :cache}
    end
    
    test "retorna erro quando a operação falha e não há valor em cache" do
      cache_key = "test_key_3"
      
      # Executa a operação com fallback para cache, mas a operação falha e não há cache
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:error, :service_unavailable} end,
        @cache_name
      )
      
      # Verifica se o erro foi propagado corretamente
      assert match?({:error, _}, result)
    end
    
    test "usa o cache quando skip_cache_check é false (padrão)" do
      cache_key = "test_key_4"
      test_value = %{id: 4, name: "Cached Value"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, test_value)
      
      # A operação não deve ser chamada porque o valor está no cache
      operation_called = false
      
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> 
          # Marca que a operação foi chamada
          operation_called = true
          {:ok, %{id: 4, name: "New Value"}}
        end,
        @cache_name
      )
      
      # Verifica se o resultado veio do cache
      assert result == {:ok, test_value, :cache}
      
      # Verifica que a operação não foi chamada
      refute operation_called
    end
    
    test "ignora o cache quando skip_cache_check é true" do
      cache_key = "test_key_5"
      cached_value = %{id: 5, name: "Cached Value"}
      new_value = %{id: 5, name: "New Value"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, cached_value)
      
      # Executa a operação ignorando o cache
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:ok, new_value} end,
        @cache_name,
        [skip_cache_check: true]
      )
      
      # Verifica se o resultado veio da operação
      assert result == {:ok, new_value, :origin}
      
      # Verifica se o cache foi atualizado
      assert {:ok, ^new_value} = Cache.get(@cache_name, cache_key)
    end
    
    test "força atualização do cache quando force_refresh é true" do
      cache_key = "test_key_6"
      cached_value = %{id: 6, name: "Cached Value"}
      new_value = %{id: 6, name: "New Value"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, cached_value)
      
      # Executa a operação forçando atualização
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:ok, new_value} end,
        @cache_name,
        [force_refresh: true]
      )
      
      # Verifica se o resultado veio da operação
      assert result == {:ok, new_value, :origin}
      
      # Verifica se o cache foi atualizado
      assert {:ok, ^new_value} = Cache.get(@cache_name, cache_key)
    end
    
    test "usa o circuit breaker para proteger a operação" do
      cache_key = "test_key_7"
      
      # Faz a operação falhar várias vezes para abrir o circuito
      for _ <- 1..3 do
        CacheIntegration.with_cache_fallback(
          @service_name,
          @operation_name,
          cache_key,
          fn -> {:error, :service_unavailable} end,
          @cache_name
        )
      end
      
      # Verifica se o circuito está aberto
      assert {:ok, :open} = CB.state(@service_name)
      
      # Armazena um valor no cache para ser usado como fallback
      test_value = %{id: 7, name: "Fallback Value"}
      Cache.put(@cache_name, cache_key, test_value)
      
      # Executa a operação com o circuito aberto
      result = CacheIntegration.with_cache_fallback(
        @service_name,
        @operation_name,
        cache_key,
        fn -> 
          # Esta função não deve ser chamada porque o circuito está aberto
          flunk("A operação não deveria ser chamada com o circuito aberto")
        end,
        @cache_name
      )
      
      # Verifica se o resultado veio do cache
      assert result == {:ok, test_value, :cache}
    end
  end
  
  describe "with_cache_fallback_transform/7" do
    test "transforma o resultado antes de armazenar no cache" do
      cache_key = "transform_key"
      original_value = %{id: 8, name: "Original", sensitive: "secret"}
      transformed_value = %{id: 8, name: "Original"}
      
      # Define a função de transformação
      transform_fun = fn {:ok, value} -> 
        {:ok, Map.drop(value, [:sensitive])}
      end
      
      # Executa a operação com transformação
      result = CacheIntegration.with_cache_fallback_transform(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:ok, original_value} end,
        transform_fun,
        @cache_name
      )
      
      # Verifica se o resultado foi transformado
      assert result == {:ok, transformed_value, :origin}
      
      # Verifica se o valor armazenado no cache foi transformado
      assert {:ok, ^transformed_value} = Cache.get(@cache_name, cache_key)
    end
  end
  
  describe "invalidate_and_refresh/6" do
    test "invalida o cache e força atualização" do
      cache_key = "invalidate_key"
      old_value = %{id: 9, name: "Old Value"}
      new_value = %{id: 9, name: "New Value"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, old_value)
      
      # Verifica se o valor está no cache
      assert {:ok, ^old_value} = Cache.get(@cache_name, cache_key)
      
      # Invalida e atualiza o cache
      result = CacheIntegration.invalidate_and_refresh(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:ok, new_value} end,
        @cache_name
      )
      
      # Verifica se o resultado é o novo valor
      assert result == {:ok, new_value, :origin}
      
      # Verifica se o cache foi atualizado
      assert {:ok, ^new_value} = Cache.get(@cache_name, cache_key)
    end
    
    test "retorna erro quando a operação falha após invalidação" do
      cache_key = "invalidate_error_key"
      old_value = %{id: 10, name: "Old Value"}
      
      # Armazena um valor no cache
      Cache.put(@cache_name, cache_key, old_value)
      
      # Invalida e tenta atualizar, mas a operação falha
      result = CacheIntegration.invalidate_and_refresh(
        @service_name,
        @operation_name,
        cache_key,
        fn -> {:error, :service_unavailable} end,
        @cache_name
      )
      
      # Verifica se o erro foi propagado
      assert match?({:error, _}, result)
      
      # Verifica se o cache foi invalidado
      assert {:ok, nil} = Cache.get(@cache_name, cache_key)
    end
  end
end
