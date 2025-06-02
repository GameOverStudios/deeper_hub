defmodule DeeperHub.Schema.BxPhotosFavoritesTrack do
  @moduledoc """
  Schema para representação de bx_photos_favorites_tracks no sistema

  Este schema armazena as informações de um bx_photos_favorites_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_photos_favorites_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :list_id, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_photos_favorites_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    list_id: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_photos_favorites_track.

  ## Parâmetros 
    - `bx_photos_favorites_track`: Struct do bx_photos_favorites_track (pode ser %BxPhotosFavoritesTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_photos_favorites_track \ %__MODULE__{}, attrs) do
    bx_photos_favorites_track
    |> cast(attrs, [:object_id, :author_id, :list_id, :date])
  end

  @doc """
  Changeset para atualização de um bx_photos_favorites_track existente.

  ## Parâmetros 
    - `bx_photos_favorites_track`: Struct do bx_photos_favorites_track (%BxPhotosFavoritesTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_photos_favorites_track \ %__MODULE__{}, attrs) do
    bx_photos_favorites_track
    |> cast(attrs, [:object_id, :author_id, :list_id, :date])
  end
end
