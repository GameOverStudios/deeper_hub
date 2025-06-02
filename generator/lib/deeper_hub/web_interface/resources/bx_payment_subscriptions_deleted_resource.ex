defmodule DeeperHub.WebInterface.Resources.BxPaymentSubscriptionsDeleted do
  @moduledoc """
  Recurso REST para bx_payment_subscriptions_deleteds.
  Fornece endpoints para gerenciar bx_payment_subscriptions_deleteds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentSubscriptionsDeleted,
    resource_name: "bx_payment_subscriptions_deleted"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
