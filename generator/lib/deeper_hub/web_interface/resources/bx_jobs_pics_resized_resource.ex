defmodule DeeperHub.WebInterface.Resources.BxJobsPicsResized do
  @moduledoc """
  Recurso REST para bx_jobs_pics_resizeds.
  Fornece endpoints para gerenciar bx_jobs_pics_resizeds.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsPicsResized,
    resource_name: "bx_jobs_pics_resized"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
