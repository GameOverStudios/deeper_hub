defmodule DeeperHub.Schema.SysStorageDeletion do
  @moduledoc """
  Schema para representação de sys_storage_deletions no sistema

  Este schema armazena as informações de um sys_storage_deletion.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_storage_deletions" do
    field :object, :string  # varchar(64)
    field :file_id, :integer  # int(11)
    field :requested, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_storage_deletion no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    file_id: integer() | nil,
    requested: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_storage_deletion.

  ## Parâmetros 
    - `sys_storage_deletion`: Struct do sys_storage_deletion (pode ser %SysStorageDeletion{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_storage_deletion \ %__MODULE__{}, attrs) do
    sys_storage_deletion
    |> cast(attrs, [:object, :file_id, :requested])
    |> validate_required([:object, :file_id, :requested])
  end

  @doc """
  Changeset para atualização de um sys_storage_deletion existente.

  ## Parâmetros 
    - `sys_storage_deletion`: Struct do sys_storage_deletion (%SysStorageDeletion{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_storage_deletion \ %__MODULE__{}, attrs) do
    sys_storage_deletion
    |> cast(attrs, [:object, :file_id, :requested])
  end
end
