defmodule DeeperHub.WebInterface.Resources.BxReviewsReports do
  @moduledoc """
  Recurso REST para bx_reviews_reports.
  Fornece endpoints para gerenciar bx_reviews_reports.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxReviewsReports,
    resource_name: "bx_reviews_report"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
