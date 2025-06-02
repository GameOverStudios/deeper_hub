defmodule DeeperHub.WebInterface.Resources.BxAntispamIpTable do
  @moduledoc """
  Recurso REST para bx_antispam_ip_tables.
  Fornece endpoints para gerenciar bx_antispam_ip_tables.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAntispamIpTable,
    resource_name: "bx_antispam_ip_table"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
