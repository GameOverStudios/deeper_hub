defmodule DeeperHub.Schema.SysAgentsModel do
  @moduledoc """
  Schema para representação de sys_agents_models no sistema

  Este schema armazena as informações de um sys_agents_model.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_agents_models" do
    field :name, :string, default: ""  # varchar(32)
    field :title, :string, default: ""  # varchar(64)
    field :key, :string, default: ""  # varchar(64)
    field :params, :string  # text
    field :for_asst, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :hidden, :integer, default: 0  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(128)
    field :class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_agents_model no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    key: String.t() | nil,
    params: String.t() | nil,
    for_asst: integer() | nil,
    active: integer() | nil,
    hidden: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_agents_model.

  ## Parâmetros 
    - `sys_agents_model`: Struct do sys_agents_model (pode ser %SysAgentsModel{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_agents_model \ %__MODULE__{}, attrs) do
    sys_agents_model
    |> cast(attrs, [:name, :title, :key, :params, :for_asst, :active, :hidden, :class_name, :class_file])
    |> validate_required([:name, :title, :key, :params, :class_name, :class_file])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_agents_model existente.

  ## Parâmetros 
    - `sys_agents_model`: Struct do sys_agents_model (%SysAgentsModel{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_agents_model \ %__MODULE__{}, attrs) do
    sys_agents_model
    |> cast(attrs, [:name, :title, :key, :params, :for_asst, :active, :hidden, :class_name, :class_file])
    |> unique_constraint(:name)
  end
end
