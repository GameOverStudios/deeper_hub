defmodule DeeperHub.WebInterface.Resources.BxForumReports do
  @moduledoc """
  Recurso REST para bx_forum_reports.
  Fornece endpoints para gerenciar bx_forum_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxForumReports,
    resource_name: "bx_forum_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
