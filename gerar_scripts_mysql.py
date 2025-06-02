import mysql.connector
import os
from datetime import datetime

# Função para conectar ao MySQL
def conectar_mysql(host='localhost', usuario='root', senha='', banco='una'):
    conexao = mysql.connector.connect(
        host=host,
        user=usuario,
        password=senha,
        database=banco
    )
    return conexao

# Função para obter todas as tabelas, campos e relações
def obter_tabelas_campos(conexao):
    cursor = conexao.cursor()
    tabelas = {}
    relacoes = {}
    
    # Obter todas as tabelas do banco de dados
    cursor.execute("SHOW TABLES")
    lista_tabelas = [tabela[0] for tabela in cursor.fetchall()]
    
    # Para cada tabela, obter seus campos e propriedades
    for tabela in lista_tabelas:
        cursor.execute(f"DESCRIBE {tabela}")
        campos = cursor.fetchall()
        tabelas[tabela] = campos
        
        # Obter informações de chaves estrangeiras
        try:
            cursor.execute(f"""
                SELECT 
                    TABLE_NAME, COLUMN_NAME, 
                    REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME 
                FROM 
                    INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                WHERE 
                    REFERENCED_TABLE_SCHEMA = DATABASE() AND 
                    TABLE_NAME = '{tabela}';
            """)
            fk_info = cursor.fetchall()
            if fk_info:
                if tabela not in relacoes:
                    relacoes[tabela] = []
                for item in fk_info:
                    relacoes[tabela].append({
                        'coluna': item[1],
                        'tabela_ref': item[2],
                        'coluna_ref': item[3]
                    })
        except mysql.connector.Error as err: # Especificar o tipo de erro é uma boa prática
            # Ignorar se não conseguir obter informações de FK, ou logar o erro
            print(f"Aviso: Não foi possível obter FKs para a tabela {tabela}: {err}")
            pass
    
    cursor.close()
    return tabelas, relacoes

