defmodule DeeperHub.WebInterface.Resources.BxTasksCmts do
  @moduledoc """
  Recurso REST para bx_tasks_cmts.
  Fornece endpoints para gerenciar bx_tasks_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksCmts,
    resource_name: "bx_tasks_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
