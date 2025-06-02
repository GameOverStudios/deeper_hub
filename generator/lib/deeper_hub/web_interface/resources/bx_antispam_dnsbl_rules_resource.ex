defmodule DeeperHub.WebInterface.Resources.BxAntispamDnsblRules do
  @moduledoc """
  Recurso REST para bx_antispam_dnsbl_rules.
  Fornece endpoints para gerenciar bx_antispam_dnsbl_rules.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAntispamDnsblRules,
    resource_name: "bx_antispam_dnsbl_rule"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
