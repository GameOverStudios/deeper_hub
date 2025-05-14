# Script para executar os testes e exibir os resultados

IO.puts("\nExecutando testes do m\u00f3dulo de cache...")
{result, _} = System.cmd("mix", ["test", "test/Deeper_Hub/Core/Data/cache_test.exs"], stderr_to_stdout: true)
IO.puts(result)

IO.puts("\nExecutando testes do m\u00f3dulo de repository...")
{result2, _} = System.cmd("mix", ["test", "test/Deeper_Hub/Core/Data/repository_test.exs"], stderr_to_stdout: true)
IO.puts(result2)

IO.puts("\nTestes conclu\u00eddos.")
