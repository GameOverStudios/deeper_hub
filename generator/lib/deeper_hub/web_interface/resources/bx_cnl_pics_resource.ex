defmodule DeeperHub.WebInterface.Resources.BxCnlPics do
  @moduledoc """
  Recurso REST para bx_cnl_pics.
  Fornece endpoints para gerenciar bx_cnl_pics.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlPics,
    resource_name: "bx_cnl_pic"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
