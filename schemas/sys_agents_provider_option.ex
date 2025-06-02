defmodule DeeperHub.Schema.SysAgentsProviderOption do
  @moduledoc """
  Schema para representação de sys_agents_provider_options no sistema

  Este schema armazena as informações de um sys_agents_provider_option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_provider_options" do
    field :provider_type_id, :integer, default: 0  # int(11)
    field :name, :string, default: ""  # varchar(64)
    field :type, :string, default: "text"  # varchar(64)
    field :title, :string, default: ""  # varchar(255)
    field :description, :string, default: "''"  # text
    field :extra, :string, default: ""  # varchar(255)
    field :check_type, :string, default: ""  # varchar(64)
    field :check_params, :string, default: ""  # varchar(128)
    field :check_error, :string, default: ""  # varchar(128)
    field :order, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_provider_option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    provider_type_id: integer() | nil,
    name: String.t() | nil,
    type: String.t() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    extra: String.t() | nil,
    check_type: String.t() | nil,
    check_params: String.t() | nil,
    check_error: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_provider_option.

  ## Parâmetros 
    - `sys_agents_provider_option`: Struct do sys_agents_provider_option (pode ser %SysAgentsProviderOption{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_provider_option \ %__MODULE__{}, attrs) do
    sys_agents_provider_option
    |> cast(attrs, [:provider_type_id, :name, :type, :title, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> validate_required([:name, :title, :extra, :check_type, :check_params, :check_error])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_agents_provider_option existente.

  ## Parâmetros 
    - `sys_agents_provider_option`: Struct do sys_agents_provider_option (%SysAgentsProviderOption{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_provider_option \ %__MODULE__{}, attrs) do
    sys_agents_provider_option
    |> cast(attrs, [:provider_type_id, :name, :type, :title, :description, :extra, :check_type, :check_params, :check_error, :order])
    |> unique_constraint(:name)
  end
end
