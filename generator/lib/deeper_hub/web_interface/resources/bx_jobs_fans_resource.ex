defmodule DeeperHub.WebInterface.Resources.BxJobsFans do
  @moduledoc """
  Recurso REST para bx_jobs_fans.
  Fornece endpoints para gerenciar bx_jobs_fans.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsFans,
    resource_name: "bx_jobs_fan"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
