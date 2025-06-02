defmodule DeeperHub.WebInterface.Resources.BxEventsPics do
  @moduledoc """
  Recurso REST para bx_events_pics.
  Fornece endpoints para gerenciar bx_events_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsPics,
    resource_name: "bx_events_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
