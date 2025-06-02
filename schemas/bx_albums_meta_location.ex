defmodule DeeperHub.Schema.BxAlbumsMetaLocation do
  @moduledoc """
  Schema para representação de bx_albums_meta_locations no sistema

  Este schema armazena as informações de um bx_albums_meta_location.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_albums_meta_locations" do
    field :object_id, :integer  # int(10) unsigned
    field :lat, :float  # double
    field :lng, :float  # double
    field :country, :string  # varchar(2)
    field :state, :string  # varchar(255)
    field :city, :string  # varchar(255)
    field :zip, :string  # varchar(255)
    field :street, :string  # varchar(255)
    field :street_number, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_albums_meta_location no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    lat: float() | nil,
    lng: float() | nil,
    country: String.t() | nil,
    state: String.t() | nil,
    city: String.t() | nil,
    zip: String.t() | nil,
    street: String.t() | nil,
    street_number: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_albums_meta_location.

  ## Parâmetros 
    - `bx_albums_meta_location`: Struct do bx_albums_meta_location (pode ser %BxAlbumsMetaLocation{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_albums_meta_location \ %__MODULE__{}, attrs) do
    bx_albums_meta_location
    |> cast(attrs, [:object_id, :lat, :lng, :country, :state, :city, :zip, :street, :street_number])
    |> validate_required([:object_id, :lat, :lng, :country, :state, :city, :zip, :street, :street_number])
  end

  @doc """
  Changeset para atualização de um bx_albums_meta_location existente.

  ## Parâmetros 
    - `bx_albums_meta_location`: Struct do bx_albums_meta_location (%BxAlbumsMetaLocation{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_albums_meta_location \ %__MODULE__{}, attrs) do
    bx_albums_meta_location
    |> cast(attrs, [:object_id, :lat, :lng, :country, :state, :city, :zip, :street, :street_number])
  end
end
