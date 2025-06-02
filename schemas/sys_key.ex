defmodule DeeperHub.Schema.SysKey do
  @moduledoc """
  Schema para representação de sys_keys no sistema

  Este schema armazena as informações de um sys_key.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_keys" do
    field :key, :string  # varchar(32)
    field :data, :string  # text
    field :expire, :integer  # int(11)
    field :salt, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_key no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    key: String.t() | nil,
    data: String.t() | nil,
    expire: integer() | nil,
    salt: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_key.

  ## Parâmetros 
    - `sys_key`: Struct do sys_key (pode ser %SysKey{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_key \ %__MODULE__{}, attrs) do
    sys_key
    |> cast(attrs, [:key, :data, :expire, :salt])
    |> validate_required([:key, :data, :expire, :salt])
  end

  @doc """
  Changeset para atualização de um sys_key existente.

  ## Parâmetros 
    - `sys_key`: Struct do sys_key (%SysKey{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_key \ %__MODULE__{}, attrs) do
    sys_key
    |> cast(attrs, [:key, :data, :expire, :salt])
  end
end
