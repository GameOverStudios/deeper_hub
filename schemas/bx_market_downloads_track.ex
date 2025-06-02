defmodule DeeperHub.Schema.BxMarketDownloadsTrack do
  @moduledoc """
  Schema para representação de bx_market_downloads_tracks no sistema

  Este schema armazena as informações de um bx_market_downloads_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_market_downloads_track" do
    field :file_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :profile_nip, :integer, default: 0  # int(11) unsigned
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_market_downloads_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    file_id: integer() | nil,
    profile_id: integer() | nil,
    profile_nip: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_market_downloads_track.

  ## Parâmetros 
    - `bx_market_downloads_track`: Struct do bx_market_downloads_track (pode ser %BxMarketDownloadsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_market_downloads_track \ %__MODULE__{}, attrs) do
    bx_market_downloads_track
    |> cast(attrs, [:file_id, :profile_id, :profile_nip, :date])
  end

  @doc """
  Changeset para atualização de um bx_market_downloads_track existente.

  ## Parâmetros 
    - `bx_market_downloads_track`: Struct do bx_market_downloads_track (%BxMarketDownloadsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_market_downloads_track \ %__MODULE__{}, attrs) do
    bx_market_downloads_track
    |> cast(attrs, [:file_id, :profile_id, :profile_nip, :date])
  end
end
