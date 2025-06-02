defmodule DeeperHub.Schema.BxTasksList do
  @moduledoc """
  Schema para representação de bx_tasks_lists no sistema

  Este schema armazena as informações de um bx_tasks_list.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_tasks_lists" do
    field :context_id, :integer  # int(11)
    field :title, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_tasks_list no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    context_id: integer() | nil,
    title: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_tasks_list.

  ## Parâmetros 
    - `bx_tasks_list`: Struct do bx_tasks_list (pode ser %BxTasksList{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_tasks_list \ %__MODULE__{}, attrs) do
    bx_tasks_list
    |> cast(attrs, [:context_id, :title])
    |> validate_required([:context_id, :title])
  end

  @doc """
  Changeset para atualização de um bx_tasks_list existente.

  ## Parâmetros 
    - `bx_tasks_list`: Struct do bx_tasks_list (%BxTasksList{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_tasks_list \ %__MODULE__{}, attrs) do
    bx_tasks_list
    |> cast(attrs, [:context_id, :title])
  end
end
