defmodule DeeperHub.WebInterface.Resources.BxReputationEvents do
  @moduledoc """
  Recurso REST para bx_reputation_events.
  Fornece endpoints para gerenciar bx_reputation_events.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReputationEvents,
    resource_name: "bx_reputation_event"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
