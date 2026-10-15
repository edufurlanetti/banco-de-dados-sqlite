-- =============================================================
-- Biblioteca — Dados de exemplo (fictícios, para fins didáticos)
-- =============================================================
PRAGMA foreign_keys = ON;

INSERT INTO livro (id_livro, isbn, titulo, editora, ano, assunto) VALUES
(1, '9788535290011', 'Sistemas de Banco de Dados',              'Pearson',   2019, 'Banco de Dados'),
(2, '9788521631231', 'Projeto de Banco de Dados',               'Bookman',   2009, 'Banco de Dados'),
(3, '9788576082675', 'Código Limpo',                            'Alta Books',2009, 'Engenharia de Software'),
(4, '9788575224366', 'Python Fluente',                          'Novatec',   2015, 'Programação'),
(5, '9788543004792', 'Algoritmos: Teoria e Prática',            'Elsevier',  2012, 'Algoritmos'),
(6, '9788582603369', 'Redes de Computadores e a Internet',      'Pearson',   2021, 'Redes');

INSERT INTO autor (id_autor, nome) VALUES
(1, 'Ramez Elmasri'), (2, 'Shamkant Navathe'), (3, 'Carlos Alberto Heuser'),
(4, 'Robert C. Martin'), (5, 'Luciano Ramalho'), (6, 'Thomas H. Cormen'),
(7, 'James F. Kurose'), (8, 'Keith W. Ross');

INSERT INTO livro_autor VALUES
(1, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (6, 8);

INSERT INTO exemplar (id_exemplar, id_livro, tombo) VALUES
(1, 1, 'BD-0001'), (2, 1, 'BD-0002'), (3, 2, 'BD-0003'),
(4, 3, 'ES-0001'), (5, 4, 'PR-0001'), (6, 4, 'PR-0002'),
(7, 5, 'AL-0001'), (8, 6, 'RD-0001');

INSERT INTO leitor (id_leitor, nome, email, tipo) VALUES
(1, 'Ana Souza',      'ana@aluno.edu',    'ALUNO'),
(2, 'Bruno Lima',     'bruno@aluno.edu',  'ALUNO'),
(3, 'Carla Mendes',   'carla@aluno.edu',  'ALUNO'),
(4, 'Prof. Marcos',   'marcos@prof.edu',  'PROFESSOR');

-- Empréstimos já devolvidos
INSERT INTO emprestimo (id_exemplar, id_leitor, data_emprestimo, data_prevista, data_devolucao) VALUES
(1, 1, '2026-02-02', '2026-02-09', '2026-02-08'),
(4, 2, '2026-02-03', '2026-02-10', '2026-02-15'),   -- devolvido com atraso
(5, 1, '2026-02-10', '2026-02-17', '2026-02-16');

-- Empréstimos em aberto (as triggers marcam o exemplar como EMPRESTADO)
INSERT INTO emprestimo (id_exemplar, id_leitor, data_emprestimo, data_prevista) VALUES
(2, 3, '2026-03-01', '2026-03-08'),
(7, 4, '2026-03-02', '2026-03-30'),
(5, 2, '2026-03-05', '2026-03-12');

-- Indexa o conteúdo para a busca textual
INSERT INTO livro_fts (livro_fts) VALUES ('rebuild');
