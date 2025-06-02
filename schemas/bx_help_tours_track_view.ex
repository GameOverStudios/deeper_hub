defmodule DeeperHub.Schema.BxHelpToursTrackView do
  @moduledoc """
  Schema para representação de bx_help_tours_track_views no sistema

  Este schema armazena as informações de um bx_help_tours_track_view.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_help_tours_track_views" do
    field :account, :integer  # int(11)
    field :tour, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_help_tours_track_view no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account: integer() | nil,
    tour: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_help_tours_track_view.

  ## Parâmetros 
    - `bx_help_tours_track_view`: Struct do bx_help_tours_track_view (pode ser %BxHelpToursTrackView{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_help_tours_track_view \ %__MODULE__{}, attrs) do
    bx_help_tours_track_view
    |> cast(attrs, [:account, :tour])
    |> validate_required([:account, :tour])
  end

  @doc """
  Changeset para atualização de um bx_help_tours_track_view existente.

  ## Parâmetros 
    - `bx_help_tours_track_view`: Struct do bx_help_tours_track_view (%BxHelpToursTrackView{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_help_tours_track_view \ %__MODULE__{}, attrs) do
    bx_help_tours_track_view
    |> cast(attrs, [:account, :tour])
  end
end
