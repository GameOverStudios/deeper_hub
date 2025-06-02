defmodule DeeperHub.Schema.SysObjectsPage do
  @moduledoc """
  Schema para representação de sys_objects_pages no sistema

  Este schema armazena as informações de um sys_objects_page.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_page" do
    field :author, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)
    field :object, :string  # varchar(64)
    field :uri, :string  # varchar(255)
    field :title_system, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :module, :string  # varchar(32)
    field :cover, :integer, default: 1  # tinyint(4)
    field :cover_image, :integer, default: 0  # int(11)
    field :cover_title, :string, default: ""  # varchar(255)
    field :type_id, :integer, default: 1  # int(11)
    field :layout_id, :integer  # int(11)
    field :sticky_columns, :integer, default: 0  # tinyint(4)
    field :submenu, :string, default: ""  # varchar(64)
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :visible_for_levels_editable, :integer, default: 1  # tinyint(4)
    field :url, :string  # varchar(255)
    field :content_info, :string  # varchar(64)
    field :meta_title, :string  # varchar(255)
    field :meta_description, :string  # text
    field :meta_keywords, :string  # text
    field :meta_robots, :string  # varchar(255)
    field :cache_lifetime, :integer, default: 0  # int(11)
    field :cache_editable, :integer, default: 1  # tinyint(4)
    field :inj_head, :string  # text
    field :inj_footer, :string  # text
    field :config_api, :string  # text
    field :deletable, :boolean  # tinyint(1)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_page no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    object: String.t() | nil,
    uri: String.t() | nil,
    title_system: String.t() | nil,
    title: String.t() | nil,
    module: String.t() | nil,
    cover: integer() | nil,
    cover_image: integer() | nil,
    cover_title: String.t() | nil,
    type_id: integer() | nil,
    layout_id: integer() | nil,
    sticky_columns: integer() | nil,
    submenu: String.t() | nil,
    visible_for_levels: integer() | nil,
    visible_for_levels_editable: integer() | nil,
    url: String.t() | nil,
    content_info: String.t() | nil,
    meta_title: String.t() | nil,
    meta_description: String.t() | nil,
    meta_keywords: String.t() | nil,
    meta_robots: String.t() | nil,
    cache_lifetime: integer() | nil,
    cache_editable: integer() | nil,
    inj_head: String.t() | nil,
    inj_footer: String.t() | nil,
    config_api: String.t() | nil,
    deletable: boolean() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_page.

  ## Parâmetros 
    - `sys_objects_page`: Struct do sys_objects_page (pode ser %SysObjectsPage{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_page \ %__MODULE__{}, attrs) do
    sys_objects_page
    |> cast(attrs, [:author, :added, :object, :uri, :title_system, :title, :module, :cover, :cover_image, :cover_title, :type_id, :layout_id, :sticky_columns, :submenu, :visible_for_levels, :visible_for_levels_editable, :url, :content_info, :meta_title, :meta_description, :meta_keywords, :meta_robots, :cache_lifetime, :cache_editable, :inj_head, :inj_footer, :config_api, :deletable, :override_class_name, :override_class_file])
    |> validate_required([:object, :uri, :title_system, :title, :module, :cover_title, :layout_id, :submenu, :url, :content_info, :meta_title, :meta_description, :meta_keywords, :meta_robots, :inj_head, :inj_footer, :config_api, :deletable, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end

  @doc """
  Changeset para atualização de um sys_objects_page existente.

  ## Parâmetros 
    - `sys_objects_page`: Struct do sys_objects_page (%SysObjectsPage{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_page \ %__MODULE__{}, attrs) do
    sys_objects_page
    |> cast(attrs, [:author, :added, :object, :uri, :title_system, :title, :module, :cover, :cover_image, :cover_title, :type_id, :layout_id, :sticky_columns, :submenu, :visible_for_levels, :visible_for_levels_editable, :url, :content_info, :meta_title, :meta_description, :meta_keywords, :meta_robots, :cache_lifetime, :cache_editable, :inj_head, :inj_footer, :config_api, :deletable, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
    |> unique_constraint(:uri)
  end
end
