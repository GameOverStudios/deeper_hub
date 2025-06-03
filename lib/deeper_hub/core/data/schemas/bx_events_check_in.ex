defmodule DeeperHub.Core.Data.Schemas.BxEventsCheckIn do
  @moduledoc """
  Schema para a tabela bx_events_check_in.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "bx_events_check_in",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
