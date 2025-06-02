defmodule DeeperHub.Schema.BxRemindersType do
  @moduledoc """
  Schema para representação de bx_reminders_types no sistema

  Este schema armazena as informações de um bx_reminders_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reminders_types" do
    field :author, :integer, default: 0  # int(11)
    field :added, :integer  # int(11)
    field :changed, :integer  # int(11)
    field :name, :string  # varchar(128)
    field :title, :string  # varchar(255)
    field :text, :string  # varchar(255)
    field :link, :string  # varchar(255)
    field :when, :string  # varchar(32)
    field :show, :integer, default: 0  # int(11)
    field :notify, :string  # varchar(255)
    field :personal, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 0  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reminders_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author: integer() | nil,
    added: integer() | nil,
    changed: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    link: String.t() | nil,
    when: String.t() | nil,
    show: integer() | nil,
    notify: String.t() | nil,
    personal: integer() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reminders_type.

  ## Parâmetros 
    - `bx_reminders_type`: Struct do bx_reminders_type (pode ser %BxRemindersType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reminders_type \ %__MODULE__{}, attrs) do
    bx_reminders_type
    |> cast(attrs, [:author, :added, :changed, :name, :title, :text, :link, :when, :show, :notify, :personal, :active, :order])
    |> validate_required([:added, :changed, :name, :title, :text, :link, :when, :notify])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_reminders_type existente.

  ## Parâmetros 
    - `bx_reminders_type`: Struct do bx_reminders_type (%BxRemindersType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reminders_type \ %__MODULE__{}, attrs) do
    bx_reminders_type
    |> cast(attrs, [:author, :added, :changed, :name, :title, :text, :link, :when, :show, :notify, :personal, :active, :order])
    |> unique_constraint(:name)
  end
end
