defmodule DeeperHub.WebInterface.Resources.BxTasksTasks do
  @moduledoc """
  Recurso REST para bx_tasks_tasks.
  Fornece endpoints para gerenciar bx_tasks_tasks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksTasks,
    resource_name: "bx_tasks_task"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
