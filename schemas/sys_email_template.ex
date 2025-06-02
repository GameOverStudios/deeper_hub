defmodule DeeperHub.Schema.SysEmailTemplate do
  @moduledoc """
  Schema para representação de sys_email_templates no sistema

  Este schema armazena as informações de um sys_email_template.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_email_templates" do
    field :ID, :integer  # int(11) unsigned
    field :Module, :string  # varchar(32)
    field :NameSystem, :string  # varchar(255)
    field :Name, :string  # varchar(255)
    field :Subject, :string  # varchar(255)
    field :Body, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_email_template no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Module: String.t() | nil,
    NameSystem: String.t() | nil,
    Name: String.t() | nil,
    Subject: String.t() | nil,
    Body: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_email_template.

  ## Parâmetros 
    - `sys_email_template`: Struct do sys_email_template (pode ser %SysEmailTemplate{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_email_template \ %__MODULE__{}, attrs) do
    sys_email_template
    |> cast(attrs, [:ID, :Module, :NameSystem, :Name, :Subject, :Body])
    |> validate_required([:ID, :Module, :NameSystem, :Name, :Subject, :Body])
  end

  @doc """
  Changeset para atualização de um sys_email_template existente.

  ## Parâmetros 
    - `sys_email_template`: Struct do sys_email_template (%SysEmailTemplate{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_email_template \ %__MODULE__{}, attrs) do
    sys_email_template
    |> cast(attrs, [:ID, :Module, :NameSystem, :Name, :Subject, :Body])
  end
end
