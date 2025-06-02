defmodule DeeperHub.Schema.SysAgentsProviderType do
  @moduledoc """
  Schema para representação de sys_agents_provider_types no sistema

  Este schema armazena as informações de um sys_agents_provider_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_provider_types" do
    field :name, :string, default: ""  # varchar(64)
    field :title, :string, default: ""  # varchar(128)
    field :option_prefix, :string, default: ""  # varchar(32)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(128)
    field :class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_provider_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    option_prefix: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_provider_type.

  ## Parâmetros 
    - `sys_agents_provider_type`: Struct do sys_agents_provider_type (pode ser %SysAgentsProviderType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_provider_type \ %__MODULE__{}, attrs) do
    sys_agents_provider_type
    |> cast(attrs, [:name, :title, :option_prefix, :active, :order, :class_name, :class_file])
    |> validate_required([:name, :title, :option_prefix, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_agents_provider_type existente.

  ## Parâmetros 
    - `sys_agents_provider_type`: Struct do sys_agents_provider_type (%SysAgentsProviderType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_provider_type \ %__MODULE__{}, attrs) do
    sys_agents_provider_type
    |> cast(attrs, [:name, :title, :option_prefix, :active, :order, :class_name, :class_file])
  end
end
