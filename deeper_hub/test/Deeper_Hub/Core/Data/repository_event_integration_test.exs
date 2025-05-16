defmodule Deeper_Hub.Core.Data.RepositoryEventIntegrationTest do
  use ExUnit.Case, async: false
  
  alias Deeper_Hub.Core.Data.RepositoryEventIntegration
  alias Deeper_Hub.Core.EventBus.EventBusFacade, as: EventBus
  
  # Define um schema de teste
  defmodule TestSchema do
  end
  
  # Configura o ambiente de teste
  setup do
    # Armazena eventos publicados
    test_pid = self()
    
    # Mock do EventBus para capturar eventos publicados
    :meck.new(EventBus, [:passthrough])
    :meck.expect(EventBus, :publish, fn event_type, event_data ->
      send(test_pid, {:event_published, event_type, event_data})
      :ok
    end)
    
    on_exit(fn ->
      :meck.unload(EventBus)
    end)
    
    :ok
  end
  
  describe "publish_record_inserted/3" do
    test "publica evento de inserção de registro" do
      # Define dados de teste
      schema = TestSchema
      id = 123
      record = %{id: id, name: "Test Record"}
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_record_inserted(schema, id, record)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_record_inserted, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.id == id
      assert event_data.record == record
      assert event_data.operation == :insert
      assert %DateTime{} = event_data.timestamp
    end
    
    test "publica evento sem o registro quando não fornecido" do
      # Define dados de teste
      schema = TestSchema
      id = 123
      
      # Publica o evento sem o registro
      assert :ok = RepositoryEventIntegration.publish_record_inserted(schema, id)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_record_inserted, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.id == id
      refute Map.has_key?(event_data, :record)
      assert event_data.operation == :insert
      assert %DateTime{} = event_data.timestamp
    end
  end
  
  describe "publish_record_updated/4" do
    test "publica evento de atualização de registro" do
      # Define dados de teste
      schema = TestSchema
      id = 123
      record = %{id: id, name: "Updated Record"}
      changes = %{name: "Updated Record"}
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_record_updated(schema, id, record, changes)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_record_updated, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.id == id
      assert event_data.record == record
      assert event_data.changes == changes
      assert event_data.operation == :update
      assert %DateTime{} = event_data.timestamp
    end
    
    test "publica evento sem o registro e alterações quando não fornecidos" do
      # Define dados de teste
      schema = TestSchema
      id = 123
      
      # Publica o evento sem o registro e alterações
      assert :ok = RepositoryEventIntegration.publish_record_updated(schema, id)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_record_updated, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.id == id
      refute Map.has_key?(event_data, :record)
      refute Map.has_key?(event_data, :changes)
      assert event_data.operation == :update
      assert %DateTime{} = event_data.timestamp
    end
  end
  
  describe "publish_record_deleted/2" do
    test "publica evento de exclusão de registro" do
      # Define dados de teste
      schema = TestSchema
      id = 123
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_record_deleted(schema, id)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_record_deleted, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.id == id
      assert event_data.operation == :delete
      assert %DateTime{} = event_data.timestamp
    end
  end
  
  describe "publish_query_executed/4" do
    test "publica evento de execução de consulta com todos os parâmetros" do
      # Define dados de teste
      schema = TestSchema
      operation = :list
      params = %{status: "active"}
      result_count = 10
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_query_executed(schema, operation, params, result_count)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_query_executed, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.operation == operation
      assert event_data.params == params
      assert event_data.result_count == result_count
      assert %DateTime{} = event_data.timestamp
    end
    
    test "publica evento de execução de consulta com parâmetros mínimos" do
      # Define dados de teste
      schema = TestSchema
      operation = :find
      
      # Publica o evento com parâmetros mínimos
      assert :ok = RepositoryEventIntegration.publish_query_executed(schema, operation)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_query_executed, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.operation == operation
      refute Map.has_key?(event_data, :params)
      refute Map.has_key?(event_data, :result_count)
      assert %DateTime{} = event_data.timestamp
    end
  end
  
  describe "publish_transaction_completed/3" do
    test "publica evento de conclusão de transação" do
      # Define dados de teste
      transaction_id = "tx-123456"
      schemas = [TestSchema, AnotherTestSchema]
      operations = [:insert, :update]
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_transaction_completed(transaction_id, schemas, operations)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_transaction_completed, event_data}
      
      # Verifica os dados do evento
      assert event_data.transaction_id == transaction_id
      assert event_data.schemas == schemas
      assert event_data.operations == operations
      assert %DateTime{} = event_data.timestamp
    end
  end
  
  describe "publish_repository_error/4" do
    test "publica evento de erro com todos os parâmetros" do
      # Define dados de teste
      schema = TestSchema
      operation = :insert
      error = :database_connection_error
      details = %{message: "Failed to connect to database"}
      
      # Publica o evento
      assert :ok = RepositoryEventIntegration.publish_repository_error(schema, operation, error, details)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_error, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.operation == operation
      assert event_data.error == error
      assert event_data.details == details
      assert %DateTime{} = event_data.timestamp
    end
    
    test "publica evento de erro com parâmetros mínimos" do
      # Define dados de teste
      schema = TestSchema
      operation = :update
      error = :validation_error
      
      # Publica o evento com parâmetros mínimos
      assert :ok = RepositoryEventIntegration.publish_repository_error(schema, operation, error)
      
      # Verifica se o evento foi publicado corretamente
      assert_receive {:event_published, :repository_error, event_data}
      
      # Verifica os dados do evento
      assert event_data.schema == schema
      assert event_data.operation == operation
      assert event_data.error == error
      refute Map.has_key?(event_data, :details)
      assert %DateTime{} = event_data.timestamp
    end
  end
end

# Módulo de schema fictício adicional para testes
defmodule AnotherTestSchema do
end
