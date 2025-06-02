defmodule DeeperHub.Schema.SysAgentsHelper do
  @moduledoc """
  Schema para representação de sys_agents_helpers no sistema

  Este schema armazena as informações de um sys_agents_helper.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_helpers" do
    field :name, :string  # varchar(128)
    field :model_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)
    field :description, :string  # text
    field :prompt, :string  # text
    field :added, :integer, default: 0  # int(11)
    field :active, :integer, default: 0  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_helper no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    model_id: integer() | nil,
    profile_id: integer() | nil,
    description: String.t() | nil,
    prompt: String.t() | nil,
    added: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_helper.

  ## Parâmetros 
    - `sys_agents_helper`: Struct do sys_agents_helper (pode ser %SysAgentsHelper{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_helper \ %__MODULE__{}, attrs) do
    sys_agents_helper
    |> cast(attrs, [:name, :model_id, :profile_id, :description, :prompt, :added, :active])
    |> validate_required([:description])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_agents_helper existente.

  ## Parâmetros 
    - `sys_agents_helper`: Struct do sys_agents_helper (%SysAgentsHelper{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_helper \ %__MODULE__{}, attrs) do
    sys_agents_helper
    |> cast(attrs, [:name, :model_id, :profile_id, :description, :prompt, :added, :active])
    |> unique_constraint(:name)
  end
end
