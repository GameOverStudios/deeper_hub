# Inicia o ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)

# Configura o ambiente de teste
ExUnit.configure(formatters: [ExUnit.CLIFormatter])
ExUnit.start()

# Garante que o diretório test/support seja compilado
Code.require_file("support/factory.ex", __DIR__)
