defmodule DeeperHub.WebInterface.Resources.BxEventsPicsResized do
  @moduledoc """
  Recurso REST para bx_events_pics_resizeds.
  Fornece endpoints para gerenciar bx_events_pics_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsPicsResized,
    resource_name: "bx_events_pics_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
