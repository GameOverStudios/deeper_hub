defmodule DeeperHub.Schema.BxClassesStatuse do
  @moduledoc """
  Schema para representação de bx_classes_statuses no sistema

  Este schema armazena as informações de um bx_classes_statuse.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_classes_statuses" do
    field :class_id, :integer  # int(10) unsigned
    field :student_profile_id, :integer  # int(11)
    field :viewed, :integer  # int(11)
    field :replied, :integer  # int(11)
    field :completed, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_classes_statuse no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    class_id: integer() | nil,
    student_profile_id: integer() | nil,
    viewed: integer() | nil,
    replied: integer() | nil,
    completed: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_classes_statuse.

  ## Parâmetros 
    - `bx_classes_statuse`: Struct do bx_classes_statuse (pode ser %BxClassesStatuse{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_classes_statuse \ %__MODULE__{}, attrs) do
    bx_classes_statuse
    |> cast(attrs, [:class_id, :student_profile_id, :viewed, :replied, :completed])
    |> validate_required([:class_id, :student_profile_id, :viewed, :replied, :completed])
  end

  @doc """
  Changeset para atualização de um bx_classes_statuse existente.

  ## Parâmetros 
    - `bx_classes_statuse`: Struct do bx_classes_statuse (%BxClassesStatuse{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_classes_statuse \ %__MODULE__{}, attrs) do
    bx_classes_statuse
    |> cast(attrs, [:class_id, :student_profile_id, :viewed, :replied, :completed])
  end
end
