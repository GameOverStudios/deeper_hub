defmodule DeeperHub.Schema.BxVideosVideo do
  @moduledoc """
  Schema para representação de bx_videos_videos no sistema

  Este schema armazena as informações de um bx_videos_video.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_videos_videos" do
    field :profile_id, :integer  # int(10) unsigned
    field :remote_id, :string  # varchar(128)
    field :path, :string  # varchar(255)
    field :file_name, :string  # varchar(255)
    field :mime_type, :string  # varchar(128)
    field :ext, :string  # varchar(32)
    field :size, :integer  # bigint(20)
    field :dimensions, :string  # varchar(12)
    field :added, :integer  # int(11)
    field :modified, :integer  # int(11)
    field :private, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_videos_video no sistema
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
    dimensions: String.t() | nil,
    added: integer() | nil,
    modified: integer() | nil,
    private: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_videos_video.

  ## Parâmetros 
    - `bx_videos_video`: Struct do bx_videos_video (pode ser %BxVideosVideo{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_videos_video \ %__MODULE__{}, attrs) do
    bx_videos_video
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :dimensions, :added, :modified, :private])
    |> validate_required([:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :dimensions, :added, :modified, :private])
    |> unique_constraint(:remote_id)
  end

  @doc """
  Changeset para atualização de um bx_videos_video existente.

  ## Parâmetros 
    - `bx_videos_video`: Struct do bx_videos_video (%BxVideosVideo{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_videos_video \ %__MODULE__{}, attrs) do
    bx_videos_video
    |> cast(attrs, [:profile_id, :remote_id, :path, :file_name, :mime_type, :ext, :size, :dimensions, :added, :modified, :private])
    |> unique_constraint(:remote_id)
  end
end
