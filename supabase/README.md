# Banco de dados (Supabase)

Aplicar no SQL Editor do projeto, nesta ordem:

1. `migrations/01_identidade.sql` (Pessoa 1)
2. `migrations/02_descoberta.sql` (Pessoa 2)
3. `migrations/03_chat.sql` (Pessoa 3)
4. `seed-demo.sql` (Pessoa 3), só para desenvolvimento e demo (cria usuários com senha conhecida: nunca rodar no projeto compartilhado ou de produção)

Regra: as áreas só se ligam por `perfis(id)`; a Pessoa 2 também lê `servicos_prestadora` e
`categorias_servico` (view de busca), então `01_identidade.sql` precisa estar fechado antes. RLS ligado em toda tabela.
Avise o grupo antes de aplicar uma migration no projeto compartilhado.
