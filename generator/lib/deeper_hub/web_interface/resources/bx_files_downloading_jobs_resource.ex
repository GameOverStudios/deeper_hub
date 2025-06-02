defmodule DeeperHub.WebInterface.Resources.BxFilesDownloadingJobs do
  @moduledoc """
  Recurso REST para bx_files_downloading_jobs.
  Fornece endpoints para gerenciar bx_files_downloading_jobs.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxFilesDownloadingJobs,
    resource_name: "bx_files_downloading_job"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
