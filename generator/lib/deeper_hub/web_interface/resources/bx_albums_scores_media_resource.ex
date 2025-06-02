defmodule DeeperHub.WebInterface.Resources.BxAlbumsScoresMedia do
  @moduledoc """
  Recurso REST para bx_albums_scores_medias.
  Fornece endpoints para gerenciar bx_albums_scores_medias.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAlbumsScoresMedia,
    resource_name: "bx_albums_scores_media"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
