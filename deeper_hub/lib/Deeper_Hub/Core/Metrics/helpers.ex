defmodule Deeper_Hub.Core.Metrics.Helpers do
  @moduledoc """
  Funções auxiliares para trabalhar com métricas no sistema Deeper_Hub.

  Este módulo fornece funções utilitárias para facilitar a emissão de eventos
  de telemetria, a criação de spans para medir a duração de operações e outras
  funcionalidades relacionadas a métricas.

  ## Funcionalidades

  * ⏱️ Medição simplificada de duração de operações
  * 📊 Emissão de eventos de telemetria com padrões consistentes
  * 🔄 Criação de spans para rastreamento de operações
  * 🏷️ Funções para manipulação de tags e metadados

  ## Exemplo de Uso

  ```elixir
  alias Deeper_Hub.Core.Metrics.Helpers

  # Medir a duração de uma operação
  Helpers.measure("deeper_hub.api.request", fn ->
    # Código da operação a ser medida
    do_something_expensive()
  end)

  # Criar um span para medir uma operação com início e fim
  Helpers.span("deeper_hub.database.query", %{query: "SELECT * FROM users"}, fn ->
    # Código da operação a ser medida
    repo.all(User)
  end)
  ```
  """

  @doc """
  Mede a duração de uma operação e emite um evento de telemetria.

  ## Parâmetros

    * `event_name` - Nome do evento de telemetria
    * `fun` - Função a ser executada e medida
    * `metadata` - Metadados adicionais para o evento (opcional)

  ## Retorno

    * O valor retornado pela função `fun`

  ## Exemplo

  ```elixir
  Helpers.measure("deeper_hub.api.request", fn ->
    # Código da operação a ser medida
    Process.sleep(100)
    :ok
  end)
  ```
  """
  @spec measure(String.t() | [atom()], (-> any()), map()) :: any()
  def measure(event_name, fun, metadata \\ %{}) when is_function(fun, 0) and is_map(metadata) do
    {result, duration} = :timer.tc(fun)

    # Converter o nome do evento para lista de átomos se for uma string
    event_prefix = if is_binary(event_name) do
      event_name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    else
      event_name
    end

    # Emitir o evento de telemetria
    :telemetry.execute(
      event_prefix ++ [:duration],
      %{duration: duration},
      metadata
    )

    result
  end

  @doc """
  Cria um span para medir a duração de uma operação, emitindo eventos de início e fim.

  ## Parâmetros

    * `event_name` - Nome do evento de telemetria
    * `metadata` - Metadados para o evento
    * `fun` - Função a ser executada e medida

  ## Retorno

    * `{result, measurements}` - Resultado da função e medições do span

  ## Exemplo

  ```elixir
  Helpers.span("deeper_hub.database.query", %{query: "SELECT * FROM users"}, fn ->
    # Código da operação a ser medida
    repo.all(User)
  end)
  ```
  """
  @spec span(String.t() | [atom()], map(), (-> any())) :: {any(), map()}
  def span(event_name, metadata \\ %{}, fun) when is_function(fun, 0) and is_map(metadata) do
    # Converter o nome do evento para lista de átomos se for uma string
    event_prefix = if is_binary(event_name) do
      event_name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    else
      event_name
    end

    # Usar a função span do telemetry
    :telemetry.span(event_prefix, metadata, fun)
  end

  @doc """
  Emite um evento de contador, incrementando o valor.

  ## Parâmetros

    * `event_name` - Nome do evento de telemetria
    * `value` - Valor a ser incrementado (padrão: 1)
    * `metadata` - Metadados adicionais para o evento (opcional)

  ## Retorno

    * `:ok`

  ## Exemplo

  ```elixir
  Helpers.count("deeper_hub.api.request.count", 1, %{endpoint: "/users", method: "GET"})
  ```
  """
  @spec count(String.t() | [atom()], number(), map()) :: :ok
  def count(event_name, value \\ 1, metadata \\ %{}) when is_number(value) and is_map(metadata) do
    # Converter o nome do evento para lista de átomos se for uma string
    event_prefix = if is_binary(event_name) do
      event_name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    else
      event_name
    end

    # Emitir o evento de telemetria
    :telemetry.execute(
      event_prefix,
      %{count: value},
      metadata
    )
  end

  @doc """
  Emite um evento com um valor específico.

  ## Parâmetros

    * `event_name` - Nome do evento de telemetria
    * `key` - Chave para o valor na medição
    * `value` - Valor a ser registrado
    * `metadata` - Metadados adicionais para o evento (opcional)

  ## Retorno

    * `:ok`

  ## Exemplo

  ```elixir
  Helpers.record("deeper_hub.cache.size", :size, 42, %{cache_name: "user_cache"})
  ```
  """
  @spec record(String.t() | [atom()], atom(), any(), map()) :: :ok
  def record(event_name, key, value, metadata \\ %{}) when is_atom(key) and is_map(metadata) do
    # Converter o nome do evento para lista de átomos se for uma string
    event_prefix = if is_binary(event_name) do
      event_name
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)
    else
      event_name
    end

    # Emitir o evento de telemetria
    :telemetry.execute(
      event_prefix,
      %{key => value},
      metadata
    )
  end

  @doc """
  Adiciona tags padrão aos metadados.

  ## Parâmetros

    * `metadata` - Metadados originais
    * `default_tags` - Tags padrão a serem adicionadas

  ## Retorno

    * Metadados combinados

  ## Exemplo

  ```elixir
  metadata = %{endpoint: "/users"}
  default_tags = %{environment: "production", service: "api"}

  Helpers.with_default_tags(metadata, default_tags)
  # => %{endpoint: "/users", environment: "production", service: "api"}
  ```
  """
  @spec with_default_tags(map(), map()) :: map()
  def with_default_tags(metadata, default_tags) when is_map(metadata) and is_map(default_tags) do
    Map.merge(default_tags, metadata)
  end
end
