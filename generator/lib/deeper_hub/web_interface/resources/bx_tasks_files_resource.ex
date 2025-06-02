defmodule DeeperHub.WebInterface.Resources.BxTasksFiles do
  @moduledoc """
  Recurso REST para bx_tasks_files.
  Fornece endpoints para gerenciar bx_tasks_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksFiles,
    resource_name: "bx_tasks_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
