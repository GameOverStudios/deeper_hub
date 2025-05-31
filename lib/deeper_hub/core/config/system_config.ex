defmodule DeeperHub.Core.Config.SystemConfig do
  @moduledoc """
  Configuração centralizada para todos os módulos do sistema DeeperHub.

  Este módulo centraliza as configurações de Cache, Telemetry, Database e outros
  subsistemas, permitindo fácil manutenção e consistência entre ambientes.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @doc """
  Obtém a configuração completa do sistema baseada no ambiente atual.

  ## Retorno

  Um mapa com todas as configurações organizadas por subsistema:
  - `:cache` - Configurações do sistema de cache
  - `:telemetry` - Configurações do sistema de telemetria
  - `:database` - Configurações do banco de dados
  - `:supervisor` - Configurações dos supervisors
  """
  @spec get_system_config() :: map()
  def get_system_config do
    environment = get_environment()

    %{
      environment: environment,
      cache: get_cache_config(environment),
      telemetry: get_telemetry_config(environment),
      database: get_database_config(environment),
      supervisor: get_supervisor_config(environment)
    }
  end

  @doc """
  Obtém configurações específicas do sistema de cache.
  """
  @spec get_cache_config() :: keyword()
  def get_cache_config do
    get_cache_config(get_environment())
  end

  @doc """
  Obtém configurações específicas do sistema de telemetria.
  """
  @spec get_telemetry_config() :: keyword()
  def get_telemetry_config do
    get_telemetry_config(get_environment())
  end

  @doc """
  Obtém configurações específicas do banco de dados.
  """
  @spec get_database_config() :: keyword()
  def get_database_config do
    get_database_config(get_environment())
  end

  @doc """
  Obtém configurações específicas dos supervisors.
  """
  @spec get_supervisor_config() :: keyword()
  def get_supervisor_config do
    get_supervisor_config(get_environment())
  end

  # Funções privadas para configurações por ambiente

  @spec get_environment() :: atom()
  defp get_environment do
    Application.get_env(:deeper_hub, :environment, :development)
  end

  @spec get_cache_config(atom()) :: keyword()
  defp get_cache_config(environment) do
    base_config = [
      compressed: true,
      stats: true,
      transactions: true,
      expiry_interval: 60_000,
      default_ttl: 300,
      use_warmers: true
    ]

    case environment do
      :production ->
        base_config ++
        [
          use_logger_hook: false,
          use_lru_limit: true,
          lru_limit: 50_000,
          use_distributed: true,
          telemetry: true,
          telemetry_report_interval: 300_000, # 5 minutos
          telemetry_logging: false,
          prometheus_integration: true,
          cache_limit: 50_000
        ]

      :test ->
        base_config ++
        [
          use_logger_hook: false,
          use_lru_limit: true,
          lru_limit: 1_000,
          use_distributed: false,
          telemetry: false,
          telemetry_logging: false,
          prometheus_integration: false,
          cache_limit: 1_000,
          expiry_interval: 10_000 # Mais frequente para testes
        ]

      _ -> # :development
        base_config ++
        [
          use_logger_hook: true,
          use_lru_limit: true,
          lru_limit: 10_000,
          use_distributed: false,
          telemetry: true,
          telemetry_report_interval: 60_000, # 1 minuto
          telemetry_logging: true,
          prometheus_integration: false,
          cache_limit: 10_000
        ]
    end
  end

  @spec get_telemetry_config(atom()) :: keyword()
  defp get_telemetry_config(environment) do
    base_config = [
      telemetry_prefix: "deeper_hub",
      enabled_adapters: [:cache, :database, :http, :network, :security]
    ]

    case environment do
      :production ->
        base_config ++
        [
          exporters: [:prometheus],
          report_interval: 300_000, # 5 minutos
          enable_logging: false,
          enable_prometheus: true,
          metrics_retention_hours: 24,
          detailed_metrics: false
        ]

      :test ->
        base_config ++
        [
          enabled_adapters: [:cache, :database], # Apenas essenciais para testes
          exporters: [],
          report_interval: 10_000,
          enable_logging: false,
          enable_prometheus: false,
          detailed_metrics: false
        ]

      _ -> # :development
        base_config ++
        [
          exporters: [],
          report_interval: 60_000, # 1 minuto
          enable_logging: true,
          enable_prometheus: false,
          metrics_retention_hours: 2,
          detailed_metrics: true
        ]
    end
  end

  @spec get_database_config(atom()) :: keyword()
  defp get_database_config(environment) do
    base_config = [
      pool_name: DeeperHub.DBConnectionPool,
      show_sensitive_data_on_connection_error: false,
      timeout: 15_000,
      idle_interval: 15_000
    ]

    case environment do
      :production ->
        base_config ++
        [
          database: "databases/deeper_hub_prod.db",
          pool_size: 20,
          journal_mode: :wal,
          busy_timeout: 10_000,
          max_retries: 5,
          retry_delay_ms: 500,
          telemetry_enabled: true,
          health_check_interval: 300_000 # 5 minutos
        ]

      :test ->
        base_config ++
        [
          database: ":memory:", # Banco em memória para testes
          pool_size: 2,
          journal_mode: :memory,
          busy_timeout: 1_000,
          max_retries: 1,
          retry_delay_ms: 100,
          telemetry_enabled: false,
          health_check_interval: 60_000
        ]

      _ -> # :development
        base_config ++
        [
          database: "databases/deeper_hub_dev.db",
          pool_size: 5,
          journal_mode: :wal,
          busy_timeout: 5_000,
          max_retries: 3,
          retry_delay_ms: 200,
          telemetry_enabled: true,
          health_check_interval: 60_000,
          show_sensitive_data_on_connection_error: true
        ]
    end
  end

  @spec get_supervisor_config(atom()) :: keyword()
  defp get_supervisor_config(environment) do
    case environment do
      :production ->
        [
          strategy: :one_for_one,
          max_restarts: 5,
          max_seconds: 10,
          restart_strategy: :permanent
        ]

      :test ->
        [
          strategy: :one_for_one,
          max_restarts: 1,
          max_seconds: 5,
          restart_strategy: :temporary
        ]

      _ -> # :development
        [
          strategy: :one_for_one,
          max_restarts: 3,
          max_seconds: 5,
          restart_strategy: :permanent
        ]
    end
  end

  @doc """
  Aplica as configurações do sistema na aplicação.

  Esta função deve ser chamada durante a inicialização da aplicação
  para garantir que todas as configurações sejam aplicadas corretamente.
  """
  @spec apply_system_config() :: :ok
  def apply_system_config do
    config = get_system_config()

    Logger.info("Aplicando configurações do sistema para ambiente: #{config.environment}")

    # Aplica configurações na aplicação
    Application.put_env(:deeper_hub, :cache, config.cache)
    Application.put_env(:deeper_hub, :telemetry, config.telemetry)
    Application.put_env(:deeper_hub, :database, config.database)
    Application.put_env(:deeper_hub, :supervisor, config.supervisor)

    Logger.info("Configurações do sistema aplicadas com sucesso")
    :ok
  end

  @doc """
  Valida se todas as configurações necessárias estão presentes.

  ## Retorno

  - `:ok` - Se todas as configurações estão válidas
  - `{:error, missing_configs}` - Se alguma configuração obrigatória estiver faltando
  """
  @spec validate_config() :: :ok | {:error, list()}
  def validate_config do
    config = get_system_config()
    missing = []

    # Valida configurações obrigatórias
    missing = if is_nil(config.cache[:default_ttl]), do: [:cache_default_ttl | missing], else: missing
    missing = if is_nil(config.database[:pool_name]), do: [:database_pool_name | missing], else: missing
    missing = if is_nil(config.telemetry[:telemetry_prefix]), do: [:telemetry_prefix | missing], else: missing

    case missing do
      [] ->
        Logger.info("Validação de configuração concluída com sucesso")
        :ok
      missing_configs ->
        Logger.error("Configurações obrigatórias faltando: #{inspect(missing_configs)}")
        {:error, missing_configs}
    end
  end
end
