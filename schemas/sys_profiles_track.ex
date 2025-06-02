defmodule DeeperHub.Schema.SysProfilesTrack do
  @moduledoc """
  Schema para representação de sys_profiles_tracks no sistema

  Este schema armazena as informações de um sys_profiles_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_profiles_track" do
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :action, :string, default: ""  # varchar(32)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_profiles_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    action: String.t() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_profiles_track.

  ## Parâmetros 
    - `sys_profiles_track`: Struct do sys_profiles_track (pode ser %SysProfilesTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_profiles_track \ %__MODULE__{}, attrs) do
    sys_profiles_track
    |> cast(attrs, [:profile_id, :action, :date])
    |> validate_required([:action])
  end

  @doc """
  Changeset para atualização de um sys_profiles_track existente.

  ## Parâmetros 
    - `sys_profiles_track`: Struct do sys_profiles_track (%SysProfilesTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_profiles_track \ %__MODULE__{}, attrs) do
    sys_profiles_track
    |> cast(attrs, [:profile_id, :action, :date])
  end
end
