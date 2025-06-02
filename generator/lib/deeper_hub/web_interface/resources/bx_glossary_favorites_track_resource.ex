defmodule DeeperHub.WebInterface.Resources.BxGlossaryFavoritesTrack do
  @moduledoc """
  Recurso REST para bx_glossary_favorites_tracks.
  Fornece endpoints para gerenciar bx_glossary_favorites_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGlossaryFavoritesTrack,
    resource_name: "bx_glossary_favorites_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
