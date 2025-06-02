defmodule DeeperHub.WebInterface.Resources.BxCnlContent do
  @moduledoc """
  Recurso REST para bx_cnl_contents.
  Fornece endpoints para gerenciar bx_cnl_contents.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlContent,
    resource_name: "bx_cnl_content"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
