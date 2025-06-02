defmodule DeeperHub.WebInterface.Resources.BxGroupsData do
  @moduledoc """
  Recurso REST para bx_groups_datas.
  Fornece endpoints para gerenciar bx_groups_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGroupsData,
    resource_name: "bx_groups_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
