defmodule DeeperHub.WebInterface.Resources.BxPaymentTransactions do
  @moduledoc """
  Recurso REST para bx_payment_transactions.
  Fornece endpoints para gerenciar bx_payment_transactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentTransactions,
    resource_name: "bx_payment_transaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
