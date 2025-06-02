defmodule DeeperHub.WebInterface.Resources.BxMapshowAccounts do
  @moduledoc """
  Recurso REST para bx_mapshow_accounts.
  Fornece endpoints para gerenciar bx_mapshow_accounts.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxMapshowAccounts,
    resource_name: "bx_mapshow_account"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
