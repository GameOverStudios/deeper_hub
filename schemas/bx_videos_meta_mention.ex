defmodule DeeperHub.Schema.BxVideosMetaMention do
  @moduledoc """
  Schema para representação de bx_videos_meta_mentions no sistema

  Este schema armazena as informações de um bx_videos_meta_mention.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_videos_meta_mentions" do
    field :object_id, :integer  # int(10) unsigned
    field :profile_id, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_videos_meta_mention no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    profile_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_videos_meta_mention.

  ## Parâmetros 
    - `bx_videos_meta_mention`: Struct do bx_videos_meta_mention (pode ser %BxVideosMetaMention{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_videos_meta_mention \ %__MODULE__{}, attrs) do
    bx_videos_meta_mention
    |> cast(attrs, [:object_id, :profile_id])
    |> validate_required([:object_id, :profile_id])
  end

  @doc """
  Changeset para atualização de um bx_videos_meta_mention existente.

  ## Parâmetros 
    - `bx_videos_meta_mention`: Struct do bx_videos_meta_mention (%BxVideosMetaMention{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_videos_meta_mention \ %__MODULE__{}, attrs) do
    bx_videos_meta_mention
    |> cast(attrs, [:object_id, :profile_id])
  end
end
