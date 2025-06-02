defmodule DeeperHub.WebInterface.Resources.BxJobsPics do
  @moduledoc """
  Recurso REST para bx_jobs_pics.
  Fornece endpoints para gerenciar bx_jobs_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsPics,
    resource_name: "bx_jobs_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
