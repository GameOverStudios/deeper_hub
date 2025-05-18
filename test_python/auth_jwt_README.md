# Autenticação JWT no Cliente Python para DeeperHub

Este documento descreve as funcionalidades de autenticação JWT implementadas no cliente Python para testes do DeeperHub.

## Funcionalidades de Autenticação

O cliente Python implementa as seguintes operações de autenticação:

### 1. Login

Realiza a autenticação do usuário no sistema e obtém tokens JWT.

```python
await client.login(username, password)
```

**Parâmetros:**
- `username`: Nome de usuário
- `password`: Senha do usuário

**Retorno:**
- Em caso de sucesso, armazena os tokens JWT (access_token e refresh_token) e retorna `True`
- Em caso de falha, retorna `False`

### 2. Logout

Encerra a sessão do usuário e invalida os tokens.

```python
await client.logout()
```

**Retorno:**
- `True` se o logout foi bem-sucedido
- `False` em caso de falha

### 3. Refresh de Tokens

Atualiza os tokens de acesso usando o refresh token.

```python
await client.refresh_tokens()
```

**Retorno:**
- `True` se os tokens foram atualizados com sucesso
- `False` em caso de falha

### 4. Solicitação de Recuperação de Senha

Solicita um token para recuperação de senha.

```python
success, token = await client.request_password_reset(email)
```

**Parâmetros:**
- `email`: Email do usuário que deseja recuperar a senha

**Retorno:**
- Uma tupla contendo:
  - `success`: Boolean indicando se a solicitação foi bem-sucedida
  - `token`: O token de recuperação (apenas em ambiente de desenvolvimento)

### 5. Redefinição de Senha

Redefine a senha do usuário usando um token de recuperação.

```python
await client.reset_password(token, new_password)
```

**Parâmetros:**
- `token`: Token de recuperação obtido anteriormente
- `new_password`: Nova senha desejada

**Retorno:**
- `True` se a senha foi redefinida com sucesso
- `False` em caso de falha

## Formato das Mensagens

As mensagens de autenticação seguem o formato:

```json
{
  "type": "auth",
  "payload": {
    "action": "login|logout|refresh|request_password_reset|reset_password",
    // Outros campos específicos da ação
  }
}
```

## Fluxo de Recuperação de Senha

1. O usuário solicita a recuperação de senha fornecendo seu email
2. O servidor gera um token de recuperação e o retorna (em ambiente de produção seria enviado por email)
3. O usuário usa o token para redefinir sua senha
4. O usuário pode fazer login com a nova senha

## Exemplo de Uso

```python
# Solicitar recuperação de senha
success, token = await client.request_password_reset("usuario@email.com")
if success and token:
    # Redefinir senha com o token recebido
    await client.reset_password(token, "nova_senha123")
    
    # Fazer login com a nova senha
    await client.login("nome_usuario", "nova_senha123")
```

## Segurança

- Os tokens JWT têm tempo de expiração configurável
- O refresh token permite renovar a sessão sem precisar fornecer credenciais novamente
- Tokens de recuperação de senha têm validade limitada
- Senhas são armazenadas com hash seguro no servidor
