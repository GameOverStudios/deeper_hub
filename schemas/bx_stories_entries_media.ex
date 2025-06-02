defmodule DeeperHub.Schema.BxStoriesEntriesMedia do
  @moduledoc """
  Schema para representação de bx_stories_entries_medias no sistema

  Este schema armazena as informações de um bx_stories_entries_media.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_stories_entries_media" do
    field :content_id, :integer  # int(11) unsigned
    field :file_id, :integer  # int(11)
    field :author, :integer  # int(10) unsigned
    field :title, :string  # varchar(255)
    field :cf, :integer, default: 1  # int(11)
    field :data, :string  # text
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_stories_entries_media no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    file_id: integer() | nil,
    author: integer() | nil,
    title: String.t() | nil,
    cf: integer() | nil,
    data: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_stories_entries_media.

  ## Parâmetros 
    - `bx_stories_entries_media`: Struct do bx_stories_entries_media (pode ser %BxStoriesEntriesMedia{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_stories_entries_media \ %__MODULE__{}, attrs) do
    bx_stories_entries_media
    |> cast(attrs, [:content_id, :file_id, :author, :title, :cf, :data, :order])
    |> validate_required([:content_id, :file_id, :author, :title, :data, :order])
  end

  @doc """
  Changeset para atualização de um bx_stories_entries_media existente.

  ## Parâmetros 
    - `bx_stories_entries_media`: Struct do bx_stories_entries_media (%BxStoriesEntriesMedia{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_stories_entries_media \ %__MODULE__{}, attrs) do
    bx_stories_entries_media
    |> cast(attrs, [:content_id, :file_id, :author, :title, :cf, :data, :order])
  end
end
