defmodule DeeperHub.Schema.SysOptionsMixe do
  @moduledoc """
  Schema para representação de sys_options_mixes no sistema

  Este schema armazena as informações de um sys_options_mixe.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_options_mixes" do
    field :type, :string, default: ""  # varchar(64)
    field :category, :string, default: ""  # varchar(64)
    field :name, :string, default: ""  # varchar(64)
    field :title, :string, default: ""  # varchar(64)
    field :dark, :boolean, default: false  # tinyint(1)
    field :active, :boolean, default: false  # tinyint(1)
    field :published, :boolean, default: false  # tinyint(1)
    field :editable, :boolean, default: true  # tinyint(1)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_options_mixe no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    type: String.t() | nil,
    category: String.t() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    dark: boolean() | nil,
    active: boolean() | nil,
    published: boolean() | nil,
    editable: boolean() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_options_mixe.

  ## Parâmetros 
    - `sys_options_mixe`: Struct do sys_options_mixe (pode ser %SysOptionsMixe{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_options_mixe \ %__MODULE__{}, attrs) do
    sys_options_mixe
    |> cast(attrs, [:type, :category, :name, :title, :dark, :active, :published, :editable])
    |> validate_required([:type, :category, :name, :title])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_options_mixe existente.

  ## Parâmetros 
    - `sys_options_mixe`: Struct do sys_options_mixe (%SysOptionsMixe{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_options_mixe \ %__MODULE__{}, attrs) do
    sys_options_mixe
    |> cast(attrs, [:type, :category, :name, :title, :dark, :active, :published, :editable])
    |> unique_constraint(:name)
  end
end
