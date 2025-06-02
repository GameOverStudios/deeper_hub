defmodule DeeperHub.Core.Data.Schemas.{{MODULE_NAME}} do
  @moduledoc """
  Schema para a tabela {{TABLE_NAME}}.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "{{TABLE_NAME}}",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
