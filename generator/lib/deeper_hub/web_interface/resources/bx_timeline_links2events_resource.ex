defmodule DeeperHub.WebInterface.Resources.BxTimelineLinks2events do
  @moduledoc """
  Recurso REST para bx_timeline_links2events.
  Fornece endpoints para gerenciar bx_timeline_links2events.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineLinks2events,
    resource_name: "bx_timeline_links2event"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
