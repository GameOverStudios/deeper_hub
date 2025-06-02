defmodule DeeperHub.WebInterface.Resources.BxPollsMetaMentions do
  @moduledoc """
  Recurso REST para bx_polls_meta_mentions.
  Fornece endpoints para gerenciar bx_polls_meta_mentions.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxPollsMetaMentions,
    resource_name: "bx_polls_meta_mention"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
