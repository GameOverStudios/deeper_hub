defmodule DeeperHub.WebInterface.Resources.BxTasksReactionsTrack do
  @moduledoc """
  Recurso REST para bx_tasks_reactions_tracks.
  Fornece endpoints para gerenciar bx_tasks_reactions_tracks.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTasksReactionsTrack,
    resource_name: "bx_tasks_reactions_track"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
