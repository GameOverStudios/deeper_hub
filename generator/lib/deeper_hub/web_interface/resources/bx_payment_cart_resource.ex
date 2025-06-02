defmodule DeeperHub.WebInterface.Resources.BxPaymentCart do
  @moduledoc """
  Recurso REST para bx_payment_carts.
  Fornece endpoints para gerenciar bx_payment_carts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentCart,
    resource_name: "bx_payment_cart"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
