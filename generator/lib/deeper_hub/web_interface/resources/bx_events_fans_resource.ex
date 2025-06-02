defmodule DeeperHub.WebInterface.Resources.BxEventsFans do
  @moduledoc """
  Recurso REST para bx_events_fans.
  Fornece endpoints para gerenciar bx_events_fans.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsFans,
    resource_name: "bx_events_fan"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
