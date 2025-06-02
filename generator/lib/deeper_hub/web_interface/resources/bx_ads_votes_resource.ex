defmodule DeeperHub.WebInterface.Resources.BxAdsVotes do
  @moduledoc """
  Recurso REST para bx_ads_votes.
  Fornece endpoints para gerenciar bx_ads_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsVotes,
    resource_name: "bx_ads_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
