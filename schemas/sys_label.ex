defmodule DeeperHub.Schema.SysLabel do
  @moduledoc """
  Schema para representação de sys_labels no sistema

  Este schema armazena as informações de um sys_label.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_labels" do
    field :module, :string  # varchar(32)
    field :parent, :integer, default: 0  # int(11)
    field :level, :integer, default: 0  # int(11)
    field :order, :integer, default: 0  # int(11)
    field :value, :string  # varchar(128)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_label no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    parent: integer() | nil,
    level: integer() | nil,
    order: integer() | nil,
    value: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_label.

  ## Parâmetros 
    - `sys_label`: Struct do sys_label (pode ser %SysLabel{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_label \ %__MODULE__{}, attrs) do
    sys_label
    |> cast(attrs, [:module, :parent, :level, :order, :value])
    |> validate_required([:module, :value])
    |> unique_constraint(:value)
  end

  @doc """
  Changeset para atualização de um sys_label existente.

  ## Parâmetros 
    - `sys_label`: Struct do sys_label (%SysLabel{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_label \ %__MODULE__{}, attrs) do
    sys_label
    |> cast(attrs, [:module, :parent, :level, :order, :value])
    |> unique_constraint(:value)
  end
end
