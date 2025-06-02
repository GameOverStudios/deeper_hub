defmodule DeeperHub.WebInterface.Resources.BxClassesCmts do
  @moduledoc """
  Recurso REST para bx_classes_cmts.
  Fornece endpoints para gerenciar bx_classes_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxClassesCmts,
    resource_name: "bx_classes_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
