defmodule DeeperHub.Schema.SysAgentsProvider do
  @moduledoc """
  Schema para representação de sys_agents_providers no sistema

  Este schema armazena as informações de um sys_agents_provider.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_providers" do
    field :name, :string, default: ""  # varchar(128)
    field :type_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_provider no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    type_id: integer() | nil,
    profile_id: integer() | nil,
    added: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_provider.

  ## Parâmetros 
    - `sys_agents_provider`: Struct do sys_agents_provider (pode ser %SysAgentsProvider{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_provider \ %__MODULE__{}, attrs) do
    sys_agents_provider
    |> cast(attrs, [:name, :type_id, :profile_id, :added, :active])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_agents_provider existente.

  ## Parâmetros 
    - `sys_agents_provider`: Struct do sys_agents_provider (%SysAgentsProvider{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_provider \ %__MODULE__{}, attrs) do
    sys_agents_provider
    |> cast(attrs, [:name, :type_id, :profile_id, :added, :active])
    |> unique_constraint(:name)
  end
end
