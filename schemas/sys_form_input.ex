defmodule DeeperHub.Schema.SysFormInput do
  @moduledoc """
  Schema para representação de sys_form_inputs no sistema

  Este schema armazena as informações de um sys_form_input.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_inputs" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :name, :string  # varchar(255)
    field :value, :string  # varchar(255)
    field :values, :string  # text
    field :checked, :integer, default: 0  # tinyint(4)
    field :type, :string  # varchar(32)
    field :caption_system, :string  # varchar(255)
    field :caption, :string  # varchar(255)
    field :info, :string  # varchar(255)
    field :help, :string  # varchar(255)
    field :icon, :string  # text
    field :required, :integer, default: 0  # tinyint(4)
    field :unique, :integer, default: 0  # tinyint(4)
    field :collapsed, :integer, default: 0  # tinyint(4)
    field :html, :integer, default: 0  # tinyint(4)
    field :privacy, :integer, default: 0  # tinyint(4)
    field :rateable, :string, default: ""  # varchar(32)
    field :attrs, :string  # text
    field :attrs_tr, :string  # text
    field :attrs_wrapper, :string  # text
    field :checker_func, :string  # varchar(32)
    field :checker_params, :string  # text
    field :checker_error, :string  # varchar(255)
    field :db_pass, :string  # varchar(32)
    field :db_params, :string  # text
    field :editable, :integer, default: 1  # tinyint(4)
    field :deletable, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_input no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    name: String.t() | nil,
    value: String.t() | nil,
    values: String.t() | nil,
    checked: integer() | nil,
    type: String.t() | nil,
    caption_system: String.t() | nil,
    caption: String.t() | nil,
    info: String.t() | nil,
    help: String.t() | nil,
    icon: String.t() | nil,
    required: integer() | nil,
    unique: integer() | nil,
    collapsed: integer() | nil,
    html: integer() | nil,
    privacy: integer() | nil,
    rateable: String.t() | nil,
    attrs: String.t() | nil,
    attrs_tr: String.t() | nil,
    attrs_wrapper: String.t() | nil,
    checker_func: String.t() | nil,
    checker_params: String.t() | nil,
    checker_error: String.t() | nil,
    db_pass: String.t() | nil,
    db_params: String.t() | nil,
    editable: integer() | nil,
    deletable: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_input.

  ## Parâmetros 
    - `sys_form_input`: Struct do sys_form_input (pode ser %SysFormInput{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_input \ %__MODULE__{}, attrs) do
    sys_form_input
    |> cast(attrs, [:object, :module, :name, :value, :values, :checked, :type, :caption_system, :caption, :info, :help, :icon, :required, :unique, :collapsed, :html, :privacy, :rateable, :attrs, :attrs_tr, :attrs_wrapper, :checker_func, :checker_params, :checker_error, :db_pass, :db_params, :editable, :deletable])
    |> validate_required([:object, :module, :name, :value, :values, :type, :caption_system, :caption, :info, :help, :icon, :rateable, :attrs, :attrs_tr, :attrs_wrapper, :checker_func, :checker_params, :checker_error, :db_pass, :db_params])
  end

  @doc """
  Changeset para atualização de um sys_form_input existente.

  ## Parâmetros 
    - `sys_form_input`: Struct do sys_form_input (%SysFormInput{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_input \ %__MODULE__{}, attrs) do
    sys_form_input
    |> cast(attrs, [:object, :module, :name, :value, :values, :checked, :type, :caption_system, :caption, :info, :help, :icon, :required, :unique, :collapsed, :html, :privacy, :rateable, :attrs, :attrs_tr, :attrs_wrapper, :checker_func, :checker_params, :checker_error, :db_pass, :db_params, :editable, :deletable])
  end
end
