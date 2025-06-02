defmodule DeeperHub.WebInterface.Resources.BxCreditsOrders do
  @moduledoc """
  Recurso REST para bx_credits_orders.
  Fornece endpoints para gerenciar bx_credits_orders.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCreditsOrders,
    resource_name: "bx_credits_order"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
