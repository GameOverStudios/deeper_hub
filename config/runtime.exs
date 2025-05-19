import Config

# Configurações em tempo de execução para o DeeperHub
# Este arquivo é carregado durante a inicialização da aplicação,
# após a compilação, permitindo configurações dinâmicas baseadas
# no ambiente de execução.

if config_env() == :prod do
  # Configurações específicas para ambiente de produção

  # Configuração do banco de dados
  database_path = 
    System.get_env("DEEPER_HUB_DB_PATH") || 
    raise """
    Variável de ambiente DEEPER_HUB_DB_PATH não definida.
    Para produção, defina o caminho absoluto para o banco de dados SQLite.
    Exemplo: /var/data/deeper_hub_prod.db
    """

  pool_size = 
    System.get_env("DEEPER_HUB_DB_POOL_SIZE") || "20"

  config :deeper_hub, DeeperHub.Core.Data.Repo,
    database: database_path,
    pool_size: String.to_integer(pool_size)

  # Configuração de segurança para autenticação
  guardian_secret = 
    System.get_env("GUARDIAN_SECRET_KEY") || 
    raise """
    Variável de ambiente GUARDIAN_SECRET_KEY não definida.
    Para produção, defina uma chave secreta forte e única.
    Você pode gerar uma chave com: mix phx.gen.secret
    """

  config :deeper_hub, DeeperHub.Accounts.Auth.Guardian,
    secret_key: guardian_secret

  # Configuração de logs
  log_level = 
    (System.get_env("DEEPER_HUB_LOG_LEVEL") || "info")
    |> String.to_atom()

  config :deeper_hub, DeeperHub.Core.Logger,
    level: log_level

  config :logger,
    level: log_level

  # Configuração de rede
  port = String.to_integer(System.get_env("PORT") || "8080")
  
  config :deeper_hub, :network,
    port: port,
    # Limite de conexões WebSocket simultâneas
    max_connections: String.to_integer(System.get_env("MAX_CONNECTIONS") || "10000"),
    # Tamanho máximo de mensagem WebSocket em bytes
    max_frame_size: String.to_integer(System.get_env("MAX_FRAME_SIZE") || "1048576")
end
