defmodule DeeperHub.WebInterface.Resources.BxGroupsPrices do
  @moduledoc """
  Recurso REST para bx_groups_prices.
  Fornece endpoints para gerenciar bx_groups_prices.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGroupsPrices,
    resource_name: "bx_groups_price"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
