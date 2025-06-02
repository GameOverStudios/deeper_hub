defmodule DeeperHub.Schema.BxRemindersEntrie do
  @moduledoc """
  Schema para representação de bx_reminders_entries no sistema

  Este schema armazena as informações de um bx_reminders_entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_reminders_entries" do
    field :type_id, :integer, default: 0  # int(11)
    field :rmd_pid, :integer, default: 0  # int(11)
    field :cnt_pid, :integer, default: 0  # int(11)
    field :params, :string, default: "''"  # text
    field :notified, :string, default: "''"  # text
    field :active, :integer, default: 0  # tinyint(4)
    field :visible, :integer, default: 0  # tinyint(4)
    field :added, :integer  # int(11)
    field :expired, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_reminders_entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    type_id: integer() | nil,
    rmd_pid: integer() | nil,
    cnt_pid: integer() | nil,
    params: String.t() | nil,
    notified: String.t() | nil,
    active: integer() | nil,
    visible: integer() | nil,
    added: integer() | nil,
    expired: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_reminders_entrie.

  ## Parâmetros 
    - `bx_reminders_entrie`: Struct do bx_reminders_entrie (pode ser %BxRemindersEntrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_reminders_entrie \ %__MODULE__{}, attrs) do
    bx_reminders_entrie
    |> cast(attrs, [:type_id, :rmd_pid, :cnt_pid, :params, :notified, :active, :visible, :added, :expired])
    |> validate_required([:added, :expired])
  end

  @doc """
  Changeset para atualização de um bx_reminders_entrie existente.

  ## Parâmetros 
    - `bx_reminders_entrie`: Struct do bx_reminders_entrie (%BxRemindersEntrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_reminders_entrie \ %__MODULE__{}, attrs) do
    bx_reminders_entrie
    |> cast(attrs, [:type_id, :rmd_pid, :cnt_pid, :params, :notified, :active, :visible, :added, :expired])
  end
end
