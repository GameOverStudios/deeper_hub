defmodule DeeperHub.WebInterface.Resources.BxPaymentProviders do
  @moduledoc """
  Recurso REST para bx_payment_providers.
  Fornece endpoints para gerenciar bx_payment_providers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentProviders,
    resource_name: "bx_payment_provider"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
