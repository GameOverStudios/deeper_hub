defmodule DeeperHub.Core.Data.Schemas.BxTimelineEfFiles do
  @moduledoc """
  Schema para a tabela bx_timeline_ef_files.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "bx_timeline_ef_files",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
