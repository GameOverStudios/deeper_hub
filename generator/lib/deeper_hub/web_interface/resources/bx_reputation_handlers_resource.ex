defmodule DeeperHub.WebInterface.Resources.BxReputationHandlers do
  @moduledoc """
  Recurso REST para bx_reputation_handlers.
  Fornece endpoints para gerenciar bx_reputation_handlers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReputationHandlers,
    resource_name: "bx_reputation_handler"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
