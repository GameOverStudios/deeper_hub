defmodule DeeperHub.WebInterface.Resources.BxMarketVotes do
  @moduledoc """
  Recurso REST para bx_market_votes.
  Fornece endpoints para gerenciar bx_market_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketVotes,
    resource_name: "bx_market_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
