defmodule DeeperHub.Schema.BxFilesScoresTrack do
  @moduledoc """
  Schema para representação de bx_files_scores_tracks no sistema

  Este schema armazena as informações de um bx_files_scores_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_files_scores_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :type, :string, default: ""  # varchar(8)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_files_scores_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    type: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_files_scores_track.

  ## Parâmetros 
    - `bx_files_scores_track`: Struct do bx_files_scores_track (pode ser %BxFilesScoresTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_files_scores_track \ %__MODULE__{}, attrs) do
    bx_files_scores_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :type, :date])
    |> validate_required([:type])
  end

  @doc """
  Changeset para atualização de um bx_files_scores_track existente.

  ## Parâmetros 
    - `bx_files_scores_track`: Struct do bx_files_scores_track (%BxFilesScoresTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_files_scores_track \ %__MODULE__{}, attrs) do
    bx_files_scores_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :type, :date])
  end
end
