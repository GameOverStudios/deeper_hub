defmodule DeeperHub.WebInterface.Resources.BxGlossaryFiles do
  @moduledoc """
  Recurso REST para bx_glossary_files.
  Fornece endpoints para gerenciar bx_glossary_files.
  """

  use DeeperHub.WebInterface.ResourceBase,
    schema: DeeperHub.Core.Data.Schemas.BxGlossaryFiles,
    resource_name: "bx_glossary_file"

  # Você pode adicionar endpoints específicos para este recurso aqui
  # Exemplo:
  #
  # get "/custom_endpoint" do
  #   # Lógica personalizada
  #   JsonResponse.send_json(conn, 200, %{message: "Endpoint personalizado"})
  # end
end
