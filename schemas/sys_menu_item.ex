defmodule DeeperHub.Schema.SysMenuItem do
  @moduledoc """
  Schema para representação de sys_menu_items no sistema

  Este schema armazena as informações de um sys_menu_item.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_menu_items" do
    field :parent_id, :integer, default: 0  # int(11)
    field :set_name, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :name, :string  # varchar(255)
    field :title_system, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :title_attr, :string, default: ""  # varchar(255)
    field :link, :string  # varchar(512)
    field :onclick, :string  # varchar(255)
    field :target, :string  # varchar(255)
    field :area_label, :string, default: ""  # varchar(255)
    field :icon, :string  # text
    field :icon_only, :integer, default: 0  # tinyint(4)
    field :addon, :string  # text
    field :addon_cache, :integer, default: 0  # tinyint(4)
    field :markers, :string  # text
    field :submenu_object, :string  # varchar(64)
    field :submenu_popup, :integer, default: 0  # tinyint(4)
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :visibility_custom, :string  # text
    field :hidden_on, :string, default: ""  # varchar(255)
    field :hidden_on_cxt, :string, default: ""  # varchar(255)
    field :hidden_on_pt, :integer, default: 0  # int(11)
    field :hidden_on_col, :integer, default: 0  # int(11)
    field :config_api, :string  # text
    field :primary, :integer, default: 0  # tinyint(4)
    field :collapsed, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :active_api, :integer, default: 0  # tinyint(4)
    field :copyable, :integer, default: 1  # tinyint(4)
    field :editable, :integer, default: 1  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_menu_item no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    parent_id: integer() | nil,
    set_name: String.t() | nil,
    module: String.t() | nil,
    name: String.t() | nil,
    title_system: String.t() | nil,
    title: String.t() | nil,
    title_attr: String.t() | nil,
    link: String.t() | nil,
    onclick: String.t() | nil,
    target: String.t() | nil,
    area_label: String.t() | nil,
    icon: String.t() | nil,
    icon_only: integer() | nil,
    addon: String.t() | nil,
    addon_cache: integer() | nil,
    markers: String.t() | nil,
    submenu_object: String.t() | nil,
    submenu_popup: integer() | nil,
    visible_for_levels: integer() | nil,
    visibility_custom: String.t() | nil,
    hidden_on: String.t() | nil,
    hidden_on_cxt: String.t() | nil,
    hidden_on_pt: integer() | nil,
    hidden_on_col: integer() | nil,
    config_api: String.t() | nil,
    primary: integer() | nil,
    collapsed: integer() | nil,
    active: integer() | nil,
    active_api: integer() | nil,
    copyable: integer() | nil,
    editable: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_menu_item.

  ## Parâmetros 
    - `sys_menu_item`: Struct do sys_menu_item (pode ser %SysMenuItem{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_menu_item \ %__MODULE__{}, attrs) do
    sys_menu_item
    |> cast(attrs, [:parent_id, :set_name, :module, :name, :title_system, :title, :title_attr, :link, :onclick, :target, :area_label, :icon, :icon_only, :addon, :addon_cache, :markers, :submenu_object, :submenu_popup, :visible_for_levels, :visibility_custom, :hidden_on, :hidden_on_cxt, :hidden_on_pt, :hidden_on_col, :config_api, :primary, :collapsed, :active, :active_api, :copyable, :editable, :order])
    |> validate_required([:set_name, :module, :name, :title_system, :title, :title_attr, :link, :onclick, :target, :area_label, :icon, :addon, :markers, :submenu_object, :visibility_custom, :hidden_on, :hidden_on_cxt, :config_api, :order])
  end

  @doc """
  Changeset para atualização de um sys_menu_item existente.

  ## Parâmetros 
    - `sys_menu_item`: Struct do sys_menu_item (%SysMenuItem{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_menu_item \ %__MODULE__{}, attrs) do
    sys_menu_item
    |> cast(attrs, [:parent_id, :set_name, :module, :name, :title_system, :title, :title_attr, :link, :onclick, :target, :area_label, :icon, :icon_only, :addon, :addon_cache, :markers, :submenu_object, :submenu_popup, :visible_for_levels, :visibility_custom, :hidden_on, :hidden_on_cxt, :hidden_on_pt, :hidden_on_col, :config_api, :primary, :collapsed, :active, :active_api, :copyable, :editable, :order])
  end
end
