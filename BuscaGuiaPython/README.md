README.md

# Projeto para Busca nos Guias de Matrícula (Versão Python 1.0)

Este projeto contém funções em R para baixar e buscar informações presentes nos Guias de matrícula (Se houve oferta, dia, horário, vagas etc.), através do código da disciplina, do nome da matéria ou do nome do Docente.

## Requisitos

Certifique-se de ter o **R** instalado no seu sistema para rodar o código. Não é necessário a instalação de nenhum pacote. A versão do R utilizada para desenvolvimento e testes do Projeto foi a 4.4.1

## Estrutura do Projeto

- `formatar`: Formata texto para exibir com cores e estilos no terminal, útil para quando houver o interesse testar a formatação do texto antes de rodar a função `pesquisa`.
- `adicionar`: Atualiza o número (adicionando 1) do último guia de matrícula de cada Unidade Universitária presente no arquivo `../ultimo.properties`.
- `baixar_guia`: Carrega os guias de matrícula em HTML, transforma em dataframes e baixa como .CSV, útil para quando houver o interesse em baixar um guia de matrícula específico.
- `baixar`: Com base no arquivo `../ultimo.properties`, baixa o último guia de matrícula de cada Unidade Universitária.
- `pesquisa`: Utilizando como critério o código da disciplina, o nome da matéria ou o nome do docente, realiza a busca nos guias de matrículas previamente baixados e retornando as informações presente nele, se houve oferta no semestre, código da disciplina, o nome da matéria, número de vagas para cada curso em cada turma, dia(s) e horário(s) de cada turma, docente(s) responsável(is) por ministrar cada turma.

## Arquivos Necessários

Certifique-se de ter os seguintes arquivos no diretório do projeto:
1. **`../ultimo.properties`** - Contém todas as Unidades Universitárias e o respectivo número do último guia de matrícula.
2. **`../cursos.properties`** - Contém o código de todos os cursos e seu respectivo nome.
3. **`../unidades.properties`** - Contém o nome de todas as unidades universitárias.

## Como Usar

### 1. Funções Auxiliares

#### `formatar(texto, ct, cf, est)`
Formata o `texto` com códigos de cor, fundo e estilo para exibição no terminal com base no código ANSI. Parâmetros:
- `ct`: Código da cor do texto.
- `cf`: Código da cor de fundo.
- `est`: Vetor de estilos.

| Código (texto) | Código (fundo) | Cor |
| --- | --- | --- |
| 30 | 40 | Preto |
| 31 | 41 | Vermelho Escuro |
| 32 | 42 | Verde Escuro |
| 33 | 43 | Laranja |
| 34 | 44 | Azul Escuro |
| 35 | 45 | Roxo |
| 36 | 46 | Verde Água |
| 37 | 47 | Cinza |
| 90 | 100 | Cinza Escuro |
| 91 | 101 | Vermelho Claro |
| 92 | 102 | Verde Limão |
| 93 | 103 | Amarelo Claro |
| 94 | 104 | Azul Claro |
| 95 | 105 | Rosa |
| 96 | 106 | Ciano Claro |
| 97 | 107 | Branco |

| Código (texto) | Formato |
| --- | --- |
| 1 | Negrito |
| 3 | Itálico |
| 4 | Sublinhado |

#### `adicionar(exceto = NULL)`
Atualiza o número (adicionando 1) do último guia de matrícula de cada Unidade Universitária no arquivo `ultimo.properties`. Parâmetro:
- `exceto`: (opcional) Vetor de abreviações de unidades universitárias que não se deseja utilizar a função.

### 2. Baixando Tabelas de Matrícula

#### `baixar_guia(nome, numeros, exceto = NULL)`
Baixa guias de matrícula de uma Unidade Universitária específica e salva em CSV. Parâmetros:
- `nome`: Abreviação da Unidade Universitária.
- `numeros`: Vetor com números dos guias a serem baixados.
- `exceto`: (opcional) Guias a serem ignorados.

