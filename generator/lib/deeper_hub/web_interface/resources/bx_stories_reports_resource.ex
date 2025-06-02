defmodule DeeperHub.WebInterface.Resources.BxStoriesReports do
  @moduledoc """
  Recurso REST para bx_stories_reports.
  Fornece endpoints para gerenciar bx_stories_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxStoriesReports,
    resource_name: "bx_stories_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
