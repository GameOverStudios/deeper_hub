defmodule DeeperHub.Schema.SysStorageToken do
  @moduledoc """
  Schema para representação de sys_storage_tokens no sistema

  Este schema armazena as informações de um sys_storage_token.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_storage_tokens" do
    field :iid, :integer  # int(11)
    field :object, :string  # varchar(64)
    field :hash, :string  # varchar(32)
    field :created, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_storage_token no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    iid: integer() | nil,
    object: String.t() | nil,
    hash: String.t() | nil,
    created: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_storage_token.

  ## Parâmetros 
    - `sys_storage_token`: Struct do sys_storage_token (pode ser %SysStorageToken{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_storage_token \ %__MODULE__{}, attrs) do
    sys_storage_token
    |> cast(attrs, [:iid, :object, :hash, :created])
    |> validate_required([:iid, :object, :hash, :created])
  end

  @doc """
  Changeset para atualização de um sys_storage_token existente.

  ## Parâmetros 
    - `sys_storage_token`: Struct do sys_storage_token (%SysStorageToken{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_storage_token \ %__MODULE__{}, attrs) do
    sys_storage_token
    |> cast(attrs, [:iid, :object, :hash, :created])
  end
end
