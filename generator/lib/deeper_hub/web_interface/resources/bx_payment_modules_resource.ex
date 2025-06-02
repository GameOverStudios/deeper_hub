defmodule DeeperHub.WebInterface.Resources.BxPaymentModules do
  @moduledoc """
  Recurso REST para bx_payment_modules.
  Fornece endpoints para gerenciar bx_payment_modules.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPaymentModules,
    resource_name: "bx_payment_module"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
