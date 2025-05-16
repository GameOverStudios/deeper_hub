defmodule Deeper_Hub.Core.Data.DBConnection.Supervisor do
  @moduledoc """
  Supervisor para o sistema de conexão com banco de dados do Deeper_Hub.

  Este módulo é responsável por iniciar e supervisionar as conexões com
  banco de dados, garantindo que elas sejam reiniciadas adequadamente
  em caso de falhas.

  ## Funcionalidades

  * 👀 Supervisão de conexões com banco de dados
  * 🔄 Reinicialização automática em caso de falhas
  * 🛠️ Configuração flexível através de opções
  * 📊 Integração com sistema de métricas

  ## Exemplo de Uso

  ```elixir
  # Iniciar o supervisor com configurações padrão
  Deeper_Hub.Core.Data.DBConnection.Supervisor.start_link()

  # Ou adicionar à árvore de supervisão da aplicação
  children = [
    {Deeper_Hub.Core.Data.DBConnection.Supervisor, []}
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
  ```
  """

  use Supervisor

  alias Deeper_Hub.Core.Data.DBConnection.DBConnectionAdapter
  alias Deeper_Hub.Core.Logger

  @doc """
  Inicia o supervisor de conexões com banco de dados.

  ## Parâmetros

    * `opts` - Opções de inicialização (opcional)

  ## Retorno

    * `{:ok, pid}` - Supervisor iniciado com sucesso
    * `{:error, reason}` - Erro ao iniciar o supervisor
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Logger.info("Iniciando supervisor de conexões com banco de dados", %{
      module: __MODULE__
    })

    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Inicializa o supervisor e seus processos filhos.

  ## Parâmetros

    * `opts` - Opções de inicialização

  ## Retorno

    * `{:ok, {supervisor_flags, child_specs}}` - Configuração do supervisor
  """
  @impl true
  def init(opts) do
    Logger.debug("Inicializando supervisor de conexões com banco de dados", %{
      module: __MODULE__,
      opts: inspect(opts)
    })

    # Obter configurações de conexão do ambiente
    conn_configs = get_connection_configs(opts)

    # Criar especificações de filhos para cada conexão
    children = Enum.map(conn_configs, fn {name, config} ->
      conn_mod = Keyword.fetch!(config, :module)
      conn_opts = Keyword.drop(config, [:module])

      # Adicionar nome à configuração
      conn_opts = Keyword.put(conn_opts, :name, name)

      # Criar especificação do filho
      %{
        id: name,
        start: {DBConnectionAdapter, :start_link, [conn_mod, conn_opts]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker
      }
    end)

    Logger.info("Supervisor de conexões com banco de dados inicializado com sucesso", %{
      module: __MODULE__,
      children_count: length(children)
    })

    # Configurar estratégia de supervisão
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Funções privadas

  # Obtém as configurações de conexão do ambiente
  defp get_connection_configs(opts) do
    # Verificar se as configurações foram passadas diretamente
    case Keyword.get(opts, :connections) do
      nil ->
        # Obter configurações do ambiente
        Application.get_env(:deeper_hub, :db_connections, [])

      connections when is_list(connections) ->
        connections
    end
    |> Enum.map(fn
      {name, config} when is_atom(name) and is_list(config) ->
        {name, config}

      config when is_list(config) ->
        case Keyword.fetch(config, :name) do
          {:ok, name} ->
            {name, Keyword.delete(config, :name)}
          :error ->
            Logger.error("Configuração de conexão sem nome", %{
              module: __MODULE__,
              config: inspect(config)
            })
            nil
        end

      invalid ->
        Logger.error("Configuração de conexão inválida", %{
          module: __MODULE__,
          config: inspect(invalid)
        })

        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end
end
