defmodule DeeperHub.WebInterface.Resources.BxOrganizationsData do
  @moduledoc """
  Recurso REST para bx_organizations_datas.
  Fornece endpoints para gerenciar bx_organizations_datas.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsData,
    resource_name: "bx_organizations_data"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
