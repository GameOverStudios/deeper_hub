defmodule DeeperHub.Schema.BxVideosEmbedsProvider do
  @moduledoc """
  Schema para representação de bx_videos_embeds_providers no sistema

  Este schema armazena as informações de um bx_videos_embeds_provider.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_videos_embeds_providers" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(64)
    field :params, :string  # text
    field :class_name, :string  # varchar(255)
    field :class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_videos_embeds_provider no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    params: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_videos_embeds_provider.

  ## Parâmetros 
    - `bx_videos_embeds_provider`: Struct do bx_videos_embeds_provider (pode ser %BxVideosEmbedsProvider{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_videos_embeds_provider \ %__MODULE__{}, attrs) do
    bx_videos_embeds_provider
    |> cast(attrs, [:object, :module, :params, :class_name, :class_file])
    |> validate_required([:object, :module, :params, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um bx_videos_embeds_provider existente.

  ## Parâmetros 
    - `bx_videos_embeds_provider`: Struct do bx_videos_embeds_provider (%BxVideosEmbedsProvider{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_videos_embeds_provider \ %__MODULE__{}, attrs) do
    bx_videos_embeds_provider
    |> cast(attrs, [:object, :module, :params, :class_name, :class_file])
  end
end
