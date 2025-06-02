defmodule DeeperHub.Schema.SysFormPreList do
  @moduledoc """
  Schema para representação de sys_form_pre_lists no sistema

  Este schema armazena as informações de um sys_form_pre_list.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_pre_lists" do
    field :module, :string, default: ""  # varchar(32)
    field :key, :string, default: ""  # varchar(255)
    field :title, :string, default: ""  # varchar(255)
    field :use_for_sets, :integer, default: 1  # tinyint(4) unsigned
    field :extendable, :integer, default: 1  # tinyint(4) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_pre_list no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    key: String.t() | nil,
    title: String.t() | nil,
    use_for_sets: integer() | nil,
    extendable: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_pre_list.

  ## Parâmetros 
    - `sys_form_pre_list`: Struct do sys_form_pre_list (pode ser %SysFormPreList{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_pre_list \ %__MODULE__{}, attrs) do
    sys_form_pre_list
    |> cast(attrs, [:module, :key, :title, :use_for_sets, :extendable])
    |> validate_required([:module, :key, :title])
    |> unique_constraint(:key)
  end

  @doc """
  Changeset para atualização de um sys_form_pre_list existente.

  ## Parâmetros 
    - `sys_form_pre_list`: Struct do sys_form_pre_list (%SysFormPreList{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_pre_list \ %__MODULE__{}, attrs) do
    sys_form_pre_list
    |> cast(attrs, [:module, :key, :title, :use_for_sets, :extendable])
    |> unique_constraint(:key)
  end
end
