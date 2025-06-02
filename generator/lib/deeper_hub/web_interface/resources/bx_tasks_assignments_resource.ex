defmodule DeeperHub.WebInterface.Resources.BxTasksAssignments do
  @moduledoc """
  Recurso REST para bx_tasks_assignments.
  Fornece endpoints para gerenciar bx_tasks_assignments.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksAssignments,
    resource_name: "bx_tasks_assignment"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
