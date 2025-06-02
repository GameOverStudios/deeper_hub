defmodule DeeperHub.Schema.BxAlbumsFiles2album do
  @moduledoc """
  Schema para representação de bx_albums_files2albums no sistema

  Este schema armazena as informações de um bx_albums_files2album.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_albums_files2albums" do
    field :content_id, :integer  # int(10) unsigned
    field :file_id, :integer  # int(11)
    field :author, :integer  # int(10) unsigned
    field :title, :string  # varchar(255)
    field :views, :integer  # int(11)
    field :rate, :float  # float
    field :votes, :integer  # int(11)
    field :score, :integer, default: 0  # int(11)
    field :sc_up, :integer, default: 0  # int(11)
    field :sc_down, :integer, default: 0  # int(11)
    field :favorites, :integer, default: 0  # int(11)
    field :comments, :integer  # int(11)
    field :reports, :integer, default: 0  # int(11)
    field :featured, :integer, default: 0  # int(11)
    field :cf, :integer, default: 1  # int(11)
    field :data, :string  # text
    field :exif, :string  # text
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_albums_files2album no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    file_id: integer() | nil,
    author: integer() | nil,
    title: String.t() | nil,
    views: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    score: integer() | nil,
    sc_up: integer() | nil,
    sc_down: integer() | nil,
    favorites: integer() | nil,
    comments: integer() | nil,
    reports: integer() | nil,
    featured: integer() | nil,
    cf: integer() | nil,
    data: String.t() | nil,
    exif: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_albums_files2album.

  ## Parâmetros 
    - `bx_albums_files2album`: Struct do bx_albums_files2album (pode ser %BxAlbumsFiles2album{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_albums_files2album \ %__MODULE__{}, attrs) do
    bx_albums_files2album
    |> cast(attrs, [:content_id, :file_id, :author, :title, :views, :rate, :votes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :data, :exif, :order])
    |> validate_required([:content_id, :file_id, :author, :title, :views, :rate, :votes, :comments, :data, :exif, :order])
  end

  @doc """
  Changeset para atualização de um bx_albums_files2album existente.

  ## Parâmetros 
    - `bx_albums_files2album`: Struct do bx_albums_files2album (%BxAlbumsFiles2album{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_albums_files2album \ %__MODULE__{}, attrs) do
    bx_albums_files2album
    |> cast(attrs, [:content_id, :file_id, :author, :title, :views, :rate, :votes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :data, :exif, :order])
  end
end
