defmodule DeeperHub.WebInterface.Resources.BxGroupsAdmins do
  @moduledoc """
  Recurso REST para bx_groups_admins.
  Fornece endpoints para gerenciar bx_groups_admins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGroupsAdmins,
    resource_name: "bx_groups_admin"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
