defmodule DeeperHub.WebInterface.Resources.BxEventsCmts do
  @moduledoc """
  Recurso REST para bx_events_cmts.
  Fornece endpoints para gerenciar bx_events_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxEventsCmts,
    resource_name: "bx_events_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
