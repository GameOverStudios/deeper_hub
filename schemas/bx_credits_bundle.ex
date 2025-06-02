defmodule DeeperHub.Schema.BxCreditsBundle do
  @moduledoc """
  Schema para representação de bx_credits_bundles no sistema

  Este schema armazena as informações de um bx_credits_bundle.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_credits_bundles" do
    field :added, :integer  # int(11)
    field :name, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :description, :string  # varchar(255)
    field :amount, :integer, default: 0  # int(11)
    field :bonus, :integer, default: 0  # int(11)
    field :price, :float, default: 0  # float
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_credits_bundle no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    added: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    amount: integer() | nil,
    bonus: integer() | nil,
    price: float() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_credits_bundle.

  ## Parâmetros 
    - `bx_credits_bundle`: Struct do bx_credits_bundle (pode ser %BxCreditsBundle{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_credits_bundle \ %__MODULE__{}, attrs) do
    bx_credits_bundle
    |> cast(attrs, [:added, :name, :title, :description, :amount, :bonus, :price, :active, :order])
    |> validate_required([:added, :name, :title, :description])
  end

  @doc """
  Changeset para atualização de um bx_credits_bundle existente.

  ## Parâmetros 
    - `bx_credits_bundle`: Struct do bx_credits_bundle (%BxCreditsBundle{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_credits_bundle \ %__MODULE__{}, attrs) do
    bx_credits_bundle
    |> cast(attrs, [:added, :name, :title, :description, :amount, :bonus, :price, :active, :order])
  end
end
