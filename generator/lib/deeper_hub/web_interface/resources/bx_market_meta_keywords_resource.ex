defmodule DeeperHub.WebInterface.Resources.BxMarketMetaKeywords do
  @moduledoc """
  Recurso REST para bx_market_meta_keywords.
  Fornece endpoints para gerenciar bx_market_meta_keywords.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMarketMetaKeywords,
    resource_name: "bx_market_meta_keyword"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
