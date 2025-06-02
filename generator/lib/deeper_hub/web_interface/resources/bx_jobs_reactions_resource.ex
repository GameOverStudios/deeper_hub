defmodule DeeperHub.WebInterface.Resources.BxJobsReactions do
  @moduledoc """
  Recurso REST para bx_jobs_reactions.
  Fornece endpoints para gerenciar bx_jobs_reactions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsReactions,
    resource_name: "bx_jobs_reaction"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
