defmodule DeeperHub.WebInterface.Resources.BxSpacesAdmins do
  @moduledoc """
  Recurso REST para bx_spaces_admins.
  Fornece endpoints para gerenciar bx_spaces_admins.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxSpacesAdmins,
    resource_name: "bx_spaces_admin"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
