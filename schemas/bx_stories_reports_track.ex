defmodule DeeperHub.Schema.BxStoriesReportsTrack do
  @moduledoc """
  Schema para representação de bx_stories_reports_tracks no sistema

  Este schema armazena as informações de um bx_stories_reports_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_stories_reports_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :type, :string, default: ""  # varchar(32)
    field :text, :string, default: "''"  # text
    field :date, :integer, default: 0  # int(11)
    field :checked_by, :integer, default: 0  # int(11)
    field :status, :integer, default: 0  # tinyint(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_stories_reports_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    type: String.t() | nil,
    text: String.t() | nil,
    date: integer() | nil,
    checked_by: integer() | nil,
    status: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_stories_reports_track.

  ## Parâmetros 
    - `bx_stories_reports_track`: Struct do bx_stories_reports_track (pode ser %BxStoriesReportsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_stories_reports_track \ %__MODULE__{}, attrs) do
    bx_stories_reports_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :type, :text, :date, :checked_by, :status])
    |> validate_required([:type])
  end

  @doc """
  Changeset para atualização de um bx_stories_reports_track existente.

  ## Parâmetros 
    - `bx_stories_reports_track`: Struct do bx_stories_reports_track (%BxStoriesReportsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_stories_reports_track \ %__MODULE__{}, attrs) do
    bx_stories_reports_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :type, :text, :date, :checked_by, :status])
  end
end
