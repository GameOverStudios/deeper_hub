defmodule DeeperHub.WebInterface.Resources.BxAdsReactions do
  @moduledoc """
  Recurso REST para bx_ads_reactions.
  Fornece endpoints para gerenciar bx_ads_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsReactions,
    resource_name: "bx_ads_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
