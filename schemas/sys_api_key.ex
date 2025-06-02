defmodule DeeperHub.Schema.SysApiKey do
  @moduledoc """
  Schema para representação de sys_api_keys no sistema

  Este schema armazena as informações de um sys_api_key.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_api_keys" do
    field :title, :string  # varchar(255)
    field :key, :string  # varchar(48)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_api_key no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    key: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_api_key.

  ## Parâmetros 
    - `sys_api_key`: Struct do sys_api_key (pode ser %SysApiKey{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_api_key \ %__MODULE__{}, attrs) do
    sys_api_key
    |> cast(attrs, [:title, :key, :order])
    |> validate_required([:title, :key, :order])
  end

  @doc """
  Changeset para atualização de um sys_api_key existente.

  ## Parâmetros 
    - `sys_api_key`: Struct do sys_api_key (%SysApiKey{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_api_key \ %__MODULE__{}, attrs) do
    sys_api_key
    |> cast(attrs, [:title, :key, :order])
  end
end
