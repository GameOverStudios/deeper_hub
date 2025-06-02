defmodule DeeperHub.Schema.SysStorageGhost do
  @moduledoc """
  Schema para representação de sys_storage_ghosts no sistema

  Este schema armazena as informações de um sys_storage_ghost.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_storage_ghosts" do
    field :iid, :integer  # int(11)
    field :profile_id, :integer  # int(10) unsigned
    field :object, :string  # varchar(64)
    field :content_id, :integer  # int(11)
    field :created, :integer  # int(10) unsigned
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_storage_ghost no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    iid: integer() | nil,
    profile_id: integer() | nil,
    object: String.t() | nil,
    content_id: integer() | nil,
    created: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_storage_ghost.

  ## Parâmetros 
    - `sys_storage_ghost`: Struct do sys_storage_ghost (pode ser %SysStorageGhost{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_storage_ghost \ %__MODULE__{}, attrs) do
    sys_storage_ghost
    |> cast(attrs, [:iid, :profile_id, :object, :content_id, :created, :order])
    |> validate_required([:iid, :profile_id, :object, :content_id, :created])
  end

  @doc """
  Changeset para atualização de um sys_storage_ghost existente.

  ## Parâmetros 
    - `sys_storage_ghost`: Struct do sys_storage_ghost (%SysStorageGhost{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_storage_ghost \ %__MODULE__{}, attrs) do
    sys_storage_ghost
    |> cast(attrs, [:iid, :profile_id, :object, :content_id, :created, :order])
  end
end
