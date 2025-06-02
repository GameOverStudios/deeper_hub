defmodule DeeperHub.WebInterface.Resources.BxInvRequests do
  @moduledoc """
  Recurso REST para bx_inv_requests.
  Fornece endpoints para gerenciar bx_inv_requests.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxInvRequests,
    resource_name: "bx_inv_request"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
