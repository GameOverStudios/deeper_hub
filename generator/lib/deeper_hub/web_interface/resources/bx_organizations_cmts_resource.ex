defmodule DeeperHub.WebInterface.Resources.BxOrganizationsCmts do
  @moduledoc """
  Recurso REST para bx_organizations_cmts.
  Fornece endpoints para gerenciar bx_organizations_cmts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxOrganizationsCmts,
    resource_name: "bx_organizations_cmt"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