# Função para criar arquivos de schema Elixir
def criar_schema(tabela, campos, relacoes=None):
    #print(f"DEBUG: Iniciando criar_schema para tabela {tabela} com {len(campos)} campos")
    # Criar diretório schemas se não existir
    diretorio_schema = "schemas"
    if not os.path.exists(diretorio_schema):
        os.makedirs(diretorio_schema)
    
    # Converter nome da tabela para formato singular
    nome_singular = tabela
    if nome_singular.endswith('s') and not nome_singular.endswith('es') and not nome_singular.endswith('is'): # Evitar remover 's' de 'address' ou 'status' incorretamente.
        nome_singular = nome_singular[:-1]
    elif nome_singular.endswith('ies'):
        nome_singular = nome_singular[:-3] + 'y'
    elif nome_singular.endswith('es'): # Ex: addresses -> address, statuses -> status (pode precisar de mais regras)
        nome_singular = nome_singular[:-2] # Removido `+ 'y'` daqui, pois nem sempre se aplica (ex: 'classes' -> 'class')
                                           # O original tinha `+ 'y'`, mas pode ser um erro. Se 'classes' -> 'classy', está errado.
                                           # Se o original `nome_singular = nome_singular[:-2] + 'y'` for intencional, reverta.
                                           # Mantendo o comportamento do código original do prompt:
    # Revertendo a lógica de singularização para exatamente como no prompt para focar na indentação
    nome_singular = tabela # Reset para garantir que a lógica original do prompt seja usada
    if nome_singular.endswith('s'):
        nome_singular = nome_singular[:-1]
    elif nome_singular.endswith('ies'):
        nome_singular = nome_singular[:-3] + 'y'
    elif nome_singular.endswith('es'):
        nome_singular = nome_singular[:-2] + 'y' # Esta era a linha original do prompt
    
    # Formatar para CamelCase para o nome do módulo
    modulo_nome = ''.join(x.capitalize() for x in nome_singular.split('_'))
    
    # Path do arquivo de schema
    schema_file = os.path.join(diretorio_schema, f"{nome_singular}.ex")
    try:
        print(f"DEBUG: Escrevendo arquivo {schema_file}")
        with open(schema_file, 'w', encoding='utf-8') as arquivo:
            # Cabeçalho do módulo
            arquivo.write(f'defmodule DeeperHub.Schema.{modulo_nome} do\n')
            arquivo.write('  @moduledoc """\n')
            arquivo.write(f'  Schema para representação de {nome_singular}s no sistema\n') # Note: se nome_singular for 'user', aqui será 'users'
            arquivo.write('\n')
            arquivo.write(f'  Este schema armazena as informações de um {nome_singular}.\n')
            arquivo.write('  """\n\n')
            arquivo.write('  use Ecto.Schema\n')
            arquivo.write('  import Ecto.Changeset\n')
            arquivo.write('\n')
        
            # Detectar tipo de chave primária e UUID
            tem_chave_primaria = any(campo[3] == "PRI" for campo in campos)
            tem_uuid = any("uuid" in campo[1].lower() for campo in campos) # Verificar se algum campo tem UUID
            print(f"DEBUG: tem_chave_primaria = {tem_chave_primaria}, tem_uuid = {tem_uuid}")
            
            # Adicionar primary_key e foreign_key_type
            arquivo.write('  @primary_key {:id, :binary_id, autogenerate: true}\n')
            arquivo.write('  @foreign_key_type :binary_id\n')
            
            # Schema
            arquivo.write(f'  schema "{tabela}" do\n')
            
            # Campos
            for campo in campos:
                nome_campo = campo[0]
                tipo_campo = campo[1]
                tipo_elixir = converter_tipo(tipo_campo)
                
                # Pular id se for auto-incremento, será tratado implicitamente pelo @primary_key
                # A menos que seja um campo id que também é UUID (o que é incomum, mas possível)
                if nome_campo == 'id' and not tem_uuid: # Se tem_uuid é true e nome_campo é 'id', ele será escrito.
                    continue
                    
                default = ""
                if campo[4] is not None: # Verificar se o default existe
                    # Tratar valores padrão comuns
                    if tipo_elixir == "boolean": # tinyint(1)
                        default = f", default: {str(campo[4] == '1' or str(campo[4]).lower() == 'true').lower()}"
                    elif tipo_elixir == "integer" or tipo_elixir == "float":
                        try:
                            # Tentar converter para número para remover aspas se for numérico
                            num_val = float(campo[4])
                            if num_val.is_integer():
                                default = f", default: {int(num_val)}"
                            else:
                                default = f", default: {num_val}"
                        except ValueError:
                             # Se não for um número simples, manter como string (pode ser uma função ou expressão)
                            default = f", default: \"{campo[4]}\"" if tipo_elixir == "string" else f", default: {campo[4]}"
                    elif tipo_elixir == "string":
                        default = f", default: \"{campo[4]}\""
                    # Para outros tipos, pode ser necessário tratamento específico.
                    # Por ora, uma abordagem genérica se não coberto acima:
                    elif campo[4]: # Se ainda há um valor padrão não coberto
                         default = f", default: \"{campo[4]}\"" # Assume string se não for numérico/booleano


                # Verificar se campo pode ser nulo
                nullable = ""
                # if campo[2] == "YES":  # Campo permite NULL
                #     # Ecto campos são nuláveis por padrão, exceto se validados como obrigatórios.
                #     # A opção `null: true` é mais para clareza ou se o DB impõe NOT NULL por padrão.
                #     # Para booleanos, :boolean já é `false` por padrão se não nulo, Ecto pode inferir.
                #     pass # Não adicionar `null: true` explicitamente, deixar Ecto/DB decidirem ou validar no changeset.
                
                # Verificar se é enum
                if tipo_campo.lower().startswith('enum'):
                    valores_enum = tipo_campo[5:-1].split(',')
                    valores_enum = [v.strip('\'"') for v in valores_enum]
                    valores_atom = [f":{v}" for v in valores_enum]
                    arquivo.write(f'    field :{nome_campo}, Ecto.Enum, values: [{", ".join(valores_atom)}]{default}{nullable}  # {tipo_campo}\n')
                else:
                    arquivo.write(f'    field :{nome_campo}, :{tipo_elixir}{default}{nullable}  # {tipo_campo}\n')
            
            # Timestamps
            arquivo.write('\n    timestamps()\n')
            arquivo.write('  end\n\n')
            
            # Definição de tipo
            arquivo.write('  @typedoc """\n')
            arquivo.write(f'  Tipo que representa um {nome_singular} no sistema\n')
            arquivo.write('  """\n')
            arquivo.write('  @type t :: %__MODULE__{\n')
            
            campos_normais = [c for c in campos if c[0] not in ['inserted_at', 'updated_at']]
            # `has_timestamps` é sempre True no original, o que significa que a vírgula para o último campo normal
            # e a adição de inserted_at/updated_at no @type t sempre ocorrerá.
            # Se timestamps() é chamado, esses campos existirão.
            
            campos_para_type_spec = []
            # Adicionar 'id' ao type spec se estiver usando :binary_id
            campos_para_type_spec.append(('id', 'binary_id', 'NO', 'PRI', None)) # Adiciona o ID binário

            for campo in campos_normais:
                # Não adicionar 'id' novamente se já foi processado ou se for o ID padrão não UUID
                if campo[0] == 'id' and not tem_uuid:
                    continue
                campos_para_type_spec.append(campo)

            for i, campo_info in enumerate(campos_para_type_spec):
                nome_campo = campo_info[0]
                tipo_campo_mysql = campo_info[1]
                tipo_elixir = converter_tipo(tipo_campo_mysql)
                if nome_campo == 'id' and tipo_elixir != 'binary_id': # Caso especial para o ID :binary_id
                    tipo_elixir = 'binary_id'


                # Vírgula para todos exceto o último, OU se timestamps forem adicionados depois
                precisa_virgula = (i < len(campos_para_type_spec) - 1) or True # True porque timestamps() sempre são adicionados
                virgula = ',' if precisa_virgula else ''
                
                tipo_elixir_spec_map = {
                    'integer': 'integer()',
                    'string': 'String.t()',
                    'float': 'float()',
                    'boolean': 'boolean()',
                    'date': 'Date.t()',
                    'naive_datetime': 'NaiveDateTime.t()',
                    'binary_id': 'Ecto.UUID.t()', # Para :binary_id
                    'map': 'map()'
                }
                tipo_elixir_spec = tipo_elixir_spec_map.get(tipo_elixir, 'term()')
                
                # Se campo pode ser nulo (originalmente verificado `campo[2] == "YES"`)
                # ou se for um campo que não é explicitamente NOT NULL (coluna 2 do DESCRIBE)
                # e não for o ID primário (que geralmente não é nil)
                can_be_nil = campo_info[2] == "YES" or nome_campo not in ('id', 'inserted_at', 'updated_at')

                if can_be_nil:
                    tipo_elixir_spec += ' | nil'

                if tipo_campo_mysql.lower().startswith('enum'):
                    valores_enum = tipo_campo_mysql[5:-1].split(',')
                    valores_enum = [v.strip('\'"') for v in valores_enum]
                    valores_atom = [f':{v}' for v in valores_enum]
                    tipo_elixir_spec = ' | '.join(valores_atom)
                    if can_be_nil:
                         tipo_elixir_spec += ' | nil'
                    
                arquivo.write(f'    {nome_campo}: {tipo_elixir_spec}{virgula}\n')
            
            # Adicionar tipos para timestamps (inserted_at, updated_at) se não foram listados
            # Se `timestamps()` é usado, eles são `NaiveDateTime.t() | nil` (nil antes do insert)
            # O último campo não deve ter vírgula
            arquivo.write('    inserted_at: NaiveDateTime.t() | nil,\n')
            arquivo.write('    updated_at: NaiveDateTime.t() | nil\n')
            
            arquivo.write('  }\n\n')
            
            # Changeset de criação
            arquivo.write('  @doc """\n')
            arquivo.write(f'  Changeset para criação de um novo {nome_singular}.\n\n')
            arquivo.write('  ## Parâmetros \n')
            arquivo.write(f'    - `{nome_singular}`: Struct do {nome_singular} (pode ser %{modulo_nome}{{}} ou %{{}})\n')
            arquivo.write('    - `attrs`: Mapa com os atributos para criação\n\n')
            arquivo.write('  ## Retorno \n')
            arquivo.write('    - Changeset válido ou inválido\n')
            arquivo.write('  """\n')
            arquivo.write(f'  def create_changeset({nome_singular} \\ %__MODULE__{{}}, attrs) do\n') # Tipagem do primeiro param
            arquivo.write(f'    {nome_singular}\n')
            
            campos_cast = [f":{campo[0]}" for campo in campos if campo[0] not in ['id', 'inserted_at', 'updated_at']]
            if campos_cast: # Só chamar cast se houver campos
                 arquivo.write(f'    |> cast(attrs, [{", ".join(campos_cast)}])\n')
            
            campos_required = [f":{campo[0]}" for campo in campos if campo[2] == "NO" and not campo[4] and campo[0] not in ['id', 'inserted_at', 'updated_at']]
            if campos_required:
                arquivo.write(f'    |> validate_required([{(", ").join(campos_required)}])\n')
            
            if any(campo[0] == 'email' for campo in campos):
                # Assumindo que validate_email/password e put_password_hash são funções auxiliares definidas em outro lugar
                arquivo.write('    |> validate_email()\n') 
            
            if any(campo[0] == 'password' for campo in campos):
                arquivo.write('    |> validate_password()\n')
                arquivo.write('    |> put_password_hash()\n')
            
            # Adicionar unique_constraint para campos UNI (exceto id)
            for campo_info in campos:
                if campo_info[3] == "UNI" and campo_info[0] != 'id':
                    arquivo.write(f'    |> unique_constraint(:{campo_info[0]})\n')

            # A chamada `timestamps()` no schema já cuida disso. Não é necessário no changeset create,
            # a menos que para sobrescrever o comportamento padrão (o que não parece ser o caso aqui).
            # if not any(campo[0] == 'inserted_at' for campo in campos):
            #     arquivo.write('    # Adiciona campos inserted_at e updated_at automaticamente\n')
            #     arquivo.write('    timestamps()\n')
            
            # Finaliza a pipe do changeset se não houver mais nada a adicionar
            # Se a última linha foi um `|> func()`, não precisa de nada. Se foi `if` e não entrou, precisa do nome do schema.
            # O código gerado assume que sempre haverá pelo menos um `cast` ou `validate_required`.
            # Para ser seguro, podemos remover a última pipe se for o caso ou garantir que sempre haja algo.
            # Como o código está, a última linha de `create_changeset` é `|> unique_constraint` ou `|> put_password_hash` etc.
            # Se não houver nenhuma dessas, a última linha seria `|> validate_required` ou `|> cast`.
            # Se `campos_cast` e `campos_required` forem vazios e não houver email/password/unique,
            # o changeset seria apenas `{nome_singular}` o que é inválido.
            # Adicionando um `|> IO.inspect(label: "Changeset final create") # Para debug` ou similar, ou nada se for a última pipe.
            # Como o prompt não define o que fazer se não houver pipes, deixamos como está.
            # A última linha real da função é o `end`.
            arquivo.write('  end\n\n')
            
            # Changeset para update
            arquivo.write(f'  @doc """\n')
            arquivo.write(f'  Changeset para atualização de um {nome_singular} existente.\n\n')
            arquivo.write(f'  ## Parâmetros \n')
            arquivo.write(f'    - `{nome_singular}`: Struct do {nome_singular} (%{modulo_nome}{{}})\n')
            arquivo.write(f'    - `attrs`: Mapa com os atributos para atualização\n\n')
            arquivo.write(f'  ## Retorno \n')
            arquivo.write(f'    - Changeset válido ou inválido\n')
            arquivo.write(f'  """\n')
            arquivo.write(f'  def update_changeset({nome_singular} \\ %__MODULE__{{}}, attrs) do\n')
            arquivo.write(f'    {nome_singular}\n')
            
            campos_update = [f":{campo[0]}" for campo in campos if campo[0] not in ['id', 'password', 'password_hash', 'inserted_at', 'updated_at']]
            if campos_update:
                arquivo.write(f'    |> cast(attrs, [{(", ").join(campos_update)}])\n')
            # Não costuma ter validate_required no update, pois os campos já existem.
            # A menos que se queira impedir que se tornem nulos.
            
            if any(campo[0] == 'email' for campo in campos):
                arquivo.write('    |> validate_email()\n') # Supondo que só valida se 'email' estiver nos attrs
            
            # Unique constraints também são importantes no update
            for campo_info in campos:
                if campo_info[3] == "UNI" and campo_info[0] != 'id':
                    arquivo.write(f'    |> unique_constraint(:{campo_info[0]})\n')
            
            arquivo.write('  end\n')
            arquivo.write('end\n')
        
        # Se chegou aqui, o arquivo foi escrito e fechado.
        print(f"Schema {schema_file} criado com sucesso!")

    except IOError as e: # Erro de escrita/leitura
        print(f"Erro de I/O ao criar o schema {schema_file}: {e}")
    except Exception as e: # Outros erros
        print(f"Erro inesperado ao criar o schema {schema_file}: {e}")
        # raise # Descomente para propagar a exceção se necessário


