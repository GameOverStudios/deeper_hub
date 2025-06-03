defmodule DeeperHub.Core.Data.Schemas.BxNotificationsQueue do
  @moduledoc """
  Schema para a tabela bx_notifications_queue.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "bx_notifications_queue",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
