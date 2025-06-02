defmodule DeeperHub.WebInterface.Resources.BxTimelineReactions do
  @moduledoc """
  Recurso REST para bx_timeline_reactions.
  Fornece endpoints para gerenciar bx_timeline_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineReactions,
    resource_name: "bx_timeline_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
