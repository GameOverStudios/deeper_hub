defmodule DeeperHub.Schema.SysOption do
  @moduledoc """
  Schema para representação de sys_options no sistema

  Este schema armazena as informações de um sys_option.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_options" do
    field :category_id, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(255)
    field :info, :string, default: ""  # varchar(255)
    field :value, :string  # mediumtext
    field :type, Ecto.Enum, values: [:value, :digit, :text, :code, :checkbox, :select, :combobox, :file, :image, :list, :rlist, :rgb, :rgba, :datetime], default: "digit"  # enum('value','digit','text','code','checkbox','select','combobox','file','image','list','rlist','rgb','rgba','datetime')
    field :extra, :string, default: "''"  # text
    field :check, :string  # varchar(32)
    field :check_params, :string  # text
    field :check_error, :string, default: ""  # varchar(255)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_option no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    category_id: integer() | nil,
    name: String.t() | nil,
    caption: String.t() | nil,
    info: String.t() | nil,
    value: String.t() | nil,
    type: :value | :digit | :text | :code | :checkbox | :select | :combobox | :file | :image | :list | :rlist | :rgb | :rgba | :datetime | nil,
    extra: String.t() | nil,
    check: String.t() | nil,
    check_params: String.t() | nil,
    check_error: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_option.

  ## Parâmetros 
    - `sys_option`: Struct do sys_option (pode ser %SysOption{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_option \ %__MODULE__{}, attrs) do
    sys_option
    |> cast(attrs, [:category_id, :name, :caption, :info, :value, :type, :extra, :check, :check_params, :check_error, :order])
    |> validate_required([:name, :caption, :info, :value, :check, :check_params, :check_error])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_option existente.

  ## Parâmetros 
    - `sys_option`: Struct do sys_option (%SysOption{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_option \ %__MODULE__{}, attrs) do
    sys_option
    |> cast(attrs, [:category_id, :name, :caption, :info, :value, :type, :extra, :check, :check_params, :check_error, :order])
    |> unique_constraint(:name)
  end
end
