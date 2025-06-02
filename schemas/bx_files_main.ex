defmodule DeeperHub.Schema.BxFilesMain do
  @moduledoc """
  Schema para representação de bx_files_mains no sistema

  Este schema armazena as informações de um bx_files_main.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_files_main" do
    field :author, :integer  # int(10) unsigned
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :file_id, :integer  # int(11)
    field :title, :string  # varchar(255)
    field :cat, :integer  # int(11)
    field :desc, :string  # text
    field :data, :string  # text
    field :data_processed, :integer, default: 0  # tinyint(4)
    field :labels, :string  # text
    field :location, :string  # text
    field :views, :integer, default: 0  # int(11)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :rrate, :float, default: 0  # float
    field :rvotes, :integer, default: 0  # int(11)
    field :score, :integer, default: 0  # int(11)
    field :sc_up, :integer, default: 0  # int(11)
    field :sc_down, :integer, default: 0  # int(11)
    field :favorites, :integer, default: 0  # int(11)
    field :comments, :integer, default: 0  # int(11)
    field :reports, :integer, default: 0  # int(11)
    field :featured, :integer, default: 0  # int(11)
    field :cf, :integer, default: 1  # int(11)
    field :allow_view_to, :string, default: "3"  # varchar(16)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')
    field :type, Ecto.Enum, values: [:file, :folder], default: "file"  # enum('file','folder')
    field :parent_folder_id, :integer, default: 0  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_files_main no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    file_id: integer() | nil,
    title: String.t() | nil,
    cat: integer() | nil,
    desc: String.t() | nil,
    data: String.t() | nil,
    data_processed: integer() | nil,
    labels: String.t() | nil,
    location: String.t() | nil,
    views: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    rrate: float() | nil,
    rvotes: integer() | nil,
    score: integer() | nil,
    sc_up: integer() | nil,
    sc_down: integer() | nil,
    favorites: integer() | nil,
    comments: integer() | nil,
    reports: integer() | nil,
    featured: integer() | nil,
    cf: integer() | nil,
    allow_view_to: String.t() | nil,
    status: :active | :hidden | nil,
    status_admin: :active | :hidden | :pending | nil,
    type: :file | :folder | nil,
    parent_folder_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_files_main.

  ## Parâmetros 
    - `bx_files_main`: Struct do bx_files_main (pode ser %BxFilesMain{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_files_main \ %__MODULE__{}, attrs) do
    bx_files_main
    |> cast(attrs, [:author, :added, :changed, :file_id, :title, :cat, :desc, :data, :data_processed, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin, :type, :parent_folder_id])
    |> validate_required([:author, :added, :changed, :file_id, :title, :cat, :desc, :data, :labels, :location])
  end

  @doc """
  Changeset para atualização de um bx_files_main existente.

  ## Parâmetros 
    - `bx_files_main`: Struct do bx_files_main (%BxFilesMain{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_files_main \ %__MODULE__{}, attrs) do
    bx_files_main
    |> cast(attrs, [:author, :added, :changed, :file_id, :title, :cat, :desc, :data, :data_processed, :labels, :location, :views, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :favorites, :comments, :reports, :featured, :cf, :allow_view_to, :status, :status_admin, :type, :parent_folder_id])
  end
end
