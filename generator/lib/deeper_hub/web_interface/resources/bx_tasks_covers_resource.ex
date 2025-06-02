defmodule DeeperHub.WebInterface.Resources.BxTasksCovers do
  @moduledoc """
  Recurso REST para bx_tasks_covers.
  Fornece endpoints para gerenciar bx_tasks_covers.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksCovers,
    resource_name: "bx_tasks_cover"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