# Função para criar os arquivos de migration
def criar_migrations(tabelas, relacoes=None):
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    
    diretorio = "migrations"
    if not os.path.exists(diretorio):
        os.makedirs(diretorio)
    
    idx_migration = 0 # Para gerar timestamps únicos se várias tabelas são processadas no mesmo segundo
    for tabela, campos in tabelas.items():
        current_timestamp = f"{timestamp}{idx_migration:02d}" # Adiciona um sufixo para unicidade
        idx_migration +=1
        nome_arquivo = os.path.join(diretorio, f"create_{tabela}_table.exs") # .exs para scripts de migração
        
        tabela_formatada = ''.join(x.capitalize() for x in tabela.split('_'))
        
        with open(nome_arquivo, 'w', encoding='utf-8') as arquivo:
            arquivo.write(f'defmodule Repo.Migrations.Create{tabela_formatada} do\n') # Módulo Repo.Migrations...
            arquivo.write('  use Ecto.Migration\n\n')
            
            arquivo.write('  def change do\n') # Usar change() para migrations reversíveis simples
            arquivo.write(f'    create table(:{tabela}, primary_key: false) do\n') # primary_key: false para definir manualmente
            
            # Adicionar id binário como chave primária por padrão para novos schemas
            arquivo.write(f'      add :id, :binary_id, primary_key: true\n')

            for campo in campos:
                nome_campo = campo[0]
                tipo_campo_mysql = campo[1]
                nulo_mysql = campo[2]
                chave_mysql = campo[3]
                default_mysql = campo[4]

                # Ignorar campo 'id' se ele for PK, já foi tratado pelo :binary_id acima
                if nome_campo == 'id' and chave_mysql == "PRI":
                    continue

                tipo_elixir = converter_tipo(tipo_campo_mysql)
                
                opcoes = []
                if nulo_mysql == "NO":
                    opcoes.append("null: false")
                
                if default_mysql is not None:
                    # Tratamento de default similar ao do schema
                    if tipo_elixir == "boolean":
                         opcoes.append(f"default: {str(default_mysql == '1' or str(default_mysql).lower() == 'true').lower()}")
                    elif tipo_elixir == "integer" or tipo_elixir == "float":
                        try:
                            num_val = float(default_mysql)
                            if num_val.is_integer():
                                opcoes.append(f"default: {int(num_val)}")
                            else:
                                opcoes.append(f"default: {num_val}")
                        except ValueError:
                            opcoes.append(f"default: \"{default_mysql}\"")
                    elif tipo_elixir == "string":
                        opcoes.append(f"default: \"{default_mysql}\"")
                    elif default_mysql: # genérico
                        opcoes.append(f"default: \"{default_mysql}\"")


                opcoes_str = (", " + ", ".join(opcoes)) if opcoes else ""
                
                if tipo_campo_mysql.lower().startswith('enum'):
                    # Ecto não tem suporte direto a ENUM do DB em migrations.
                    # Geralmente se usa `check_constraint` ou um tipo customizado, ou apenas string.
                    # Aqui, vamos usar string e assumir que `Ecto.Enum` no schema cuida da validação.
                    arquivo.write(f'      add :{nome_campo}, :string{opcoes_str}\n')
                else:
                    arquivo.write(f'      add :{nome_campo}, :{tipo_elixir}{opcoes_str}\n')
            
            if not any(c[0] == 'inserted_at' for c in campos) and not any(c[0] == 'updated_at' for c in campos):
                arquivo.write('      timestamps()\n')
            
            arquivo.write('    end\n')
            
            # Índices para chaves estrangeiras ou campos marcados como MUL (índice não único)
            # Ou para campos com unique constraint
            for campo in campos:
                nome_campo = campo[0]
                # Adicionar índice para chaves estrangeiras (MUL) ou campos únicos (UNI) que não são PK
                if (campo[3] == "MUL" or campo[3] == "UNI") and nome_campo != 'id':
                    unique_opt = ", unique: true" if campo[3] == "UNI" else ""
                    arquivo.write(f'    create index(:{tabela}, [:{nome_campo}]{unique_opt})\n') 
            
            # Relações (chaves estrangeiras) - se `relacoes` for fornecido e usado
            if relacoes and tabela in relacoes:
                for rel in relacoes[tabela]:
                    arquivo.write(f'    alter table(:{tabela}) do\n')
                    arquivo.write(f'      add :"{rel["coluna"]}", references(:{rel["tabela_ref"]}, column: :"{rel["coluna_ref"]}", type: :binary_id)\n')
                    arquivo.write(f'    end\n')


            arquivo.write('  end\n') # Fim do def change
            # `up` e `down` não são mais necessários se `change` for usado corretamente.
            # Se precisar de lógica mais complexa que `change` não suporta, volte para `up/down`.
            arquivo.write('end\n')
        
        print(f"Arquivo de migration {nome_arquivo} criado com sucesso!")

