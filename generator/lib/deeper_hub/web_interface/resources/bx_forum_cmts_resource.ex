defmodule DeeperHub.WebInterface.Resources.BxForumCmts do
  @moduledoc """
  Recurso REST para bx_forum_cmts.
  Fornece endpoints para gerenciar bx_forum_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumCmts,
    resource_name: "bx_forum_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
