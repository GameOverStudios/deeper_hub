defmodule DeeperHub.WebInterface.Resources.BxPaymentStripePaymentsPending do
  @moduledoc """
  Recurso REST para bx_payment_stripe_payments_pendings.
  Fornece endpoints para gerenciar bx_payment_stripe_payments_pendings.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentStripePaymentsPending,
    resource_name: "bx_payment_stripe_payments_pending"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
