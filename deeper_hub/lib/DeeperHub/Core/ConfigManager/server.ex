defmodule DeeperHub.Core.ConfigManager.Server do
  @moduledoc """
  Servidor GenServer que gerencia o estado das configurações do sistema.

  Este módulo é responsável por:
  - Interagir com o storage adapter para persistência
  - Gerenciar o cache de configurações
  - Notificar os assinantes sobre mudanças nas configurações
  """

  use GenServer

  alias DeeperHub.Core.ConfigManager.Services.Setting, as: SettingService
  alias DeeperHub.Core.EventBus
  alias DeeperHub.Core.Logger

  # API Pública

  @doc """
  Inicia o servidor do ConfigManager.
  """
  def start_link(opts \\ []) do
    Logger.debug("Iniciando servidor do ConfigManager", %{module: __MODULE__})
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Obtém o valor de uma configuração.
  """
  def get(key, scope, default) do
    Logger.debug("Obtendo configuração", %{key: key, scope: scope})
    case GenServer.call(__MODULE__, {:get, key, scope}) do
      {:ok, value} ->
        Logger.debug("Configuração encontrada", %{key: key, scope: scope})
        value
      {:error, :not_found} ->
        Logger.debug("Configuração não encontrada, usando valor padrão", %{key: key, scope: scope, default: inspect(default)})
        default
    end
  end

  @doc """
  Define ou atualiza o valor de uma configuração.
  """
  def set(key, value, scope, opts) do
    Logger.debug("Definindo configuração", %{key: key, scope: scope, options: inspect(opts)})
    GenServer.call(__MODULE__, {:set, key, value, scope, opts})
  end

  @doc """
  Remove uma configuração.
  """
  def delete(key, scope, opts) do
    Logger.debug("Removendo configuração", %{key: key, scope: scope, options: inspect(opts)})
    GenServer.call(__MODULE__, {:delete, key, scope, opts})
  end

  @doc """
  Subscreve para receber notificações de mudanças em configurações.
  """
  def subscribe(pattern, subscriber) do
    Logger.debug("Registrando assinante para configurações", %{pattern: pattern, subscriber: inspect(subscriber)})
    # Delegamos para o EventBus
    case EventBus.subscribe("config.#{pattern}", subscriber) do
      :ok ->
        Logger.info("Assinante registrado com sucesso", %{pattern: pattern, subscriber: inspect(subscriber)})
        :ok
      error ->
        Logger.error("Falha ao registrar assinante", %{pattern: pattern, subscriber: inspect(subscriber), error: inspect(error)})
        error
    end
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
    Logger.info("Inicializando estado do ConfigManager", %{module: __MODULE__})

    # Garantir que as tabelas Mnesia estejam criadas
    :ok = ensure_tables_created()

    # Estado inicial: um mapa vazio para cache em memória
    # No futuro, poderíamos adicionar um sistema de cache mais sofisticado (ETS)
    {:ok, %{
      cache: %{}
    }, {:continue, :load_initial_configs}}
  end

  @impl true
  def handle_continue(:load_initial_configs, state) do
    Logger.info("Carregando configurações iniciais", %{})
    # Carregar configurações iniciais apenas uma vez na inicialização
    # Aqui poderíamos carregar também de arquivos de configuração ou variáveis de ambiente
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key, scope}, _from, state) do
    Logger.debug("Buscando configuração", %{key: key, scope: scope})

    # Verificar primeiro no cache
    cache_key = cache_key(key, scope)

    case Map.get(state.cache, cache_key) do
      nil ->
        Logger.debug("Configuração não encontrada no cache, buscando no banco", %{key: key, scope: scope})

        # Não encontrou no cache, buscar no banco de dados
        case SettingService.get_by_key_and_scope(key, scope) do
          {:ok, setting} ->
            Logger.debug("Configuração encontrada no banco", %{key: key, scope: scope, value: inspect(setting.value)})

            # Atualizar o cache e retornar o valor
            new_cache = Map.put(state.cache, cache_key, setting.value)
            {:reply, {:ok, setting.value}, %{state | cache: new_cache}}

          {:error, :not_found} ->
            Logger.debug("Configuração não encontrada no banco", %{key: key, scope: scope})
            {:reply, {:error, :not_found}, state}
        end

      value ->
        # Encontrou no cache
        Logger.debug("Configuração encontrada no cache", %{key: key, scope: scope, value: inspect(value)})
        {:reply, {:ok, value}, state}
    end
  end

  @impl true
  def handle_call({:set, key, value, scope, opts}, _from, state) do
    Logger.debug("Processando definição de configuração", %{key: key, scope: scope})

    case SettingService.upsert(key, value, scope, opts) do
      {:ok, setting} ->
        Logger.debug("Configuração persistida com sucesso", %{key: key, scope: scope})

        # Atualizar o cache
        cache_key = cache_key(key, scope)
        new_cache = Map.put(state.cache, cache_key, value)

        # Notificar os assinantes
        Logger.debug("Notificando assinantes sobre mudança de configuração", %{key: key, scope: scope})
        publish_config_changed(key, scope, nil, value)

        Logger.info("Configuração definida com sucesso", %{key: key, scope: scope})
        {:reply, {:ok, setting}, %{state | cache: new_cache}}

      {:error, reason} ->
        Logger.error("Falha ao definir configuração", %{key: key, scope: scope, reason: inspect(reason)})
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:delete, key, scope, opts}, _from, state) do
    Logger.debug("Processando remoção de configuração", %{key: key, scope: scope})

    # Primeiro, vamos buscar a configuração atual
    case SettingService.get_by_key_and_scope(key, scope) do
      {:ok, setting} ->
        Logger.debug("Configuração encontrada para remoção", %{key: key, scope: scope})

        # Remover a configuração
        deleted_by = Keyword.get(opts, :deleted_by, "system")

        case SettingService.delete(setting, deleted_by) do
          {:ok, deleted_setting} ->
            Logger.debug("Configuração removida do banco com sucesso", %{key: key, scope: scope})

            # Remover do cache
            cache_key = cache_key(key, scope)
            new_cache = Map.delete(state.cache, cache_key)

            # Notificar os assinantes
            Logger.debug("Notificando assinantes sobre remoção de configuração", %{key: key, scope: scope})
            publish_config_changed(key, scope, setting.value, nil)

            Logger.info("Configuração removida com sucesso", %{key: key, scope: scope})
            {:reply, {:ok, deleted_setting}, %{state | cache: new_cache}}

          {:error, reason} ->
            Logger.error("Falha ao remover configuração", %{key: key, scope: scope, reason: inspect(reason)})
            {:reply, {:error, reason}, state}
        end

      {:error, :not_found} ->
        Logger.warn("Tentativa de remover configuração inexistente", %{key: key, scope: scope})
        {:reply, {:error, :not_found}, state}
    end
  end

  # Funções privadas

  defp cache_key(key, scope) do
    "#{scope}:#{key}"
  end

  defp ensure_tables_created do
    Logger.debug("Garantindo que as tabelas Mnesia estejam criadas", %{})

    try do
      case :mnesia.system_info(:is_running) do
        :yes ->
          # Verifica se a tabela já existe antes de tentar criar
          tables = :mnesia.system_info(:tables)

          if not Enum.member?(tables, SettingTable) do
            Logger.debug("Tabela Setting não encontrada, criando...", %{})
            SettingService.setup()
          else
            Logger.debug("Tabela Setting já existe, usando a existente", %{})
          end

          Logger.debug("Tabelas Mnesia verificadas com sucesso", %{})
          :ok
        _ ->
          # Iniciar o Mnesia
          Logger.debug("Iniciando Mnesia", %{})
          :mnesia.start()

          # Verifica se a tabela já existe antes de tentar criar
          tables = :mnesia.system_info(:tables)

          if not Enum.member?(tables, SettingTable) do
            Logger.debug("Tabela Setting não encontrada, criando...", %{})
            SettingService.setup()
          else
            Logger.debug("Tabela Setting já existe, usando a existente", %{})
          end

          Logger.debug("Tabelas Mnesia verificadas com sucesso", %{})
          :ok
      end
    rescue
      error ->
        Logger.warn("Erro ao verificar tabelas Mnesia, tentando inicializar", %{
          error: inspect(error)
        })

        # Se houver algum erro, tentar iniciar o Mnesia e criar as tabelas
        :mnesia.start()

        # Mesmo com erro, tentamos verificar se as tabelas já existem
        tables = :mnesia.system_info(:tables)

        if not Enum.member?(tables, SettingTable) do
          Logger.debug("Tabela Setting não encontrada, criando após erro...", %{})
          SettingService.setup()
        end

        Logger.info("Tabelas Mnesia verificadas após erro", %{})
        :ok
    end
  end

  defp publish_config_changed(key, scope, old_value, new_value) do
    Logger.debug("Publicando evento de mudança de configuração", %{
      key: key,
      scope: scope,
      old_value: inspect(old_value),
      new_value: inspect(new_value)
    })

    # Publicar um evento no EventBus
    EventBus.publish(
      "config.#{key}",
      %{
        key: key,
        scope: scope,
        old_value: old_value,
        new_value: new_value
      },
      metadata: %{
        timestamp: DateTime.utc_now()
      }
    )
  end
end
