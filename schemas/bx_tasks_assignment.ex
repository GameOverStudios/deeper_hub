defmodule DeeperHub.Schema.BxTasksAssignment do
  @moduledoc """
  Schema para representação de bx_tasks_assignments no sistema

  Este schema armazena as informações de um bx_tasks_assignment.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_tasks_assignments" do
    field :initiator, :integer  # int(11)
    field :content, :integer  # int(11)
    field :added, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_tasks_assignment no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_tasks_assignment.

  ## Parâmetros 
    - `bx_tasks_assignment`: Struct do bx_tasks_assignment (pode ser %BxTasksAssignment{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_tasks_assignment \ %__MODULE__{}, attrs) do
    bx_tasks_assignment
    |> cast(attrs, [:initiator, :content, :added])
    |> validate_required([:initiator, :content, :added])
  end

  @doc """
  Changeset para atualização de um bx_tasks_assignment existente.

  ## Parâmetros 
    - `bx_tasks_assignment`: Struct do bx_tasks_assignment (%BxTasksAssignment{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_tasks_assignment \ %__MODULE__{}, attrs) do
    bx_tasks_assignment
    |> cast(attrs, [:initiator, :content, :added])
  end
end
