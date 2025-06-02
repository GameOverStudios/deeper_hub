defmodule DeeperHub.Core.Data.Schemas.BxPaymentCurrencies do
  @moduledoc """
  Schema para a tabela bx_payment_currencies.
  Fornece funções para acessar e manipular dados da tabela.
  """

  use DeeperHub.Core.Data.SchemaBase,
    table_name: "bx_payment_currencies",
    primary_key: :id

  # Você pode adicionar funções específicas para esta tabela aqui
  # Exemplo:
  #
  # def find_by_name(name, opts \\ %{}) do
  #   get_by(:name, name, opts)
  # end
end
