defmodule DeeperHub.WebInterface.Resources.BxJobsData do
  @moduledoc """
  Recurso REST para bx_jobs_datas.
  Fornece endpoints para gerenciar bx_jobs_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxJobsData,
    resource_name: "bx_jobs_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
