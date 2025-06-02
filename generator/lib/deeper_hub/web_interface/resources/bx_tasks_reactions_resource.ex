defmodule DeeperHub.WebInterface.Resources.BxTasksReactions do
  @moduledoc """
  Recurso REST para bx_tasks_reactions.
  Fornece endpoints para gerenciar bx_tasks_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksReactions,
    resource_name: "bx_tasks_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
