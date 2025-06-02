defmodule DeeperHub.Schema.SysModulesRelation do
  @moduledoc """
  Schema para representação de sys_modules_relations no sistema

  Este schema armazena as informações de um sys_modules_relation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_modules_relations" do
    field :module, :string, default: ""  # varchar(32)
    field :on_install, :string, default: ""  # varchar(255)
    field :on_uninstall, :string, default: ""  # varchar(255)
    field :on_enable, :string, default: ""  # varchar(255)
    field :on_disable, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_modules_relation no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    on_install: String.t() | nil,
    on_uninstall: String.t() | nil,
    on_enable: String.t() | nil,
    on_disable: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_modules_relation.

  ## Parâmetros 
    - `sys_modules_relation`: Struct do sys_modules_relation (pode ser %SysModulesRelation{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_modules_relation \ %__MODULE__{}, attrs) do
    sys_modules_relation
    |> cast(attrs, [:module, :on_install, :on_uninstall, :on_enable, :on_disable])
    |> validate_required([:module, :on_install, :on_uninstall, :on_enable, :on_disable])
  end

  @doc """
  Changeset para atualização de um sys_modules_relation existente.

  ## Parâmetros 
    - `sys_modules_relation`: Struct do sys_modules_relation (%SysModulesRelation{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_modules_relation \ %__MODULE__{}, attrs) do
    sys_modules_relation
    |> cast(attrs, [:module, :on_install, :on_uninstall, :on_enable, :on_disable])
  end
end
