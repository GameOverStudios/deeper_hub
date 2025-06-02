defmodule DeeperHub.Schema.BxPersonsViewsTrack do
  @moduledoc """
  Schema para representação de bx_persons_views_tracks no sistema

  Este schema armazena as informações de um bx_persons_views_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_persons_views_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :viewer_id, :integer, default: 0  # int(11)
    field :viewer_nip, :integer, default: 0  # int(11) unsigned
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_persons_views_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    viewer_id: integer() | nil,
    viewer_nip: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_persons_views_track.

  ## Parâmetros 
    - `bx_persons_views_track`: Struct do bx_persons_views_track (pode ser %BxPersonsViewsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_persons_views_track \ %__MODULE__{}, attrs) do
    bx_persons_views_track
    |> cast(attrs, [:object_id, :viewer_id, :viewer_nip, :date])
  end

  @doc """
  Changeset para atualização de um bx_persons_views_track existente.

  ## Parâmetros 
    - `bx_persons_views_track`: Struct do bx_persons_views_track (%BxPersonsViewsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_persons_views_track \ %__MODULE__{}, attrs) do
    bx_persons_views_track
    |> cast(attrs, [:object_id, :viewer_id, :viewer_nip, :date])
  end
end
