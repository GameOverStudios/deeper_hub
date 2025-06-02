defmodule DeeperHub.WebInterface.Resources.BxPersonsCmts do
  @moduledoc """
  Recurso REST para bx_persons_cmts.
  Fornece endpoints para gerenciar bx_persons_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsCmts,
    resource_name: "bx_persons_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
