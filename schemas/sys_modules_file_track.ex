defmodule DeeperHub.Schema.SysModulesFileTrack do
  @moduledoc """
  Schema para representação de sys_modules_file_tracks no sistema

  Este schema armazena as informações de um sys_modules_file_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_modules_file_tracks" do
    field :module_id, :integer, default: 0  # int(11) unsigned
    field :file, :string, default: ""  # varchar(255)
    field :hash, :string, default: ""  # varchar(64)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_modules_file_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module_id: integer() | nil,
    file: String.t() | nil,
    hash: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_modules_file_track.

  ## Parâmetros 
    - `sys_modules_file_track`: Struct do sys_modules_file_track (pode ser %SysModulesFileTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_modules_file_track \ %__MODULE__{}, attrs) do
    sys_modules_file_track
    |> cast(attrs, [:module_id, :file, :hash])
    |> validate_required([:file, :hash])
  end

  @doc """
  Changeset para atualização de um sys_modules_file_track existente.

  ## Parâmetros 
    - `sys_modules_file_track`: Struct do sys_modules_file_track (%SysModulesFileTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_modules_file_track \ %__MODULE__{}, attrs) do
    sys_modules_file_track
    |> cast(attrs, [:module_id, :file, :hash])
  end
end
