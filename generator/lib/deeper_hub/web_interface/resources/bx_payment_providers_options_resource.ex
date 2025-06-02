defmodule DeeperHub.WebInterface.Resources.BxPaymentProvidersOptions do
  @moduledoc """
  Recurso REST para bx_payment_providers_options.
  Fornece endpoints para gerenciar bx_payment_providers_options.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentProvidersOptions,
    resource_name: "bx_payment_providers_option"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
