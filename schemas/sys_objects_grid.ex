defmodule DeeperHub.Schema.SysObjectsGrid do
  @moduledoc """
  Schema para representação de sys_objects_grids no sistema

  Este schema armazena as informações de um sys_objects_grid.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_grid" do
    field :object, :string  # varchar(64)
    field :source_type, Ecto.Enum, values: [:Array, :Sql]  # enum('Array','Sql')
    field :source, :string  # text
    field :table, :string  # varchar(255)
    field :field_id, :string  # varchar(255)
    field :field_order, :string  # varchar(255)
    field :field_active, :string  # varchar(255)
    field :order_get_field, :string, default: "order_field"  # varchar(255)
    field :order_get_dir, :string, default: "order_dir"  # varchar(255)
    field :paginate_url, :string  # varchar(255)
    field :paginate_per_page, :integer, default: 10  # int(11)
    field :paginate_simple, :string  # varchar(255)
    field :paginate_get_start, :string  # varchar(255)
    field :paginate_get_per_page, :string  # varchar(255)
    field :filter_fields, :string  # text
    field :filter_fields_translatable, :string  # text
    field :filter_mode, Ecto.Enum, values: [:like, :fulltext, :auto], default: "auto"  # enum('like','fulltext','auto')
    field :filter_get, :string, default: "filter"  # varchar(255)
    field :sorting_fields, :string  # text
    field :sorting_fields_translatable, :string  # text
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :responsive, :integer, default: 1  # tinyint(4)
    field :show_total_count, :integer, default: 0  # tinyint(4)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_grid no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    source_type: :Array | :Sql | nil,
    source: String.t() | nil,
    table: String.t() | nil,
    field_id: String.t() | nil,
    field_order: String.t() | nil,
    field_active: String.t() | nil,
    order_get_field: String.t() | nil,
    order_get_dir: String.t() | nil,
    paginate_url: String.t() | nil,
    paginate_per_page: integer() | nil,
    paginate_simple: String.t() | nil,
    paginate_get_start: String.t() | nil,
    paginate_get_per_page: String.t() | nil,
    filter_fields: String.t() | nil,
    filter_fields_translatable: String.t() | nil,
    filter_mode: :like | :fulltext | :auto | nil,
    filter_get: String.t() | nil,
    sorting_fields: String.t() | nil,
    sorting_fields_translatable: String.t() | nil,
    visible_for_levels: integer() | nil,
    responsive: integer() | nil,
    show_total_count: integer() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_grid.

  ## Parâmetros 
    - `sys_objects_grid`: Struct do sys_objects_grid (pode ser %SysObjectsGrid{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_grid \ %__MODULE__{}, attrs) do
    sys_objects_grid
    |> cast(attrs, [:object, :source_type, :source, :table, :field_id, :field_order, :field_active, :order_get_field, :order_get_dir, :paginate_url, :paginate_per_page, :paginate_simple, :paginate_get_start, :paginate_get_per_page, :filter_fields, :filter_fields_translatable, :filter_mode, :filter_get, :sorting_fields, :sorting_fields_translatable, :visible_for_levels, :responsive, :show_total_count, :override_class_name, :override_class_file])
    |> validate_required([:object, :source_type, :source, :table, :field_id, :field_order, :field_active, :paginate_url, :paginate_get_start, :paginate_get_per_page, :filter_fields, :filter_fields_translatable, :sorting_fields, :sorting_fields_translatable, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_grid existente.

  ## Parâmetros 
    - `sys_objects_grid`: Struct do sys_objects_grid (%SysObjectsGrid{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_grid \ %__MODULE__{}, attrs) do
    sys_objects_grid
    |> cast(attrs, [:object, :source_type, :source, :table, :field_id, :field_order, :field_active, :order_get_field, :order_get_dir, :paginate_url, :paginate_per_page, :paginate_simple, :paginate_get_start, :paginate_get_per_page, :filter_fields, :filter_fields_translatable, :filter_mode, :filter_get, :sorting_fields, :sorting_fields_translatable, :visible_for_levels, :responsive, :show_total_count, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
