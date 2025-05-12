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

  # API Pública

  @doc """
  Inicia o servidor do ConfigManager.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Obtém o valor de uma configuração.
  """
  def get(key, scope, default) do
    case GenServer.call(__MODULE__, {:get, key, scope}) do
      {:ok, value} -> value
      {:error, :not_found} -> default
    end
  end

  @doc """
  Define ou atualiza o valor de uma configuração.
  """
  def set(key, value, scope, opts) do
    GenServer.call(__MODULE__, {:set, key, value, scope, opts})
  end

  @doc """
  Remove uma configuração.
  """
  def delete(key, scope, opts) do
    GenServer.call(__MODULE__, {:delete, key, scope, opts})
  end

  @doc """
  Subscreve para receber notificações de mudanças em configurações.
  """
  def subscribe(pattern, subscriber) do
    # Delegamos para o EventBus
    case EventBus.subscribe("config.#{pattern}", subscriber) do
      :ok -> :ok
      error -> error
    end
  end

  # Callbacks do GenServer

  @impl true
  def init(_opts) do
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
    # Carregar configurações iniciais apenas uma vez na inicialização
    # Aqui poderíamos carregar também de arquivos de configuração ou variáveis de ambiente
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, key, scope}, _from, state) do
    # Verificar primeiro no cache
    cache_key = cache_key(key, scope)

    case Map.get(state.cache, cache_key) do
      nil ->
        # Não encontrou no cache, buscar no banco de dados
        case SettingService.get_by_key_and_scope(key, scope) do
          {:ok, setting} ->
            # Atualizar o cache e retornar o valor
            new_cache = Map.put(state.cache, cache_key, setting.value)
            {:reply, {:ok, setting.value}, %{state | cache: new_cache}}

          {:error, :not_found} ->
            {:reply, {:error, :not_found}, state}
        end

      value ->
        # Encontrou no cache
        {:reply, {:ok, value}, state}
    end
  end

  @impl true
  def handle_call({:set, key, value, scope, opts}, _from, state) do
    case SettingService.upsert(key, value, scope, opts) do
      {:ok, setting} ->
        # Atualizar o cache
        cache_key = cache_key(key, scope)
        new_cache = Map.put(state.cache, cache_key, value)

        # Notificar os assinantes
        publish_config_changed(key, scope, nil, value)

        {:reply, {:ok, setting}, %{state | cache: new_cache}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:delete, key, scope, opts}, _from, state) do
    # Primeiro, vamos buscar a configuração atual
    case SettingService.get_by_key_and_scope(key, scope) do
      {:ok, setting} ->
        # Remover a configuração
        deleted_by = Keyword.get(opts, :deleted_by, "system")

        case SettingService.delete(setting, deleted_by) do
          {:ok, deleted_setting} ->
            # Remover do cache
            cache_key = cache_key(key, scope)
            new_cache = Map.delete(state.cache, cache_key)

            # Notificar os assinantes
            publish_config_changed(key, scope, setting.value, nil)

            {:reply, {:ok, deleted_setting}, %{state | cache: new_cache}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, :not_found} ->
        {:reply, {:error, :not_found}, state}
    end
  end

  # Funções privadas

  defp cache_key(key, scope) do
    "#{scope}:#{key}"
  end

  defp ensure_tables_created do
    try do
      case :mnesia.system_info(:is_running) do
        :yes ->
          # Garantir que a tabela Setting esteja criada
          SettingService.setup()
          :ok
        _ ->
          # Iniciar o Mnesia
          :mnesia.start()
          SettingService.setup()
          :ok
      end
    rescue
      _ ->
        # Se houver algum erro, tentar iniciar o Mnesia e criar as tabelas
        :mnesia.start()
        SettingService.setup()
        :ok
    end
  end

  defp publish_config_changed(key, scope, old_value, new_value) do
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