# Função para converter tipo MySQL para tipo Elixir
def converter_tipo(tipo_mysql):
    tipo_lower = tipo_mysql.lower()
    
    if 'tinyint(1)' in tipo_lower: return "boolean"
    if 'int' in tipo_lower: return "integer" # Covers tinyint, smallint, mediumint, int, bigint
    
    if 'float' in tipo_lower: return "float"
    if 'double' in tipo_lower: return "float"
    if 'decimal' in tipo_lower: return "decimal"
    
    if 'char' in tipo_lower: return "string"
    if 'varchar' in tipo_lower: return "string"
    if 'text' in tipo_lower: return "string" # Covers tinytext, text, mediumtext, longtext
    
    if 'binary' in tipo_lower and 'varbinary' not in tipo_lower : return "binary" # fixed length binary
    if 'varbinary' in tipo_lower : return "binary" # variable length binary
    if 'blob' in tipo_lower: return "binary" # Covers tinyblob, blob, mediumblob, longblob
    
    if tipo_lower.startswith('date') and 'datetime' not in tipo_lower: return "date"
    if 'datetime' in tipo_lower: return "naive_datetime"
    if 'timestamp' in tipo_lower: return "naive_datetime"
    if 'time' in tipo_lower and 'timestamp' not in tipo_lower: return "time"
    if 'year' in tipo_lower: return "integer"
    
    if 'enum' in tipo_lower: return "string" # Ecto.Enum usa string ou integer no DB, mas valida no schema
    if 'json' in tipo_lower: return "map" # Ecto usa :map para JSON
    if 'bool' in tipo_lower: return "boolean"
    if 'binary_id' in tipo_lower: return "binary_id" # Tipo especial para Ecto UUIDs

    print(f"Aviso: Tipo MySQL não mapeado '{tipo_mysql}', usando 'string' como padrão.")
    return "string"

