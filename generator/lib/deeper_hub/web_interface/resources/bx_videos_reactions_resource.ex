defmodule DeeperHub.WebInterface.Resources.BxVideosReactions do
  @moduledoc """
  Recurso REST para bx_videos_reactions.
  Fornece endpoints para gerenciar bx_videos_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosReactions,
    resource_name: "bx_videos_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
