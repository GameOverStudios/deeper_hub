# Cliente de Terminal Interativo Elixir

Este cliente Python permite conectar-se ao servidor DeeperHub e executar comandos Elixir remotamente através da API REST.

## Requisitos

Antes de usar o cliente, certifique-se de ter as seguintes dependências instaladas:

```bash
pip install requests colorama readline
```

Para Windows, você pode precisar instalar o pacote `pyreadline` em vez de `readline`:

```bash
pip install pyreadline
```

## Como Usar

1. Certifique-se de que o servidor DeeperHub está em execução (por padrão na porta 4000)
2. Execute o cliente:

```bash
python terminal_client.py
```

Ou, se quiser especificar um servidor diferente:

```bash
python terminal_client.py http://servidor-diferente:porta
```

## Comandos Disponíveis

O cliente possui os seguintes comandos especiais:

- `help` - Exibe a ajuda do terminal
- `new` - Cria uma nova sessão de terminal
- `list` - Lista todas as sessões ativas
- `close` - Encerra a sessão atual sem sair do terminal
- `exit` ou `quit` - Sai do terminal (encerra a sessão atual)
- `cls` ou `clear` - Limpa a tela

Qualquer outro comando será enviado para o servidor Elixir como código a ser executado.

## Exemplos de Uso

Para criar uma nova sessão:
```
[Sem Sessão]> new
```

Para executar um comando Elixir:
```
iex (12345678...)> IO.puts("Olá mundo!")
```

Para listar as informações do sistema:
```
iex (12345678...)> :sys.get_status(self())
```

## Solução de Problemas

Se você encontrar problemas de conexão, verifique:

1. Se o servidor DeeperHub está em execução
2. Se as rotas da API REST para o terminal foram configuradas corretamente
3. Se o endereço do servidor está correto (padrão: http://localhost:4000)