# Função para limpar diretórios
def limpar_diretorios():
    import shutil
    if os.path.exists("migrations"):
        shutil.rmtree("migrations")
        print("Diretório migrations apagado!")
    
    if os.path.exists("schemas"):
        shutil.rmtree("schemas")
        print("Diretório schemas apagado!")

# Função principal
def main():
    try:
        limpar_diretorios()
        
        host = input("Host do MySQL (deixe em branco para 'localhost'): ") or "localhost"
        usuario = input("Usuário do MySQL (deixe em branco para 'root'): ") or "root"
        senha = input("Senha do MySQL: ")
        banco = input("Nome do banco de dados: ") or "una"
        
        if not banco:
            print("Nome do banco de dados é obrigatório.")
            return

        conexao = conectar_mysql(host, usuario, senha, banco)
        
        tabelas, relacoes = obter_tabelas_campos(conexao)
        
        if not tabelas:
            print(f"Nenhuma tabela encontrada no banco '{banco}'.")
            conexao.close()
            return

        print("\nGerando arquivos de migration...")
        criar_migrations(tabelas, relacoes) # Passar relacoes para criar_migrations
        
        print("\nGerando arquivos de schema...")
        for tabela, campos in tabelas.items():
            relacoes_tabela = relacoes.get(tabela, [])
            criar_schema(tabela, campos, relacoes_tabela) # Passar relacoes_tabela para criar_schema
        
        conexao.close()
        print("\nProcesso concluído com sucesso!")
        
    except mysql.connector.Error as err:
        print(f"Erro de MySQL: {err}")
    except Exception as e:
        print(f"Erro geral no script: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()