defmodule DeeperHub.WebInterface.Resources.BxPostsViewsTrack do
  @moduledoc """
  Recurso REST para bx_posts_views_tracks.
  Fornece endpoints para gerenciar bx_posts_views_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsViewsTrack,
    resource_name: "bx_posts_views_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
