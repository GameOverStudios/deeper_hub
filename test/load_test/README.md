# Testes de Carga para WebSockets do DeeperHub

Este diretório contém ferramentas para realizar testes de carga no sistema WebSocket do DeeperHub, permitindo avaliar o desempenho e a escalabilidade da implementação.

## Estrutura

- `websocket_load_test.ex` - Implementação principal do teste de carga
- `client_simulator.ex` - Simulador de cliente WebSocket usando Gun
- `run_load_test.exs` - Script para executar testes com diferentes configurações
- `reports/` - Diretório onde os relatórios de testes são armazenados

## Como Executar

Para executar os testes de carga:

```bash
mix run test/load_test/run_load_test.exs
```

Isso executará uma série de testes com diferentes níveis de carga:

1. **Teste de Baixa Carga** - 100 conexões simultâneas
2. **Teste de Média Carga** - 500 conexões simultâneas
3. **Teste de Alta Carga** - 1000 conexões simultâneas

## Configurações

Você pode modificar as configurações de teste no arquivo `run_load_test.exs`:

- `num_connections` - Número de conexões simultâneas
- `ramp_up_time` - Tempo (em segundos) para estabelecer todas as conexões
- `test_duration` - Duração total do teste (em segundos)
- `message_rate` - Mensagens por segundo por conexão
- `message_size` - Tamanho das mensagens em bytes

## Relatórios

Após a execução, um relatório detalhado é gerado no diretório `reports/` com informações sobre:

- Taxa de sucesso das conexões
- Throughput de mensagens
- Latência (mínima, média, máxima)
- Erros encontrados durante o teste

## Implementação

Os testes utilizam conexões WebSocket reais (não mockadas) para obter métricas precisas:

- `WebSocketLoadTest` - Coordena a execução do teste e coleta estatísticas
- `ClientSimulator` - Implementa clientes WebSocket reais usando a biblioteca Gun

## Métricas Coletadas

- **Conexões** - Taxa de sucesso, falhas, tempo de estabelecimento
- **Mensagens** - Taxa de envio/recebimento, latência, falhas
- **Recursos** - Uso de CPU, memória (quando disponível)
- **Erros** - Tipos e frequência de erros encontrados

## Recomendações

Para obter resultados mais precisos:

1. Execute os testes em um ambiente similar ao de produção
2. Monitore o uso de recursos do servidor durante os testes
3. Aumente gradualmente a carga para identificar limites do sistema
4. Execute testes por períodos mais longos para detectar vazamentos de memória
