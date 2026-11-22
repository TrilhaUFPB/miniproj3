# Banco de dados (Supabase)

Aplicar no SQL Editor do projeto, nesta ordem:

1. `migrations/01_identidade.sql` (Pessoa 1)
2. `migrations/02_descoberta.sql` (Pessoa 2)
3. `migrations/03_chat.sql` (Pessoa 3)
4. `seed-demo.sql` (Pessoa 3), só para desenvolvimento e demo

Regra: uma área só referencia outra por `perfis(id)`. RLS ligado em toda tabela.
Avise o grupo antes de aplicar uma migration no projeto compartilhado.
