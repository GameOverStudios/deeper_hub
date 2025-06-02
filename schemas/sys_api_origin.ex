defmodule DeeperHub.Schema.SysApiOrigin do
  @moduledoc """
  Schema para representação de sys_api_origins no sistema

  Este schema armazena as informações de um sys_api_origin.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_api_origins" do
    field :url, :string  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_api_origin no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    url: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_api_origin.

  ## Parâmetros 
    - `sys_api_origin`: Struct do sys_api_origin (pode ser %SysApiOrigin{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_api_origin \ %__MODULE__{}, attrs) do
    sys_api_origin
    |> cast(attrs, [:url, :order])
    |> validate_required([:url, :order])
  end

  @doc """
  Changeset para atualização de um sys_api_origin existente.

  ## Parâmetros 
    - `sys_api_origin`: Struct do sys_api_origin (%SysApiOrigin{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_api_origin \ %__MODULE__{}, attrs) do
    sys_api_origin
    |> cast(attrs, [:url, :order])
  end
end