#### `baixar(todos = FALSE, exceto = NULL)`
baixa o último guia com base em `ultimo.properties`, de cada Unidade Universitária. Parâmetros:
- `todos`: (opcional) quando `TRUE` baixará todos os guias de cada Unidade Universitária
- `exceto`: (opcional) Vetor de abreviações de Unidades Universitárias a serem ignoradas.

### 3. Pesquisa em Tabelas Baixadas

#### `pesquisa(item, unidade, busca, aviso, formatado, fore, back, estilo, multi, tipo)`
Realiza uma pesquisa nas tabelas baixadas, exibindo informações sobre disciplinas, turmas ou docentes. Parâmetros:
- `item`: Código ou nome da matéria/docente.
- `unidade`: (opcional) Abreviação da unidade onde procurar, se não informado em caso do **tipo** de pesquisa ser `código`, irá buscar com base no código, se o tipo for `matéria` ou `docente`, procurará em todas as unidades
- `busca`: Define o critério de parada da busca (`"semestre"`, `"todas"`, `"ultima"`), sendo `"semestre"` para o último semestre (independente de oferta), `"todas"` para todos os semestres, `"ultima"` para última vez que foi ofertada, `última` por padrão.
- `tipo`: Tipo de pesquisa (`"código"`, `"matéria"`, `"docente"`),  `código` por padrão.
- `aviso`:  (opcional) Um vetor de tamanho 2 para avisar se não foi ofertada, em que o primeiro elemento é referente a mensagem e o segundo ao retorno, desativado para ambos por padrão.
- `formatado`: (opcional) Ativa/desativa formatação de cores, por ativado por padrão
- `fore`, `back`, `estilo`: (opcional) Códigos de cor e estilo para formatação; Por padrão, azul, sem fundo, em itálico e negrito.
- `multi`: (opcional) Booleano que indica múltiplas cores no texto, desativado por padrão.
- `retornar`: Se True, retorna os resultados da busca, se False, apenas exibe no console, por padrão False.
- `tabela`: Se True, retorna em forma de tabela, se False, retorna em forma de texto, por padrão False.
- `ocultar`: Vetor (de tamanho 10) de Booleanos que alteram a visibilidade das informações da saída, sendo respectivamente: Código da Matéria, Nome da Matéria, Semestre, Número do Guia, Unidade Universitária, Número da Turma, Cursos, Vagas, Horários, Docente.


### Exemplos de Uso

- **A cada semestre**
  ```r
  # Atualizar o índice
  adicionar()
  
  # Baixar guias do semestre com base no índice
  baixar()
  ```
  
- **Teste de formatação de texto**
  ```r
  formatar("teste", ct=33, cf=107, est=c(3, 4))
  ```
  
- **Baixar Guia de Matrícula específico**
  ```r
  # Baixa os Guias de Matrícula do Instituto de Matemática e Estatística do 1 ao 13 com exceção do 3 e do 9
  baixar_guia("mat", c(1:13), exceto=c(3,9))
  ```
  
 - **Pesquisa**
  ```r
  # Buscar pela matéria de código MATD47
  pesquisa("MATD47")
  # Buscará nos guias do Instituto de Matemática e Estatística, a última vez que foi ofertada a matéria com esse código
  
  # Buscar pela matéria de nome estatística básica a
  pesquisa("ESTATÍSTICA BÁSICA A", tipo="matéria")
  # Buscará nos guias de todas as unidades, a última vez que foi ofertada a matéria com esse nome, devido a grande quantidade de guias e unidades, é recomendado informar a unidade, como no exemplo abaixo.
  
  # Buscar pela matéria de nome estatística básica a
  pesquisa("estatística básica a", unidade="mat", tipo="matéria")
  # Buscará nos guias do Instituto de Matemática e Estatística, a última vez que a matéria com esse nome foi ofertada
  ```
