defmodule DeeperHub.Schema.SysObjectsLiveUpdate do
  @moduledoc """
  Schema para representação de sys_objects_live_updates no sistema

  Este schema armazena as informações de um sys_objects_live_update.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_live_updates" do
    field :name, :string, default: ""  # varchar(50)
    field :init, :integer, default: 0  # tinyint(4)
    field :frequency, :integer, default: 1  # tinyint(4)
    field :service_call, :string, default: "''"  # text
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_live_update no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    init: integer() | nil,
    frequency: integer() | nil,
    service_call: String.t() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_live_update.

  ## Parâmetros 
    - `sys_objects_live_update`: Struct do sys_objects_live_update (pode ser %SysObjectsLiveUpdate{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_live_update \ %__MODULE__{}, attrs) do
    sys_objects_live_update
    |> cast(attrs, [:name, :init, :frequency, :service_call, :active])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_objects_live_update existente.

  ## Parâmetros 
    - `sys_objects_live_update`: Struct do sys_objects_live_update (%SysObjectsLiveUpdate{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_live_update \ %__MODULE__{}, attrs) do
    sys_objects_live_update
    |> cast(attrs, [:name, :init, :frequency, :service_call, :active])
    |> unique_constraint(:name)
  end
end
