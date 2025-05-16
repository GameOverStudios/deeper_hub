defmodule Deeper_Hub.Core.EventBus.Supervisor do
  @moduledoc """
  Supervisor para o sistema de barramento de eventos do Deeper_Hub.

  Este módulo é responsável por iniciar e supervisionar os processos
  relacionados ao sistema de barramento de eventos, garantindo que os tópicos
  padrão sejam registrados e que o sistema esteja sempre disponível.

  ## Responsabilidades

  * 🚀 Inicializar o sistema de barramento de eventos
  * 📊 Registrar tópicos padrão para eventos importantes
  * 🔄 Garantir a disponibilidade do sistema de eventos
  * 🛡️ Supervisionar processos relacionados ao barramento de eventos
  """

  use Supervisor

  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.EventBus.Topics

  @doc """
  Inicia o supervisor de barramento de eventos.

  ## Retorno

    * `{:ok, pid}` - Supervisor iniciado com sucesso
    * `{:error, reason}` - Falha ao iniciar o supervisor
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Inicializa o supervisor e registra os tópicos padrão.

  ## Parâmetros

    * `init_arg` - Argumentos de inicialização (não utilizados)

  ## Retorno

    * `{:ok, {supervisor_flags, child_specs}}` - Configuração do supervisor
  """
  @impl Supervisor
  def init(_init_arg) do
    Logger.info("Inicializando supervisor de barramento de eventos", %{module: __MODULE__})

    # Registra os tópicos padrão para eventos importantes
    register_default_topics()

    # Define os processos filhos a serem supervisionados
    children = [
      # Por enquanto, não há processos filhos específicos para o barramento de eventos
      # No futuro, poderiam ser adicionados processos como workers de processamento de eventos
    ]

    # Inicia o supervisor com a estratégia one_for_one
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Registra os tópicos padrão para eventos importantes do sistema.

  Esta função é chamada durante a inicialização do supervisor e
  registra os tópicos definidos no módulo Topics.

  ## Retorno

    * `:ok` - Tópicos registrados com sucesso
  """
  @spec register_default_topics() :: :ok
  def register_default_topics do
    Logger.debug("Registrando tópicos padrão de barramento de eventos", %{module: __MODULE__})

    # Registra todos os tópicos padrão
    :ok = Topics.register_all_topics()

    Logger.info("Tópicos padrão de barramento de eventos registrados com sucesso", %{module: __MODULE__})

    :ok
  end
end
