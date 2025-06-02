defmodule DeeperHub.Schema.SysFormFieldsVotesTrack do
  @moduledoc """
  Schema para representação de sys_form_fields_votes_tracks no sistema

  Este schema armazena as informações de um sys_form_fields_votes_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_fields_votes_track" do
    field :object_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :author_nip, :integer, default: 0  # int(11) unsigned
    field :value, :integer, default: 0  # tinyint(4)
    field :date, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_fields_votes_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    author_id: integer() | nil,
    author_nip: integer() | nil,
    value: integer() | nil,
    date: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_fields_votes_track.

  ## Parâmetros 
    - `sys_form_fields_votes_track`: Struct do sys_form_fields_votes_track (pode ser %SysFormFieldsVotesTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_fields_votes_track \ %__MODULE__{}, attrs) do
    sys_form_fields_votes_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :value, :date])
  end

  @doc """
  Changeset para atualização de um sys_form_fields_votes_track existente.

  ## Parâmetros 
    - `sys_form_fields_votes_track`: Struct do sys_form_fields_votes_track (%SysFormFieldsVotesTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_fields_votes_track \ %__MODULE__{}, attrs) do
    sys_form_fields_votes_track
    |> cast(attrs, [:object_id, :author_id, :author_nip, :value, :date])
  end
end
