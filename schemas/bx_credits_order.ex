defmodule DeeperHub.Schema.BxCreditsOrder do
  @moduledoc """
  Schema para representação de bx_credits_orders no sistema

  Este schema armazena as informações de um bx_credits_order.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_orders" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :bundle_id, :integer, default: 0  # int(11) unsigned
    field :count, :integer, default: 0  # int(11) unsigned
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :type, :string, default: ""  # varchar(16)
    field :added, :integer, default: 0  # int(11) unsigned
    field :expired, :integer, default: 0  # int(11) unsigned
    field :new, :boolean, default: true  # tinyint(1)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_order no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    bundle_id: integer() | nil,
    count: integer() | nil,
    order: String.t() | nil,
    license: String.t() | nil,
    type: String.t() | nil,
    added: integer() | nil,
    expired: integer() | nil,
    new: boolean() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_order.

  ## Parâmetros 
    - `bx_credits_order`: Struct do bx_credits_order (pode ser %BxCreditsOrder{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_order \ %__MODULE__{}, attrs) do
    bx_credits_order
    |> cast(attrs, [:profile_id, :bundle_id, :count, :order, :license, :type, :added, :expired, :new])
    |> validate_required([:order, :license, :type])
  end

  @doc """
  Changeset para atualização de um bx_credits_order existente.

  ## Parâmetros 
    - `bx_credits_order`: Struct do bx_credits_order (%BxCreditsOrder{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_order \ %__MODULE__{}, attrs) do
    bx_credits_order
    |> cast(attrs, [:profile_id, :bundle_id, :count, :order, :license, :type, :added, :expired, :new])
  end
end
