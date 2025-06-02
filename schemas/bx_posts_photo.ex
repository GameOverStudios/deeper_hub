defmodule DeeperHub.Schema.BxPostsPhoto do
  @moduledoc """
  Schema para representação de bx_posts_photos no sistema

  Este schema armazena as informações de um bx_posts_photo.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_posts_photos" do
    field :profile_id, :integer  # int(10) unsigned
    field :remote_id, :string  # varchar(128)
    field :path, :string  # varchar(255)
    field :file_name, :string  # varchar(255)
    field :mime_type, :string  # varchar(128)
    field :ext, :string  # varchar(32)
    field :size, :integer  # bigint(20)
    field :added, :integer  # int(11)
    field :modified, :integer  # int(11)
    field :private, :integer  # int(11)
    field :dimensions, :string  # varchar(12)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_posts_photo no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    remote_id: String.t() | nil,
    path: String.t() | nil,
    file_name: String.t() | nil,
    mime_type: String.t() | nil,
    ext: String.t() | nil,
    size: integer() | nil,
    added: integer() | nil,
    modified: integer() | nil,
    private: integer() | nil,
    dimensions: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_posts_photo.

  ## Parâmetros 
    - `bx_posts_photo`: Struct do bx_posts_photo (pode ser %BxPostsPhoto{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_posts_photo \ %__MODULE__{}, attrs) do
    bx_posts_photo
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private, :dimensions])
    |> validate_required([:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private, :dimensions])
    |> unique_constraint(:remote_id)
  end

  @doc """
  Changeset para atualização de um bx_posts_photo existente.

  ## Parâmetros 
    - `bx_posts_photo`: Struct do bx_posts_photo (%BxPostsPhoto{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_posts_photo \ %__MODULE__{}, attrs) do
    bx_posts_photo
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :added, :modified, :private, :dimensions])
    |> unique_constraint(:remote_id)
  end
end
