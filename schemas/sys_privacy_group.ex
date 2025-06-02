defmodule DeeperHub.Schema.SysPrivacyGroup do
  @moduledoc """
  Schema para representação de sys_privacy_groups no sistema

  Este schema armazena as informações de um sys_privacy_group.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_privacy_groups" do
    field :title, :string, default: ""  # varchar(255)
    field :check, :string, default: "''"  # text
    field :active, :integer, default: 1  # tinyint(4)
    field :visible, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_privacy_group no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    check: String.t() | nil,
    active: integer() | nil,
    visible: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_privacy_group.

  ## Parâmetros 
    - `sys_privacy_group`: Struct do sys_privacy_group (pode ser %SysPrivacyGroup{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_privacy_group \ %__MODULE__{}, attrs) do
    sys_privacy_group
    |> cast(attrs, [:title, :check, :active, :visible, :order])
    |> validate_required([:title])
  end

  @doc """
  Changeset para atualização de um sys_privacy_group existente.

  ## Parâmetros 
    - `sys_privacy_group`: Struct do sys_privacy_group (%SysPrivacyGroup{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_privacy_group \ %__MODULE__{}, attrs) do
    sys_privacy_group
    |> cast(attrs, [:title, :check, :active, :visible, :order])
  end
end
