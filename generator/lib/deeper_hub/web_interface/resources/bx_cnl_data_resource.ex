defmodule DeeperHub.WebInterface.Resources.BxCnlData do
  @moduledoc """
  Recurso REST para bx_cnl_datas.
  Fornece endpoints para gerenciar bx_cnl_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxCnlData,
    resource_name: "bx_cnl_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
