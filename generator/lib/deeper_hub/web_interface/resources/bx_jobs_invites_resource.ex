defmodule DeeperHub.WebInterface.Resources.BxJobsInvites do
  @moduledoc """
  Recurso REST para bx_jobs_invites.
  Fornece endpoints para gerenciar bx_jobs_invites.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsInvites,
    resource_name: "bx_jobs_invite"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
