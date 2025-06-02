defmodule DeeperHub.WebInterface.Resources.BxAntispamDisposableEmailDomains do
  @moduledoc """
  Recurso REST para bx_antispam_disposable_email_domains.
  Fornece endpoints para gerenciar bx_antispam_disposable_email_domains.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxAntispamDisposableEmailDomains,
    resource_name: "bx_antispam_disposable_email_domain"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
