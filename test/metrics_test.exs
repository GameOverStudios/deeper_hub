defmodule Deeper_Hub.Core.MetricsTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Metrics

  setup do
    # Limpa as métricas antes de cada teste
    Metrics.clear_metrics()
    :ok
  end

  describe "operações básicas de métricas" do
    test "initialize/0 inicializa o sistema de métricas" do
      assert :ok = Metrics.initialize()
    end

    test "record_execution_time/3 registra o tempo de execução" do
      Metrics.record_execution_time(:http, :request_time, 150.5)
      
      metrics = Metrics.get_metrics(:http)
      assert metrics[:request_time][:count] == 1
      assert metrics[:request_time][:total] == 150.5
      assert metrics[:request_time][:avg] == 150.5
    end

    test "increment_counter/2 incrementa um contador" do
      Metrics.increment_counter(:http, :request_count)
      Metrics.increment_counter(:http, :request_count)
      
      metrics = Metrics.get_metrics(:http)
      assert metrics[:request_count] == 2
    end

    test "record_value/3 registra um valor" do
      Metrics.record_value(:system, :memory_usage, 1024)
      Metrics.record_value(:system, :memory_usage, 2048)
      
      metrics = Metrics.get_metrics(:system)
      assert metrics[:memory_usage][:count] == 2
      assert metrics[:memory_usage][:total] == 3072
      assert metrics[:memory_usage][:avg] == 1536.0
    end

    test "get_metrics/1 retorna métricas de uma categoria" do
      Metrics.increment_counter(:api, :calls)
      Metrics.record_value(:api, :response_time, 200)
      
      metrics = Metrics.get_metrics(:api)
      assert is_map(metrics)
      assert metrics[:calls] == 1
      assert metrics[:response_time][:count] == 1
    end

    test "get_metric_value/2 retorna um valor específico" do
      Metrics.record_value(:cache, :hits, 42)
      
      value = Metrics.get_metric_value(:cache, :hits)
      assert value[:count] == 1
      assert value[:total] == 42
    end

    test "clear_metrics/0 limpa todas as métricas" do
      Metrics.increment_counter(:test, :counter)
      Metrics.record_value(:test, :value, 100)
      
      Metrics.clear_metrics()
      
      assert Metrics.get_metrics(:test) == %{}
    end

    test "export_metrics/1 exporta métricas para diferentes formatos" do
      Metrics.increment_counter(:export, :test)
      
      json = Metrics.export_metrics(:json)
      assert is_binary(json)
      assert String.contains?(json, "export")
      
      csv = Metrics.export_metrics(:csv)
      assert is_binary(csv)
      assert String.contains?(csv, "export")
    end
  end
end
