defmodule DeeperHub.WebInterface.Resources.BxTimelineEfFiles do
  @moduledoc """
  Recurso REST para bx_timeline_ef_files.
  Fornece endpoints para gerenciar bx_timeline_ef_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxTimelineEfFiles,
    resource_name: "bx_timeline_ef_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
