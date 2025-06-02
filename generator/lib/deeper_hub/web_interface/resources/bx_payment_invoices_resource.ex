defmodule DeeperHub.WebInterface.Resources.BxPaymentInvoices do
  @moduledoc """
  Recurso REST para bx_payment_invoices.
  Fornece endpoints para gerenciar bx_payment_invoices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentInvoices,
    resource_name: "bx_payment_invoice"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
