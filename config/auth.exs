import Config

# Configurações para autenticação JWT
config :joken,
  default_signer: [
    signer_alg: "HS256",
    key_octet: System.get_env("JWT_SECRET_KEY", "deeper_hub_secret_key_for_development_only")
  ]

# Configurações para o TokenBlacklist
config :deeper_hub, Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist,
  cleanup_interval: 60 * 60 * 1000  # 1 hora em milissegundos
