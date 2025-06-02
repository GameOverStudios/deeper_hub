defmodule DeeperHub.WebInterface.Resources.BxMarketViewsTrack do
  @moduledoc """
  Recurso REST para bx_market_views_tracks.
  Fornece endpoints para gerenciar bx_market_views_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketViewsTrack,
    resource_name: "bx_market_views_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
