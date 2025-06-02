defmodule DeeperHub.Schema.BxAlbumsMetaKeywordsMedia do
  @moduledoc """
  Schema para representação de bx_albums_meta_keywords_medias no sistema

  Este schema armazena as informações de um bx_albums_meta_keywords_media.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_albums_meta_keywords_media" do
    field :object_id, :integer  # int(10) unsigned
    field :keyword, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_albums_meta_keywords_media no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    keyword: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_albums_meta_keywords_media.

  ## Parâmetros 
    - `bx_albums_meta_keywords_media`: Struct do bx_albums_meta_keywords_media (pode ser %BxAlbumsMetaKeywordsMedia{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_albums_meta_keywords_media \ %__MODULE__{}, attrs) do
    bx_albums_meta_keywords_media
    |> cast(attrs, [:object_id, :keyword])
    |> validate_required([:object_id, :keyword])
  end

  @doc """
  Changeset para atualização de um bx_albums_meta_keywords_media existente.

  ## Parâmetros 
    - `bx_albums_meta_keywords_media`: Struct do bx_albums_meta_keywords_media (%BxAlbumsMetaKeywordsMedia{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_albums_meta_keywords_media \ %__MODULE__{}, attrs) do
    bx_albums_meta_keywords_media
    |> cast(attrs, [:object_id, :keyword])
  end
end
