defmodule DeeperHub.Schema.SysAgentsProvidersValue do
  @moduledoc """
  Schema para representação de sys_agents_providers_values no sistema

  Este schema armazena as informações de um sys_agents_providers_value.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_providers_values" do
    field :provider_id, :integer, default: 0  # int(11)
    field :option_id, :integer, default: 0  # int(11)
    field :value, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_providers_value no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    provider_id: integer() | nil,
    option_id: integer() | nil,
    value: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_providers_value.

  ## Parâmetros 
    - `sys_agents_providers_value`: Struct do sys_agents_providers_value (pode ser %SysAgentsProvidersValue{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_providers_value \ %__MODULE__{}, attrs) do
    sys_agents_providers_value
    |> cast(attrs, [:provider_id, :option_id, :value])
    |> validate_required([:value])
  end

  @doc """
  Changeset para atualização de um sys_agents_providers_value existente.

  ## Parâmetros 
    - `sys_agents_providers_value`: Struct do sys_agents_providers_value (%SysAgentsProvidersValue{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_providers_value \ %__MODULE__{}, attrs) do
    sys_agents_providers_value
    |> cast(attrs, [:provider_id, :option_id, :value])
  end
end
