defmodule DeeperHub.WebInterface.Resources.BxSpacesData do
  @moduledoc """
  Recurso REST para bx_spaces_datas.
  Fornece endpoints para gerenciar bx_spaces_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesData,
    resource_name: "bx_spaces_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
