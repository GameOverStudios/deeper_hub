defmodule DeeperHub.Schema.BxVideosReaction do
  @moduledoc """
  Schema para representação de bx_videos_reactions no sistema

  Este schema armazena as informações de um bx_videos_reaction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_videos_reactions" do
    field :object_id, :integer, default: 0  # int(11)
    field :reaction, :string, default: ""  # varchar(32)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_videos_reaction no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    reaction: String.t() | nil,
    count: integer() | nil,
    sum: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_videos_reaction.

  ## Parâmetros 
    - `bx_videos_reaction`: Struct do bx_videos_reaction (pode ser %BxVideosReaction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_videos_reaction \ %__MODULE__{}, attrs) do
    bx_videos_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
    |> validate_required([:reaction])
  end

  @doc """
  Changeset para atualização de um bx_videos_reaction existente.

  ## Parâmetros 
    - `bx_videos_reaction`: Struct do bx_videos_reaction (%BxVideosReaction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_videos_reaction \ %__MODULE__{}, attrs) do
    bx_videos_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
  end
end
