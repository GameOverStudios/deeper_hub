defmodule DeeperHub.WebInterface.Resources.BxPaymentTransactionsPending do
  @moduledoc """
  Recurso REST para bx_payment_transactions_pendings.
  Fornece endpoints para gerenciar bx_payment_transactions_pendings.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentTransactionsPending,
    resource_name: "bx_payment_transactions_pending"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
