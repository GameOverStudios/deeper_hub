project('deeper_client', 'cpp',
  version : '0.1.0',
  default_options : ['warning_level=3', 'cpp_std=c++17']
)

src_files = [
  'src/main.cpp'
]

incdir = include_directories('include')

# Dependências externas
dep_list = []

# Usar subprojetos para as dependências
json_dep = dependency('nlohmann_json', fallback: ['nlohmann_json', 'nlohmann_json_dep'])
websocketpp_dep = dependency('websocketpp', fallback: ['websocketpp', 'websocketpp_dep'], required: false)

# Adicionar dependências à lista
dep_list += json_dep

# Adicionar diretórios de inclusão para as bibliotecas externas
websocketpp_include = include_directories('subprojects/websocketpp-0.8.2')

executable('deeper_client',
  src_files,
  include_directories : incdir,
  dependencies : dep_list
)