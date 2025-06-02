defmodule DeeperHub.WebInterface.Resources.BxCreditsOrdersDeleted do
  @moduledoc """
  Recurso REST para bx_credits_orders_deleteds.
  Fornece endpoints para gerenciar bx_credits_orders_deleteds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCreditsOrdersDeleted,
    resource_name: "bx_credits_orders_deleted"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
