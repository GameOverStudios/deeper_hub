defmodule DeeperHub.WebInterface.Resources.BxEventsSessions do
  @moduledoc """
  Recurso REST para bx_events_sessions.
  Fornece endpoints para gerenciar bx_events_sessions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsSessions,
    resource_name: "bx_events_session"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
