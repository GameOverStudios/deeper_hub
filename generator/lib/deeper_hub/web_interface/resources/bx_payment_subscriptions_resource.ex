defmodule DeeperHub.WebInterface.Resources.BxPaymentSubscriptions do
  @moduledoc """
  Recurso REST para bx_payment_subscriptions.
  Fornece endpoints para gerenciar bx_payment_subscriptions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentSubscriptions,
    resource_name: "bx_payment_subscription"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
