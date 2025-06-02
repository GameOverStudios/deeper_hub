defmodule DeeperHub.Schema.SysBadge do
  @moduledoc """
  Schema para representação de sys_badges no sistema

  Este schema armazena as informações de um sys_badge.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_badges" do
    field :added, :integer  # int(11)
    field :module, :string, default: ""  # varchar(32)
    field :text, :string, default: ""  # varchar(255)
    field :icon, :string, default: "''"  # text
    field :color, :string, default: ""  # varchar(32)
    field :fontcolor, :string, default: ""  # varchar(32)
    field :is_icon_only, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_badge no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    added: integer() | nil,
    module: String.t() | nil,
    text: String.t() | nil,
    icon: String.t() | nil,
    color: String.t() | nil,
    fontcolor: String.t() | nil,
    is_icon_only: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_badge.

  ## Parâmetros 
    - `sys_badge`: Struct do sys_badge (pode ser %SysBadge{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_badge \ %__MODULE__{}, attrs) do
    sys_badge
    |> cast(attrs, [:added, :module, :text, :icon, :color, :fontcolor, :is_icon_only])
    |> validate_required([:added, :module, :text, :color, :fontcolor])
  end

  @doc """
  Changeset para atualização de um sys_badge existente.

  ## Parâmetros 
    - `sys_badge`: Struct do sys_badge (%SysBadge{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_badge \ %__MODULE__{}, attrs) do
    sys_badge
    |> cast(attrs, [:added, :module, :text, :icon, :color, :fontcolor, :is_icon_only])
  end
end
