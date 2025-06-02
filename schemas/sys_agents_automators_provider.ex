defmodule DeeperHub.Schema.SysAgentsAutomatorsProvider do
  @moduledoc """
  Schema para representação de sys_agents_automators_providers no sistema

  Este schema armazena as informações de um sys_agents_automators_provider.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_automators_providers" do
    field :automator_id, :integer, default: 0  # int(11)
    field :provider_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_automators_provider no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    automator_id: integer() | nil,
    provider_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_automators_provider.

  ## Parâmetros 
    - `sys_agents_automators_provider`: Struct do sys_agents_automators_provider (pode ser %SysAgentsAutomatorsProvider{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_automators_provider \ %__MODULE__{}, attrs) do
    sys_agents_automators_provider
    |> cast(attrs, [:automator_id, :provider_id])
  end

  @doc """
  Changeset para atualização de um sys_agents_automators_provider existente.

  ## Parâmetros 
    - `sys_agents_automators_provider`: Struct do sys_agents_automators_provider (%SysAgentsAutomatorsProvider{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_automators_provider \ %__MODULE__{}, attrs) do
    sys_agents_automators_provider
    |> cast(attrs, [:automator_id, :provider_id])
  end
end
