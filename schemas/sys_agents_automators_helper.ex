defmodule DeeperHub.Schema.SysAgentsAutomatorsHelper do
  @moduledoc """
  Schema para representação de sys_agents_automators_helpers no sistema

  Este schema armazena as informações de um sys_agents_automators_helper.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_automators_helpers" do
    field :automator_id, :integer, default: 0  # int(11)
    field :helper_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_automators_helper no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    automator_id: integer() | nil,
    helper_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_automators_helper.

  ## Parâmetros 
    - `sys_agents_automators_helper`: Struct do sys_agents_automators_helper (pode ser %SysAgentsAutomatorsHelper{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_automators_helper \ %__MODULE__{}, attrs) do
    sys_agents_automators_helper
    |> cast(attrs, [:automator_id, :helper_id])
  end

  @doc """
  Changeset para atualização de um sys_agents_automators_helper existente.

  ## Parâmetros 
    - `sys_agents_automators_helper`: Struct do sys_agents_automators_helper (%SysAgentsAutomatorsHelper{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_automators_helper \ %__MODULE__{}, attrs) do
    sys_agents_automators_helper
    |> cast(attrs, [:automator_id, :helper_id])
  end
end
