defmodule DeeperHub.WebInterface.Resources.BxPostsCmts do
  @moduledoc """
  Recurso REST para bx_posts_cmts.
  Fornece endpoints para gerenciar bx_posts_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPostsCmts,
    resource_name: "bx_posts_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
