defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal do DeeperHub.

  Este módulo define a árvore de supervisão e inicia todos os componentes
  necessários para o funcionamento da aplicação.
  """

  use Application
  require Logger # Usamos o Logger padrão do Elixir aqui já que nosso Logger ainda não foi inicializado

  @impl true
  def start(_type, _args) do
    # Configura o diretório do Mnesia para persistência de dados
    configure_mnesia()

    Logger.info("Inicializando Sistema DeeperHub")

    # Definimos a lista de supervisores em ordem de inicialização
    children = [
      # Inicia o supervisor do Logger primeiro para garantir que os logs estejam disponíveis
      DeeperHub.Core.Logger.Supervisor,

      # Inicia outros supervisores
      DeeperHub.Core.ConfigManager.Supervisor,
      DeeperHub.Core.EventBus.Supervisor

      # Outros módulos do sistema...
    ]

    # Ver https://hexdocs.pm/elixir/Supervisor.html
    # para outras estratégias e opções de supervisão
    opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]

    # Iniciar supervisor
    result = Supervisor.start_link(children, opts)

    Logger.info("Todos os supervisores iniciados")
    result
  end

  # Configura o diretório do Mnesia para persistência
  defp configure_mnesia do
    # Define o diretório para armazenar os dados do Mnesia
    dir = Application.get_env(:mnesia, :dir) ||
           Path.join([File.cwd!(), "priv", "mnesia", "#{node()}"])

    Logger.info("Configurando diretório de persistência do Mnesia: #{dir}")

    # Garante que o diretório existe
    File.mkdir_p!(dir)

    # Configura o diretório no Mnesia
    :ok = Application.put_env(:mnesia, :dir, to_charlist(dir))

    # Se não houver schema, cria um novo
    if not File.exists?(Path.join(dir, "schema.DAT")) do
      Logger.info("Criando novo schema Mnesia")
      case :mnesia.create_schema([node()]) do
        :ok ->
          Logger.info("Schema criado com sucesso")
        {:error, {_, {:already_exists, _}}} ->
          Logger.info("Schema já existe, usando o existente")
        {:error, reason} ->
          Logger.error("Erro ao criar schema: #{inspect(reason)}")
      end
    end

    # Inicia o Mnesia
    case :mnesia.start() do
      :ok ->
        Logger.info("Mnesia iniciado com sucesso")
      {:error, reason} ->
        Logger.error("Erro ao iniciar Mnesia: #{inspect(reason)}")
        raise "Falha ao iniciar Mnesia: #{inspect(reason)}"
    end
  end
end
