defmodule DeeperHub.Schema.BxCreditsOrdersDeleted do
  @moduledoc """
  Schema para representação de bx_credits_orders_deleteds no sistema

  Este schema armazena as informações de um bx_credits_orders_deleted.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_orders_deleted" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :bundle_id, :integer, default: 0  # int(11) unsigned
    field :count, :integer, default: 0  # int(11) unsigned
    field :order, :string, default: ""  # varchar(32)
    field :license, :string, default: ""  # varchar(32)
    field :type, :string, default: ""  # varchar(16)
    field :added, :integer, default: 0  # int(11) unsigned
    field :expired, :integer, default: 0  # int(11) unsigned
    field :new, :boolean, default: true  # tinyint(1)
    field :reason, :string, default: ""  # varchar(16)
    field :deleted, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_orders_deleted no sistema
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
    reason: String.t() | nil,
    deleted: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_orders_deleted.

  ## Parâmetros 
    - `bx_credits_orders_deleted`: Struct do bx_credits_orders_deleted (pode ser %BxCreditsOrdersDeleted{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_orders_deleted \ %__MODULE__{}, attrs) do
    bx_credits_orders_deleted
    |> cast(attrs, [:profile_id, :bundle_id, :count, :order, :license, :type, :added, :expired, :new, :reason, :deleted])
    |> validate_required([:order, :license, :type, :reason])
  end

  @doc """
  Changeset para atualização de um bx_credits_orders_deleted existente.

  ## Parâmetros 
    - `bx_credits_orders_deleted`: Struct do bx_credits_orders_deleted (%BxCreditsOrdersDeleted{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_orders_deleted \ %__MODULE__{}, attrs) do
    bx_credits_orders_deleted
    |> cast(attrs, [:profile_id, :bundle_id, :count, :order, :license, :type, :added, :expired, :new, :reason, :deleted])
  end
end
