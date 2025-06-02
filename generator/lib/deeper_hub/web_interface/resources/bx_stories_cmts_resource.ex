defmodule DeeperHub.WebInterface.Resources.BxStoriesCmts do
  @moduledoc """
  Recurso REST para bx_stories_cmts.
  Fornece endpoints para gerenciar bx_stories_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesCmts,
    resource_name: "bx_stories_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
