defmodule DeeperHub.WebInterface.Resources.BxJobsCmts do
  @moduledoc """
  Recurso REST para bx_jobs_cmts.
  Fornece endpoints para gerenciar bx_jobs_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsCmts,
    resource_name: "bx_jobs_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
