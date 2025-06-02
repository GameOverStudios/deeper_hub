defmodule DeeperHub.WebInterface.Resources.BxAdsCmts do
  @moduledoc """
  Recurso REST para bx_ads_cmts.
  Fornece endpoints para gerenciar bx_ads_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAdsCmts,
    resource_name: "bx_ads_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
