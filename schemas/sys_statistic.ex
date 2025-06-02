defmodule DeeperHub.Schema.SysStatistic do
  @moduledoc """
  Schema para representação de sys_statistics no sistema

  Este schema armazena as informações de um sys_statistic.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_statistics" do
    field :module, :string, default: ""  # varchar(32)
    field :name, :string, default: ""  # varchar(64)
    field :title, :string, default: ""  # varchar(255)
    field :link, :string, default: ""  # varchar(255)
    field :icon, :string, default: ""  # varchar(32)
    field :query, :string, default: "''"  # text
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_statistic no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    link: String.t() | nil,
    icon: String.t() | nil,
    query: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_statistic.

  ## Parâmetros 
    - `sys_statistic`: Struct do sys_statistic (pode ser %SysStatistic{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_statistic \ %__MODULE__{}, attrs) do
    sys_statistic
    |> cast(attrs, [:module, :name, :title, :link, :icon, :query, :order])
    |> validate_required([:module, :name, :title, :link, :icon])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_statistic existente.

  ## Parâmetros 
    - `sys_statistic`: Struct do sys_statistic (%SysStatistic{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_statistic \ %__MODULE__{}, attrs) do
    sys_statistic
    |> cast(attrs, [:module, :name, :title, :link, :icon, :query, :order])
    |> unique_constraint(:name)
  end
end
