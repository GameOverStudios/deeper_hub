defmodule DeeperHub.WebInterface.Resources.BxTimelineLinks do
  @moduledoc """
  Recurso REST para bx_timeline_links.
  Fornece endpoints para gerenciar bx_timeline_links.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineLinks,
    resource_name: "bx_timeline_link"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
