defmodule DeeperHub.Schema.SysPagesBlock do
  @moduledoc """
  Schema para representação de sys_pages_blocks no sistema

  Este schema armazena as informações de um sys_pages_block.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_blocks" do
    field :object, :string  # varchar(64)
    field :cell_id, :integer, default: 1  # int(11)
    field :module, :string  # varchar(32)
    field :title_system, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :designbox_id, :integer, default: 11  # int(11)
    field :class, :string, default: ""  # varchar(128)
    field :submenu, :string, default: ""  # varchar(64)
    field :tabs, :integer, default: 0  # tinyint(4)
    field :async, :integer, default: 0  # int(11)
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :hidden_on, :string, default: ""  # varchar(255)
    field :type, Ecto.Enum, values: [:raw, :html, :creative, :bento_grid, :lang, :image, :rss, :menu, :custom, :service, :wiki], default: "raw"  # enum('raw','html','creative','bento_grid','lang','image','rss','menu','custom','service','wiki')
    field :content, :string  # mediumtext
    field :content_empty, :string, default: ""  # varchar(255)
    field :text, :string  # mediumtext
    field :text_updated, :integer  # int(11)
    field :help, :string  # varchar(255)
    field :cache_lifetime, :integer, default: 0  # int(11)
    field :config_api, :string  # text
    field :deletable, :integer, default: 1  # tinyint(4)
    field :copyable, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :active_api, :integer, default: 0  # tinyint(4)
    field :order, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_block no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    cell_id: integer() | nil,
    module: String.t() | nil,
    title_system: String.t() | nil,
    title: String.t() | nil,
    designbox_id: integer() | nil,
    class: String.t() | nil,
    submenu: String.t() | nil,
    tabs: integer() | nil,
    async: integer() | nil,
    visible_for_levels: integer() | nil,
    hidden_on: String.t() | nil,
    type: :raw | :html | :creative | :bento_grid | :lang | :image | :rss | :menu | :custom | :service | :wiki | nil,
    content: String.t() | nil,
    content_empty: String.t() | nil,
    text: String.t() | nil,
    text_updated: integer() | nil,
    help: String.t() | nil,
    cache_lifetime: integer() | nil,
    config_api: String.t() | nil,
    deletable: integer() | nil,
    copyable: integer() | nil,
    active: integer() | nil,
    active_api: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_block.

  ## Parâmetros 
    - `sys_pages_block`: Struct do sys_pages_block (pode ser %SysPagesBlock{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_block \ %__MODULE__{}, attrs) do
    sys_pages_block
    |> cast(attrs, [:object, :cell_id, :module, :title_system, :title, :designbox_id, :class, :submenu, :tabs, :async, :visible_for_levels, :hidden_on, :type, :content, :content_empty, :text, :text_updated, :help, :cache_lifetime, :config_api, :deletable, :copyable, :active, :active_api, :order])
    |> validate_required([:object, :module, :title_system, :title, :class, :submenu, :hidden_on, :content, :content_empty, :text, :text_updated, :help, :config_api, :order])
  end

  @doc """
  Changeset para atualização de um sys_pages_block existente.

  ## Parâmetros 
    - `sys_pages_block`: Struct do sys_pages_block (%SysPagesBlock{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_block \ %__MODULE__{}, attrs) do
    sys_pages_block
    |> cast(attrs, [:object, :cell_id, :module, :title_system, :title, :designbox_id, :class, :submenu, :tabs, :async, :visible_for_levels, :hidden_on, :type, :content, :content_empty, :text, :text_updated, :help, :cache_lifetime, :config_api, :deletable, :copyable, :active, :active_api, :order])
  end
end
