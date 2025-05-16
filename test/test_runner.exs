Logger.info("Iniciando execução dos testes...")

# Garante que a aplicação está iniciada
Application.ensure_all_started(:deeper_hub)

# Executa os testes
try do
  {user_id, user} = DeeperHub.Core.Data.Testes.teste_usuarios()
  Logger.info("Teste de usuários concluído com sucesso! ID: #{user_id}")
  
  DeeperHub.Core.Data.Testes.teste_perfis(user_id)
  Logger.info("Teste de perfis concluído com sucesso!")
  
  DeeperHub.Core.Data.Testes.teste_joins(user_id)
  Logger.info("Teste de joins concluído com sucesso!")
  
  Logger.info("Todos os testes foram executados com sucesso!")
rescue
  e ->
    Logger.error("Erro durante a execução dos testes: #{inspect(e)}")
    Logger.error(Exception.format(:error, e, __STACKTRACE__))
end
