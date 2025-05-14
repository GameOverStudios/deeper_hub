defmodule Deeper_Hub.Core.Data.Repository do
  @moduledoc """
  Repositório genérico para operações CRUD.

  Este módulo funciona como uma fachada (Facade) para os módulos específicos:
  - RepositoryCore: Funções de gerenciamento de cache e inicialização
  - RepositoryCrud: Operações CRUD básicas (insert, get, update, delete, list, find)
  - RepositoryJoins: Operações de join (inner, left, right)
  """

  alias Deeper_Hub.Core.Data.RepositoryCore
  alias Deeper_Hub.Core.Data.RepositoryCrud
  alias Deeper_Hub.Core.Data.RepositoryJoins
  
  @doc """
  Define a especificação para o supervisor.
  
  Esta função é chamada pelo supervisor para iniciar o processo
  do repositório.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {RepositoryCore, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # Delegação de funções de cache e inicialização
  defdelegate initialize_cache(), to: RepositoryCore
  defdelegate start_link(opts), to: RepositoryCore
  defdelegate init_cache(), to: RepositoryCore
  defdelegate invalidate_cache(schema, id), to: RepositoryCore
  defdelegate get_cache_stats(), to: RepositoryCore
  defdelegate ensure_cache_initialized(), to: RepositoryCore
  defdelegate get_from_cache(schema, id), to: RepositoryCore
  defdelegate put_in_cache(schema, id, value), to: RepositoryCore
  defdelegate apply_limit_offset(query, opts), to: RepositoryCore

  # Delegação de operações CRUD
  defdelegate insert(schema, attrs), to: RepositoryCrud
  defdelegate get(schema, id), to: RepositoryCrud
  defdelegate update(struct, attrs), to: RepositoryCrud
  defdelegate delete(struct), to: RepositoryCrud
  defdelegate list(schema, opts \\ []), to: RepositoryCrud
  defdelegate find(schema, conditions, opts \\ []), to: RepositoryCrud

  # Delegação de operações de join
  defdelegate join_inner(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
  defdelegate join_left(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
  defdelegate join_right(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []), to: RepositoryJoins
end
