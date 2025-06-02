defmodule DeeperHub.WebInterface.Resources.BxPersonsData do
  @moduledoc """
  Recurso REST para bx_persons_datas.
  Fornece endpoints para gerenciar bx_persons_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPersonsData,
    resource_name: "bx_persons_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
