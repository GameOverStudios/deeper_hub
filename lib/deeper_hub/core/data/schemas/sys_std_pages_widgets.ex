defmodule DeeperHub.Core.Data.Schemas.SysStdPagesWidgets do
  @moduledoc """
  Schema para a tabela sys_std_pages_widgets.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "sys_std_pages_widgets",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
