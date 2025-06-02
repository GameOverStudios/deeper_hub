defmodule DeeperHub.Schema.SysStdWidget do
  @moduledoc """
  Schema para representação de sys_std_widgets no sistema

  Este schema armazena as informações de um sys_std_widget.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_widgets" do
    field :page_id, :string, default: ""  # varchar(255)
    field :module, :string, default: ""  # varchar(32)
    field :type, :string, default: ""  # varchar(32)
    field :url, :string, default: ""  # varchar(255)
    field :click, :string, default: "''"  # text
    field :icon, :string, default: ""  # varchar(255)
    field :caption, :string, default: ""  # varchar(255)
    field :cnt_notices, :string, default: "''"  # text
    field :cnt_actions, :string, default: "''"  # text
    field :featured, :integer, default: 0  # tinyint(4) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_widget no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    page_id: String.t() | nil,
    module: String.t() | nil,
    type: String.t() | nil,
    url: String.t() | nil,
    click: String.t() | nil,
    icon: String.t() | nil,
    caption: String.t() | nil,
    cnt_notices: String.t() | nil,
    cnt_actions: String.t() | nil,
    featured: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_widget.

  ## Parâmetros 
    - `sys_std_widget`: Struct do sys_std_widget (pode ser %SysStdWidget{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_widget \ %__MODULE__{}, attrs) do
    sys_std_widget
    |> cast(attrs, [:page_id, :module, :type, :url, :click, :icon, :caption, :cnt_notices, :cnt_actions, :featured])
    |> validate_required([:page_id, :module, :type, :url, :icon, :caption])
  end

  @doc """
  Changeset para atualização de um sys_std_widget existente.

  ## Parâmetros 
    - `sys_std_widget`: Struct do sys_std_widget (%SysStdWidget{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_widget \ %__MODULE__{}, attrs) do
    sys_std_widget
    |> cast(attrs, [:page_id, :module, :type, :url, :click, :icon, :caption, :cnt_notices, :cnt_actions, :featured])
  end
end
