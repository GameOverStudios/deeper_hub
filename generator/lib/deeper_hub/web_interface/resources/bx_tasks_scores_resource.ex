defmodule DeeperHub.WebInterface.Resources.BxTasksScores do
  @moduledoc """
  Recurso REST para bx_tasks_scores.
  Fornece endpoints para gerenciar bx_tasks_scores.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksScores,
    resource_name: "bx_tasks_score"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
