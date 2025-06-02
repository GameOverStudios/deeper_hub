defmodule DeeperHub.Schema.SysCmtsReactionsTrack do
  @moduledoc """
  Schema para representação de sys_cmts_reactions_tracks no sistema

  Este schema armazena as informações de um sys_cmts_reactions_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_reactions_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :reaction, :string, default: ""  # varchar(32)
    field :value, :integer, default: 0  # tinyint(4)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_reactions_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    reaction: String.t() | nil,
    value: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_reactions_track.

  ## Parâmetros 
    - `sys_cmts_reactions_track`: Struct do sys_cmts_reactions_track (pode ser %SysCmtsReactionsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_reactions_track \ %__MODULE__{}, attrs) do
    sys_cmts_reactions_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :reaction, :value, :date])
    |> validate_required([:reaction])
  end

  @doc """
  Changeset para atualização de um sys_cmts_reactions_track existente.

  ## Parâmetros 
    - `sys_cmts_reactions_track`: Struct do sys_cmts_reactions_track (%SysCmtsReactionsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_reactions_track \ %__MODULE__{}, attrs) do
    sys_cmts_reactions_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :reaction, :value, :date])
  end
end
