defmodule DeeperHub.WebInterface.Resources.BxAclLevelPrices do
  @moduledoc """
  Recurso REST para bx_acl_level_prices.
  Fornece endpoints para gerenciar bx_acl_level_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAclLevelPrices,
    resource_name: "bx_acl_level_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
