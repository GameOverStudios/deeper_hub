defmodule DeeperHub.WebInterface.Resources.BxPaymentCommissions do
  @moduledoc """
  Recurso REST para bx_payment_commissions.
  Fornece endpoints para gerenciar bx_payment_commissions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentCommissions,
    resource_name: "bx_payment_commission"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
