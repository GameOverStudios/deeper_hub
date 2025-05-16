defmodule Deeper_Hub.Core.Metrics.MetricsFacade do
  @moduledoc """
  Fachada para o sistema de métricas do Deeper_Hub.

  Este módulo fornece uma interface simplificada para registrar métricas em toda a aplicação,
  abstraindo a implementação específica do sistema de métricas utilizado.

  ## Funcionalidades

  * 📊 Contadores para eventos e operações
  * 📏 Medidores para valores numéricos
  * ⏱️ Histogramas para distribuições de valores
  * 🔄 Medição de duração de operações
  """

  alias Deeper_Hub.Core.Logger

  @doc """
  Incrementa um contador.

  ## Parâmetros

    - `name`: Nome da métrica
    - `tags`: Tags para categorizar a métrica (opcional)
    - `value`: Valor a incrementar (padrão: 1)

  ## Exemplo

  ```elixir
  MetricsFacade.increment("deeper_hub.api.requests", %{endpoint: "/users", method: "GET"})
  ```
  """
  @spec increment(String.t(), map(), number()) :: :ok
  def increment(name, tags \\ %{}, value \\ 1) do
    Logger.debug("Incrementando métrica", %{
      module: __MODULE__,
      metric_name: name,
      metric_type: :counter,
      tags: tags,
      value: value
    })

    # Aqui seria a chamada para o sistema de métricas real
    # Por exemplo: StatsD, Prometheus, Telemetry, etc.

    # Emite evento de telemetria para que outros sistemas possam capturar
    :telemetry.execute(
      [:deeper_hub, :metrics, :counter],
      %{value: value},
      %{name: name, tags: tags}
    )

    :ok
  end

  @doc """
  Define o valor de um medidor (gauge).

  ## Parâmetros

    - `name`: Nome da métrica
    - `value`: Valor do medidor
    - `tags`: Tags para categorizar a métrica (opcional)

  ## Exemplo

  ```elixir
  MetricsFacade.gauge("deeper_hub.connections.active", 42, %{pool: "db"})
  ```
  """
  @spec gauge(String.t(), number(), map()) :: :ok
  def gauge(name, value, tags \\ %{}) do
    Logger.debug("Definindo valor de medidor", %{
      module: __MODULE__,
      metric_name: name,
      metric_type: :gauge,
      tags: tags,
      value: value
    })

    # Aqui seria a chamada para o sistema de métricas real

    # Emite evento de telemetria
    :telemetry.execute(
      [:deeper_hub, :metrics, :gauge],
      %{value: value},
      %{name: name, tags: tags}
    )

    :ok
  end

  @doc """
  Registra um valor em um histograma.

  ## Parâmetros

    - `name`: Nome da métrica
    - `value`: Valor a ser registrado
    - `tags`: Tags para categorizar a métrica (opcional)

  ## Exemplo

  ```elixir
  MetricsFacade.histogram("deeper_hub.api.response_time_ms", 42, %{endpoint: "/users"})
  ```
  """
  @spec histogram(String.t(), number(), map()) :: :ok
  def histogram(name, value, tags \\ %{}) do
    Logger.debug("Registrando valor em histograma", %{
      module: __MODULE__,
      metric_name: name,
      metric_type: :histogram,
      tags: tags,
      value: value
    })

    # Aqui seria a chamada para o sistema de métricas real

    # Emite evento de telemetria
    :telemetry.execute(
      [:deeper_hub, :metrics, :histogram],
      %{value: value},
      %{name: name, tags: tags}
    )

    :ok
  end

  @doc """
  Mede a duração de uma função.

  ## Parâmetros

    - `name`: Nome da métrica
    - `fun`: Função a ser medida
    - `tags`: Tags para categorizar a métrica (opcional)

  ## Retorno

    - Resultado da função `fun`

  ## Exemplo

  ```elixir
  result = MetricsFacade.measure("deeper_hub.db.query_time_ms", fn ->
    Repo.all(User)
  end, %{table: "users"})
  ```
  """
  @spec measure(String.t(), function(), map()) :: any()
  def measure(name, fun, tags \\ %{}) do
    start_time = System.monotonic_time(:millisecond)

    # Executa a função
    result = fun.()

    # Calcula a duração
    duration_ms = System.monotonic_time(:millisecond) - start_time

    # Registra a duração no histograma
    histogram("#{name}", duration_ms, tags)

    # Retorna o resultado da função
    result
  end

  @doc """
  Executa uma função dentro de um span de telemetria.

  ## Parâmetros

    - `name`: Nome do span
    - `meta`: Metadados para o span
    - `fun`: Função a ser executada

  ## Retorno

    - Resultado da função `fun`

  ## Exemplo

  ```elixir
  result = MetricsFacade.span("deeper_hub.api.request", %{endpoint: "/users"}, fn ->
    # Código a ser executado dentro do span
    {:ok, fetch_users()}
  end)
  ```
  """
  @spec span(String.t() | [atom()], map(), function()) :: any()
  def span(name, meta \\ %{}, fun) do
    # Converte string para lista de atoms se necessário
    event = if is_binary(name) do
      name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    else
      name
    end

    # Executa o span de telemetria
    :telemetry.span(event, meta, fn ->
      # Executa a função
      result = fun.()

      # Retorna o resultado e metadados adicionais
      {result, Map.merge(meta, %{result: result})}
    end)
  end
end
