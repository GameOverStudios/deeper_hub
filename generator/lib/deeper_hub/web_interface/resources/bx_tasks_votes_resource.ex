defmodule DeeperHub.WebInterface.Resources.BxTasksVotes do
  @moduledoc """
  Recurso REST para bx_tasks_votes.
  Fornece endpoints para gerenciar bx_tasks_votes.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksVotes,
    resource_name: "bx_tasks_vote"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
