defmodule DeeperHub.WebInterface.Resources.BxVideosReactionsTrack do
  @moduledoc """
  Recurso REST para bx_videos_reactions_tracks.
  Fornece endpoints para gerenciar bx_videos_reactions_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxVideosReactionsTrack,
    resource_name: "bx_videos_reactions_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
