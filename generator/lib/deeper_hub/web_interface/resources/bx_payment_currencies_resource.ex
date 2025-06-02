defmodule DeeperHub.WebInterface.Resources.BxPaymentCurrencies do
  @moduledoc """
  Recurso REST para bx_payment_currencies.
  Fornece endpoints para gerenciar bx_payment_currencies.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentCurrencies,
    resource_name: "bx_payment_currencie"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
