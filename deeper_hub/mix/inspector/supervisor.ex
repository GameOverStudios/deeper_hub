defmodule DeeperHub.Inspector.Supervisor do
  @moduledoc """
  Supervisor para o sistema de inspeção 🔍

  Este módulo supervisiona os processos relacionados ao sistema de inspeção,
  garantindo que eles sejam reiniciados adequadamente em caso de falhas.
  """

  use Supervisor

  @doc """
  Inicia o supervisor do sistema de inspeção 🚀

  ## Parâmetros

    * `opts` - Opções para o supervisor

  ## Retorno

  Retorna `{:ok, pid}` se o supervisor for iniciado com sucesso, ou
  `{:error, reason}` caso contrário.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Definir os processos filhos a serem supervisionados
    children = [
      # Adicionar processos relacionados ao sistema de inspeção aqui
      # Por exemplo, serviços de cache, workers para inspeção em background, etc.

      # Por enquanto, não temos processos GenServer para supervisionar
      # Quando adicionarmos, eles serão incluídos aqui
    ]

    # Usar estratégia one_for_one: se um processo falhar, apenas ele será reiniciado
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Retorna informações sobre o estado atual do supervisor 📊

  ## Retorno

  Retorna um mapa com informações sobre os processos supervisionados.
  """
  def info do
    # Obter informações sobre os processos filhos
    children = Supervisor.which_children(__MODULE__)

    # Formatar as informações para exibição
    %{
      process_count: length(children),
      processes:
        Enum.map(children, fn {id, pid, type, modules} ->
          %{
            id: id,
            pid: inspect(pid),
            type: type,
            modules: modules
          }
        end)
    }
  end
end
