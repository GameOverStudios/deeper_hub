defmodule DeeperHub.Schema.BxMarketPhotos2product do
  @moduledoc """
  Schema para representação de bx_market_photos2products no sistema

  Este schema armazena as informações de um bx_market_photos2product.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_market_photos2products" do
    field :content_id, :integer  # int(11) unsigned
    field :file_id, :integer  # int(11)
    field :title, :string  # varchar(255)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_market_photos2product no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    file_id: integer() | nil,
    title: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_market_photos2product.

  ## Parâmetros 
    - `bx_market_photos2product`: Struct do bx_market_photos2product (pode ser %BxMarketPhotos2product{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_market_photos2product \ %__MODULE__{}, attrs) do
    bx_market_photos2product
    |> cast(attrs, [:content_id, :file_id, :title, :order])
    |> validate_required([:content_id, :file_id, :title, :order])
  end

  @doc """
  Changeset para atualização de um bx_market_photos2product existente.

  ## Parâmetros 
    - `bx_market_photos2product`: Struct do bx_market_photos2product (%BxMarketPhotos2product{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_market_photos2product \ %__MODULE__{}, attrs) do
    bx_market_photos2product
    |> cast(attrs, [:content_id, :file_id, :title, :order])
  end
end
