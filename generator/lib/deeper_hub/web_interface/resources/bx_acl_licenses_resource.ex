defmodule DeeperHub.WebInterface.Resources.BxAclLicenses do
  @moduledoc """
  Recurso REST para bx_acl_licenses.
  Fornece endpoints para gerenciar bx_acl_licenses.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAclLicenses,
    resource_name: "bx_acl_license"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
