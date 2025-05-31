# Documentação Deeper: Autenticação e Autorização (ACL)

Este documento descreve como a autenticação de usuários e a autorização baseada em Níveis de Controle de Acesso (ACL) serão implementadas na API RESTful \"Deeper\".

## 1. Autenticação

A autenticação é o processo de verificar a identidade de um usuário. Para a API \"Deeper\", usaremos **JSON Web Tokens (JWT)**.

### Fluxo de Autenticação:

1.  **Login Endpoint:**
    *   O cliente envia credenciais (ex: email e senha) para um endpoint específico (ex: `POST /api/v1/auth/login`).
    *   O backend verifica as credenciais consultando a tabela `sys_accounts` (após hashear a senha fornecida e compará-la com `password_hash`).
2.  **Geração do JWT:**
    *   Se as credenciais forem válidas, o backend gera um JWT.
    *   O **payload** do JWT conterá informações essenciais do usuário, como:
        *   `sub` (Subject): ID da conta do usuário (da tabela `sys_accounts`).
        *   `pid` (Profile ID): ID do perfil ativo do usuário (da tabela `sys_profiles`).
        *   `lvl` (Level ID): ID do nível de ACL do usuário (da tabela `sys_acl_levels_members`).
        *   `exp` (Expiration Time): Timestamp de expiração do token.
        *   Outras claims relevantes (ex: `role` da `sys_accounts`).
    *   O token é assinado com uma chave secreta conhecida apenas pelo backend.
3.  **Retorno do Token:**
    *   O backend retorna o JWT para o cliente. O cliente deve armazená-lo de forma segura (ex: localStorage, sessionStorage, ou memória).
4.  **Requisições Autenticadas:**
    *   Para acessar endpoints protegidos, o cliente deve incluir o JWT no cabeçalho `Authorization` de cada requisição, usando o esquema `Bearer`:

        Authorization: Bearer <seu_jwt_aqui>