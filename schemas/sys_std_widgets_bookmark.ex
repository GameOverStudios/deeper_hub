defmodule DeeperHub.Schema.SysStdWidgetsBookmark do
  @moduledoc """
  Schema para representação de sys_std_widgets_bookmarks no sistema

  Este schema armazena as informações de um sys_std_widgets_bookmark.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_widgets_bookmarks" do
    field :widget_id, :integer, default: 0  # int(11) unsigned
    field :profile_id, :integer, default: 0  # int(11) unsigned
    field :bookmark, :integer, default: 0  # tinyint(4) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_widgets_bookmark no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    widget_id: integer() | nil,
    profile_id: integer() | nil,
    bookmark: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_widgets_bookmark.

  ## Parâmetros 
    - `sys_std_widgets_bookmark`: Struct do sys_std_widgets_bookmark (pode ser %SysStdWidgetsBookmark{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_widgets_bookmark \ %__MODULE__{}, attrs) do
    sys_std_widgets_bookmark
    |> cast(attrs, [:widget_id, :profile_id, :bookmark])
  end

  @doc """
  Changeset para atualização de um sys_std_widgets_bookmark existente.

  ## Parâmetros 
    - `sys_std_widgets_bookmark`: Struct do sys_std_widgets_bookmark (%SysStdWidgetsBookmark{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_widgets_bookmark \ %__MODULE__{}, attrs) do
    sys_std_widgets_bookmark
    |> cast(attrs, [:widget_id, :profile_id, :bookmark])
  end
end
