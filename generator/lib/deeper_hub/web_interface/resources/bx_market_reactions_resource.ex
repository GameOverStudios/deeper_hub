defmodule DeeperHub.WebInterface.Resources.BxMarketReactions do
  @moduledoc """
  Recurso REST para bx_market_reactions.
  Fornece endpoints para gerenciar bx_market_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketReactions,
    resource_name: "bx_market_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
