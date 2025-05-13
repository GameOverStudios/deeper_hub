defmodule Deeper_Hub.Core.Metrics.DatabaseMetricsTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics

  setup do
    # Inicializa o sistema de métricas antes de cada teste
    alias Deeper_Hub.Core.Metrics
    Metrics.initialize()
    # Limpa as métricas antes de cada teste
    DatabaseMetrics.clear_metrics()
    :ok
  end

  describe "operações de métricas de banco de dados" do
    test "start_operation/2 retorna um timestamp" do
      timestamp = DatabaseMetrics.start_operation(:users, :insert)
      assert is_integer(timestamp)
    end

    test "complete_operation/4 registra uma operação completa" do
      # Inicia uma operação
      timestamp = DatabaseMetrics.start_operation(:users, :insert)
      
      # Completa a operação
      DatabaseMetrics.complete_operation(:users, :insert, :success, timestamp)
      
      # Verifica se a métrica foi registrada
      metrics = DatabaseMetrics.get_table_metrics(:users)
      assert metrics[:operations][:insert][:count] == 1
      assert metrics[:operations][:insert][:success] == 1
      assert metrics[:operations][:insert][:error] == 0
      assert is_integer(metrics[:operations][:insert][:total_time])
      assert is_float(metrics[:operations][:insert][:avg_time])
    end

    test "complete_operation/4 registra operações com erro" do
      # Inicia uma operação
      timestamp = DatabaseMetrics.start_operation(:users, :update)
      
      # Completa a operação com erro
      DatabaseMetrics.complete_operation(:users, :update, :error, timestamp)
      
      # Verifica se a métrica foi registrada corretamente
      metrics = DatabaseMetrics.get_table_metrics(:users)
      assert metrics[:operations][:update][:count] == 1
      assert metrics[:operations][:update][:success] == 0
      assert metrics[:operations][:update][:error] == 1
    end

    test "record_result_size/3 registra o tamanho do resultado" do
      # Registra o tamanho de um resultado
      DatabaseMetrics.record_result_size(:users, :all, 42)
      
      # Verifica se a métrica foi registrada
      metrics = DatabaseMetrics.get_table_metrics(:users)
      assert metrics[:result_sizes][:all][:count] == 1
      assert metrics[:result_sizes][:all][:total] == 42
      assert metrics[:result_sizes][:all][:avg] == 42.0
    end

    test "get_table_metrics/1 retorna métricas de uma tabela específica" do
      # Registra algumas métricas
      timestamp = DatabaseMetrics.start_operation(:users, :find)
      DatabaseMetrics.complete_operation(:users, :find, :success, timestamp)
      DatabaseMetrics.record_result_size(:users, :find, 1)
      
      # Verifica se as métricas são retornadas corretamente
      metrics = DatabaseMetrics.get_table_metrics(:users)
      assert is_map(metrics)
      assert metrics[:operations][:find][:count] == 1
      assert metrics[:result_sizes][:find][:total] == 1
    end

    test "get_operation_metrics/0 retorna métricas de todas as operações" do
      # Registra métricas para diferentes tabelas
      timestamp1 = DatabaseMetrics.start_operation(:users, :insert)
      DatabaseMetrics.complete_operation(:users, :insert, :success, timestamp1)
      
      timestamp2 = DatabaseMetrics.start_operation(:posts, :update)
      DatabaseMetrics.complete_operation(:posts, :update, :error, timestamp2)
      
      # Verifica se as métricas são retornadas corretamente
      metrics = DatabaseMetrics.get_operation_metrics()
      assert is_map(metrics)
      assert metrics[:users][:insert][:count] == 1
      assert metrics[:posts][:update][:count] == 1
    end

    test "clear_metrics/0 limpa todas as métricas" do
      # Registra algumas métricas
      timestamp = DatabaseMetrics.start_operation(:users, :delete)
      DatabaseMetrics.complete_operation(:users, :delete, :success, timestamp)
      
      # Limpa as métricas
      DatabaseMetrics.clear_metrics()
      
      # Verifica se as métricas foram limpas
      metrics = DatabaseMetrics.get_table_metrics(:users)
      assert metrics[:operations] == %{}
      assert metrics[:result_sizes] == %{}
    end
  end
end
