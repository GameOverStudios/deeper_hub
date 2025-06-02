defmodule DeeperHub.WebInterface.Resources.BxMarketFavoritesTrack do
  @moduledoc """
  Recurso REST para bx_market_favorites_tracks.
  Fornece endpoints para gerenciar bx_market_favorites_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketFavoritesTrack,
    resource_name: "bx_market_favorites_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
