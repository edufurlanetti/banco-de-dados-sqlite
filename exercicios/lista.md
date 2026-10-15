# Lista de exercícios — Biblioteca (SQLite)

Crie o banco com `python app/biblioteca.py criar` ou executando os scripts `01` e `02` no `sqlite3`.

1. Liste os livros publicados a partir de 2015, do mais novo para o mais antigo.
2. Mostre quantos livros existem por assunto.
3. Liste os leitores que **nunca** pegaram um livro emprestado.
4. Qual é o tempo médio (em dias) que os leitores ficam com um livro nos empréstimos já devolvidos?
5. Crie uma *view* `vw_emprestimos_abertos` com leitor, título, tombo e data prevista.
6. Professores podem ter até 5 empréstimos simultâneos e alunos, até 2. Crie uma *trigger* que impeça empréstimos acima desse limite.
7. Na aplicação Python, adicione o comando `historico <id_leitor>` que liste todos os empréstimos do leitor. Use consulta parametrizada.

As soluções estão em [`solucoes.sql`](solucoes.sql).
