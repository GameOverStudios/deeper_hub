defmodule DeeperHub.Core.Data.Schemas.BxFdbQuestions do
  @moduledoc """
  Schema para a tabela bx_fdb_questions.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "bx_fdb_questions",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
