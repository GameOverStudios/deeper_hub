defmodule Deeper_Hub.Core.Data.RepositoryTelemetryTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryTelemetry
  
  # Configuração para capturar eventos de telemetria durante os testes
  setup do
    # Armazena eventos capturados
    test_pid = self()
    
    # Configura handler temporário para capturar eventos
    :telemetry.attach_many(
      "repository_telemetry_test_handler",
      [
        [:deeper_hub, :core, :data, :repository, :get],
        [:deeper_hub, :core, :data, :repository, :insert],
        [:deeper_hub, :core, :data, :repository, :update],
        [:deeper_hub, :core, :data, :repository, :delete],
        [:deeper_hub, :core, :data, :repository, :list],
        [:deeper_hub, :core, :data, :repository, :find]
      ],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )
    
    # Limpa o handler após os testes
    on_exit(fn ->
      :telemetry.detach("repository_telemetry_test_handler")
    end)
    
    :ok
  end
  
  describe "setup/0" do
    test "configura handlers de telemetria para todos os eventos de repositório" do
      # Executa a função de setup
      RepositoryTelemetry.setup()
      
      # Verifica se o handler foi registrado
      handlers = :telemetry.list_handlers([])
      
      # Verifica se o handler do módulo está presente
      assert Enum.any?(handlers, fn handler ->
        handler.id == {RepositoryTelemetry, :repository_handler}
      end)
      
      # Verifica se todos os eventos estão cobertos
      events_covered = handlers
                       |> Enum.filter(fn handler -> 
                         handler.id == {RepositoryTelemetry, :repository_handler} 
                       end)
                       |> Enum.flat_map(fn handler -> handler.event_names end)
      
      # Lista de eventos esperados
      expected_events = [
        [:deeper_hub, :core, :data, :repository, :get],
        [:deeper_hub, :core, :data, :repository, :insert],
        [:deeper_hub, :core, :data, :repository, :update],
        [:deeper_hub, :core, :data, :repository, :delete],
        [:deeper_hub, :core, :data, :repository, :list],
        [:deeper_hub, :core, :data, :repository, :find],
        [:deeper_hub, :core, :data, :repository, :join_inner],
        [:deeper_hub, :core, :data, :repository, :join_left],
        [:deeper_hub, :core, :data, :repository, :join_right],
        [:deeper_hub, :core, :data, :repository, :transaction]
      ]
      
      # Verifica se todos os eventos esperados estão cobertos
      Enum.each(expected_events, fn event ->
        assert event in events_covered, "Evento #{inspect(event)} não está coberto"
      end)
    end
  end
  
  describe "span/3" do
    test "executa função dentro de um span de telemetria" do
      schema = TestSchema
      event = [:deeper_hub, :core, :data, :repository, :get]
      metadata = %{schema: schema, id: 123}
      
      # Executa a função dentro de um span
      result = RepositoryTelemetry.span(event, metadata, fn ->
        {:ok, %{id: 123, name: "Test"}}
      end)
      
      # Verifica o resultado
      assert result == {:ok, %{id: 123, name: "Test"}}
      
      # Verifica se o evento foi emitido
      assert_receive {:telemetry_event, ^event, measurements, received_metadata}
      
      # Verifica se as medições incluem a duração
      assert is_integer(measurements.duration)
      
      # Verifica se os metadados foram passados corretamente
      assert received_metadata.schema == schema
      assert received_metadata.id == 123
      assert received_metadata.result == :success
    end
    
    test "trata erros dentro do span" do
      schema = TestSchema
      event = [:deeper_hub, :core, :data, :repository, :get]
      metadata = %{schema: schema, id: 123}
      
      # Executa a função que retorna erro dentro de um span
      result = RepositoryTelemetry.span(event, metadata, fn ->
        {:error, :not_found}
      end)
      
      # Verifica o resultado
      assert result == {:error, :not_found}
      
      # Verifica se o evento foi emitido
      assert_receive {:telemetry_event, ^event, measurements, received_metadata}
      
      # Verifica se as medições incluem a duração
      assert is_integer(measurements.duration)
      
      # Verifica se os metadados foram passados corretamente
      assert received_metadata.schema == schema
      assert received_metadata.id == 123
      assert received_metadata.result == :not_found
    end
    
    test "sanitiza metadados sensíveis" do
      schema = TestSchema
      event = [:deeper_hub, :core, :data, :repository, :get]
      metadata = %{
        schema: schema, 
        id: 123, 
        password: "secret123", 
        token: "jwt-token",
        large_list: List.duplicate("item", 20),
        large_string: String.duplicate("a", 2000)
      }
      
      # Executa a função dentro de um span
      RepositoryTelemetry.span(event, metadata, fn ->
        {:ok, %{id: 123, name: "Test"}}
      end)
      
      # Verifica se o evento foi emitido
      assert_receive {:telemetry_event, ^event, _measurements, received_metadata}
      
      # Verifica se os dados sensíveis foram removidos
      refute Map.has_key?(received_metadata, :password)
      refute Map.has_key?(received_metadata, :token)
      
      # Verifica se listas grandes foram truncadas
      assert length(received_metadata.large_list) == 11  # 10 itens + mensagem de truncamento
      assert List.last(received_metadata.large_list) =~ "more items"
      
      # Verifica se strings grandes foram truncadas
      assert byte_size(received_metadata.large_string) <= 1050  # 1000 + mensagem de truncamento
      assert String.ends_with?(received_metadata.large_string, "more bytes)")
    end
  end
  
  describe "handle_event/4" do
    test "processa eventos de telemetria corretamente" do
      # Simula um evento de telemetria
      event = [:deeper_hub, :core, :data, :repository, :get]
      measurements = %{duration: 1_000_000}  # 1ms em unidades nativas
      metadata = %{schema: TestSchema, id: 123, result: :success}
      
      # Chama o handler diretamente
      RepositoryTelemetry.handle_event(event, measurements, metadata, nil)
      
      # Como o handler apenas registra logs e métricas, não há como verificar
      # diretamente seu comportamento sem mockar essas dependências.
      # Em um teste real, você poderia usar mocks para verificar se as funções
      # de log e métricas foram chamadas corretamente.
      
      # Este teste serve principalmente para garantir que o handler não lança exceções
    end
  end
end

# Módulo de schema fictício para testes
defmodule TestSchema do
end
