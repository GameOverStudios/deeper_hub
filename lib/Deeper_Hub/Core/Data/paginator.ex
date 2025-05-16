defmodule Deeper_Hub.Core.Data.Paginator do
  @moduledoc """
  Módulo responsável por gerenciar a paginação de dados usando Scrivener.
  
  Este módulo fornece funções para paginar consultas Ecto de forma consistente,
  usando configurações definidas no config.exs.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo

  @doc """
  Pagina uma consulta usando as configurações padrão do Scrivener.

  ## Parâmetros

    * `query` - A consulta Ecto a ser paginada
    * `params` - Mapa com parâmetros de paginação:
      * `:page` - Número da página (padrão: 1)
      * `:page_size` - Itens por página (padrão: configuração do Scrivener)
      * `:sort_field` - Campo para ordenação (padrão: configuração do Scrivener)
      * `:sort_order` - Direção da ordenação, :asc ou :desc (padrão: configuração do Scrivener)

  ## Exemplo

      iex> paginate(User, %{page: 2, page_size: 20})
      %Scrivener.Page{entries: [...], page_number: 2, page_size: 20, total_pages: 5, total_entries: 100}
  """
  def paginate(query, params \\ %{}) do
    paginate_with_config(query, params, :scrivener_ecto)
  end

  @doc """
  Pagina uma consulta usando configurações específicas do módulo.

  ## Parâmetros

    * `query` - A consulta Ecto a ser paginada
    * `params` - Mapa com parâmetros de paginação (mesmo formato de `paginate/2`)
    * `module_config` - Átomo representando a chave de configuração do módulo (ex: :users, :profiles)

  ## Exemplo

      iex> paginate_module(User, %{page: 1}, :users)
      %Scrivener.Page{entries: [...], page_number: 1, page_size: 15, total_pages: 7, total_entries: 100}
  """
  def paginate_module(query, params \\ %{}, module_config) do
    config = Application.get_env(:deeper_hub, :pagination)[module_config] || []
    paginate_with_config(query, params, config)
  end

  # Função privada para realizar a paginação com configurações específicas
  defp paginate_with_config(query, params, config) do
    page_number = params[:page] || 1
    page_size = get_page_size(params, config)
    sort_field = get_sort_field(params, config)
    sort_order = get_sort_order(params, config)

    # Aplica ordenação à query
    query = from q in query,
      order_by: [{^sort_order, ^sort_field}]

    # Pagina usando Scrivener
    Repo.paginate(query, page: page_number, page_size: page_size)
  end

  # Funções auxiliares para obter valores de configuração
  defp get_page_size(params, config) do
    max_size = config[:max_page_size] || 100
    default_size = config[:page_size] || 10
    size = params[:page_size] || default_size
    min(size, max_size)
  end

  defp get_sort_field(params, config) do
    params[:sort_field] || config[:default_sort_field] || :id
  end

  defp get_sort_order(params, config) do
    order = params[:sort_order] || config[:default_sort_order] || :asc
    if order in [:asc, :desc], do: order, else: :asc
  end
end
