defmodule DeeperHub.WebInterface.Resources.BxTimelinePolls do
  @moduledoc """
  Recurso REST para bx_timeline_polls.
  Fornece endpoints para gerenciar bx_timeline_polls.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelinePolls,
    resource_name: "bx_timeline_poll"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
