defmodule DeeperHub.Schema.SysBadges2object do
  @moduledoc """
  Schema para representação de sys_badges2objects no sistema

  Este schema armazena as informações de um sys_badges2object.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_badges2objects" do
    field :badge_id, :integer  # int(11)
    field :object_id, :integer  # int(11)
    field :module, :string  # varchar(32)
    field :added, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_badges2object no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    badge_id: integer() | nil,
    object_id: integer() | nil,
    module: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_badges2object.

  ## Parâmetros 
    - `sys_badges2object`: Struct do sys_badges2object (pode ser %SysBadges2object{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_badges2object \ %__MODULE__{}, attrs) do
    sys_badges2object
    |> cast(attrs, [:badge_id, :object_id, :module, :added])
    |> validate_required([:badge_id, :object_id, :module, :added])
  end

  @doc """
  Changeset para atualização de um sys_badges2object existente.

  ## Parâmetros 
    - `sys_badges2object`: Struct do sys_badges2object (%SysBadges2object{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_badges2object \ %__MODULE__{}, attrs) do
    sys_badges2object
    |> cast(attrs, [:badge_id, :object_id, :module, :added])
  end
end
