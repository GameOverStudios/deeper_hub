defmodule Deeper_Hub.Core.Metrics.MetricsIntegrationTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  alias Deeper_Hub.Core.Metrics.MetricsIntegration
  alias Deeper_Hub.Core.Data.Repository
  
  setup do
    # Inicializa o sistema de métricas antes de cada teste
    Metrics.initialize()
    # Limpa as métricas antes de cada teste
    Metrics.clear_metrics()
    DatabaseMetrics.clear_metrics()
    :ok
  end
  
  describe "integração de métricas com o Repository" do
    test "registra métricas ao realizar operações no Repository" do
      # Cria uma tabela de teste
      :mnesia.create_schema([node()])
      :mnesia.start()
      :mnesia.create_table(:test_table, [attributes: [:id, :name]])
      
      # Realiza operações no Repository
      Repository.insert(:test_table, {:test_table, 1, "Test"})
      Repository.find(:test_table, 1)
      Repository.update(:test_table, {:test_table, 1, "Updated Test"})
      Repository.all(:test_table)
      Repository.delete(:test_table, 1)
      
      # Verifica se as métricas foram registradas
      metrics = DatabaseMetrics.get_table_metrics(:test_table)
      
      # Verifica métricas de inserção
      assert metrics[:operations][:insert][:count] > 0
      assert metrics[:operations][:insert][:success] > 0
      
      # Verifica métricas de busca
      assert metrics[:operations][:find][:count] > 0
      assert metrics[:operations][:find][:success] > 0
      
      # Verifica métricas de atualização
      assert metrics[:operations][:update][:count] > 0
      assert metrics[:operations][:update][:success] > 0
      
      # Verifica métricas de listagem
      assert metrics[:operations][:all][:count] > 0
      assert metrics[:operations][:all][:success] > 0
      
      # Verifica métricas de exclusão
      assert metrics[:operations][:delete][:count] > 0
      assert metrics[:operations][:delete][:success] > 0
      
      # Limpa a tabela de teste
      :mnesia.delete_table(:test_table)
      :mnesia.stop()
    end
  end
  
  describe "integração de métricas com o Pagination" do
    test "registra métricas ao realizar operações de paginação" do
      # Cria uma lista de teste
      test_list = Enum.to_list(1..100)
      
      # Realiza operações de paginação
      Deeper_Hub.Core.Data.Pagination.paginate_list(test_list, %{page: 1, page_size: 10})
      Deeper_Hub.Core.Data.Pagination.paginate_list(test_list, %{page: 2, page_size: 20})
      
      # Verifica se as métricas foram registradas
      metrics = DatabaseMetrics.get_table_metrics(:pagination)
      
      # Verifica métricas de paginação
      assert metrics[:operations][:paginate_list][:count] == 2
      assert metrics[:operations][:paginate_list][:success] == 2
      
      # Verifica métricas de tamanho de resultado
      assert metrics[:result_sizes][:paginate_list][:count] == 2
      assert metrics[:result_sizes][:paginate_list][:total] == 30 # 10 + 20
    end
  end
  
  describe "integração de métricas com a aplicação" do
    test "inicializa o sistema de métricas" do
      # Inicializa o sistema de métricas com configurações personalizadas
      result = MetricsIntegration.initialize(0, :json, "logs/test_metrics")
      
      # Verifica se a inicialização foi bem-sucedida
      assert result == :ok
      
      # Registra algumas métricas
      Metrics.increment_counter(:test, :counter)
      Metrics.record_value(:test, :value, 42)
      
      # Gera um relatório
      report = MetricsIntegration.generate_report(:map)
      
      # Verifica se o relatório contém as métricas registradas
      assert get_in(report, [:general, :test, :counter]) == 1
      assert get_in(report, [:general, :test, :value, :total]) == 42
    end
  end
end
