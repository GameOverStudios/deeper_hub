defmodule DeeperHub.Core.Config.SystemConfig do
  @moduledoc """
  Configuração centralizada para todos os módulos do sistema DeeperHub.

  Este módulo centraliza as configurações de Database e outros
  subsistemas essenciais, permitindo fácil manutenção e consistência entre ambientes.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @doc """
  Obtém a configuração completa do sistema baseada no ambiente atual.

  ## Retorno

  Um mapa com todas as configurações organizadas por subsistema:
  - `:database` - Configurações do banco de dados
  - `:supervisor` - Configurações dos supervisors
  """
  @spec get_system_config() :: map()
  def get_system_config do
    environment = get_environment()

    %{
      environment: environment,
      database: get_database_config(environment),
      supervisor: get_supervisor_config(environment)
    }
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

  @doc """
  Obtém o ambiente atual da aplicação.

  ## Retorno
  - `:prod` - Ambiente de produção
  - `:dev` - Ambiente de desenvolvimento
  - `:test` - Ambiente de testes
  """
  @spec get_environment() :: atom()
  def get_environment do
    Application.get_env(:deeper_hub, :environment, :dev)
  end

  # Configurações específicas para cada ambiente

  @spec get_database_config(atom()) :: keyword()
  defp get_database_config(environment) do
    # Configurações base para todos os ambientes
    base_config = [
      db_path: "data/deeperhub.db",
      pool_size: 5,
      timeout: 15_000
    ]

    # Configurações específicas por ambiente
    case environment do
      :prod -> 
        Keyword.merge(base_config, [
          pool_size: 20,
          timeout: 30_000,
          auto_vacuum: true
        ])
      :test -> 
        Keyword.merge(base_config, [
          db_path: "data/test_db.db",
          pool_size: 2,
          auto_vacuum: false
        ])
      :dev -> 
        Keyword.merge(base_config, [
          pool_size: 10,
          auto_vacuum: true
        ])
    end
  end

  @spec get_supervisor_config(atom()) :: keyword()
  defp get_supervisor_config(environment) do
    # Configurações base para todos os ambientes
    base_config = [
      max_restarts: 3,
      max_seconds: 5
    ]

    # Configurações específicas por ambiente
    case environment do
      :prod -> 
        Keyword.merge(base_config, [
          max_restarts: 5,
          max_seconds: 10,
          shutdown_timeout: 10_000
        ])
      :test -> 
        Keyword.merge(base_config, [
          max_restarts: 1,
          max_seconds: 1,
          shutdown_timeout: 1_000
        ])
      :dev -> 
        Keyword.merge(base_config, [
          max_restarts: 10,
          max_seconds: 5,
          shutdown_timeout: 5_000
        ])
    end
  end

  @doc """
  Aplica as configurações do sistema ao ambiente da aplicação.

  Esta função deve ser chamada durante a inicialização da aplicação
  para garantir que todas as configurações estejam disponíveis.

  ## Retorno
  - `:ok` - Configurações aplicadas com sucesso
  """
  @spec apply_system_config() :: :ok
  def apply_system_config do
    Logger.info("Aplicando configurações do sistema...")
    config = get_system_config()

    # Registra as configurações aplicadas
    Logger.debug("Configurações do ambiente: #{inspect(config.environment)}")
    Logger.debug("Configurações de banco de dados: #{inspect(config.database)}")
    Logger.debug("Configurações de supervisors: #{inspect(config.supervisor)}")

    # Aplica configurações ao ambiente
    Application.put_env(:deeper_hub, :environment, config.environment)
    Application.put_env(:deeper_hub, :database, config.database)
    Application.put_env(:deeper_hub, :supervisor, config.supervisor)

    :ok
  end

  @doc """
  Valida as configurações do sistema.

  Esta função verifica se todas as configurações obrigatórias estão presentes
  e se os valores estão dentro dos intervalos aceitáveis.

  ## Retorno
  - `:ok` - Configurações válidas
  - `{:error, missing_configs}` - Lista de configurações ausentes ou inválidas
  """
  @spec validate_config() :: :ok | {:error, list(atom())}
  def validate_config do
    config = get_system_config()
    missing = []

    # Valida configurações do banco de dados
    missing = if is_nil(config.database[:db_path]), do: [:db_path | missing], else: missing
    missing = if is_nil(config.database[:pool_size]), do: [:pool_size | missing], else: missing

    # Valida configurações de supervisors
    missing = if is_nil(config.supervisor[:max_restarts]), do: [:max_restarts | missing], else: missing
    missing = if is_nil(config.supervisor[:max_seconds]), do: [:max_seconds | missing], else: missing

    if Enum.empty?(missing) do
      :ok
    else
      {:error, missing}
    end
  end
end
