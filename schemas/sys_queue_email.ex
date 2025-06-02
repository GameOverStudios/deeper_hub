defmodule DeeperHub.Schema.SysQueueEmail do
  @moduledoc """
  Schema para representação de sys_queue_emails no sistema

  Este schema armazena as informações de um sys_queue_email.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_queue_email" do
    field :email, :string, default: ""  # varchar(64)
    field :subject, :string, default: ""  # varchar(255)
    field :body, :string, default: "''"  # text
    field :params, :string, default: "''"  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_queue_email no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    email: String.t() | nil,
    subject: String.t() | nil,
    body: String.t() | nil,
    params: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_queue_email.

  ## Parâmetros 
    - `sys_queue_email`: Struct do sys_queue_email (pode ser %SysQueueEmail{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_queue_email \ %__MODULE__{}, attrs) do
    sys_queue_email
    |> cast(attrs, [:email, :subject, :body, :params])
    |> validate_required([:email, :subject])
    |> validate_email()
  end

  @doc """
  Changeset para atualização de um sys_queue_email existente.

  ## Parâmetros 
    - `sys_queue_email`: Struct do sys_queue_email (%SysQueueEmail{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_queue_email \ %__MODULE__{}, attrs) do
    sys_queue_email
    |> cast(attrs, [:email, :subject, :body, :params])
    |> validate_email()
  end
end
