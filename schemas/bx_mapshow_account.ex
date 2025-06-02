defmodule DeeperHub.Schema.BxMapshowAccount do
  @moduledoc """
  Schema para representação de bx_mapshow_accounts no sistema

  Este schema armazena as informações de um bx_mapshow_account.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_mapshow_accounts" do
    field :account_id, :integer  # int(11)
    field :lng, :float  # float
    field :lat, :float  # float

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_mapshow_account no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    lng: float() | nil,
    lat: float() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_mapshow_account.

  ## Parâmetros 
    - `bx_mapshow_account`: Struct do bx_mapshow_account (pode ser %BxMapshowAccount{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_mapshow_account \ %__MODULE__{}, attrs) do
    bx_mapshow_account
    |> cast(attrs, [:account_id, :lng, :lat])
    |> validate_required([:account_id])
  end

  @doc """
  Changeset para atualização de um bx_mapshow_account existente.

  ## Parâmetros 
    - `bx_mapshow_account`: Struct do bx_mapshow_account (%BxMapshowAccount{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_mapshow_account \ %__MODULE__{}, attrs) do
    bx_mapshow_account
    |> cast(attrs, [:account_id, :lng, :lat])
  end
end
