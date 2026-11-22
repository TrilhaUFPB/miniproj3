-- 03_chat.sql — chat entre cliente e prestadora (Pessoa 3).
-- Roda depois de 01_identidade.sql e 02_descoberta.sql, que fornecem:
--   perfis(id uuid, nome, avatar_url, cidade, papel 'cliente' | 'prestadora')  (01)
--   perfil_tem_papel(perfil_id uuid, papel_esperado text)                     (02)
--
-- Regras:
--   * uma conversa por par cliente/prestadora, criada só por iniciar_conversa();
--   * só as duas participantes leem a conversa e as mensagens;
--   * só a autora insere mensagem, em nome próprio, numa conversa dela;
--   * ninguém edita nem apaga mensagem; lida_em só muda por marcar_lidas().

-- ---------------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------------
create table conversas (
  id                 bigint generated always as identity primary key,
  cliente_id         uuid not null references perfis (id) on delete cascade,
  prestadora_id      uuid not null references perfis (id) on delete cascade,
  criada_em          timestamptz not null default now(),
  ultima_mensagem_em timestamptz,
  constraint conversas_par_unico unique (cliente_id, prestadora_id),
  check (cliente_id <> prestadora_id)
);

-- cliente_id já é coberto pelo índice do UNIQUE.
create index conversas_prestadora_id_idx on conversas (prestadora_id);

create table mensagens (
  id          bigint generated always as identity primary key,
  conversa_id bigint not null references conversas (id) on delete cascade,
  autor_id    uuid not null references perfis (id) on delete cascade,
  texto       text not null check (char_length(btrim(texto)) between 1 and 2000),
  criada_em   timestamptz not null default now(),
  lida_em     timestamptz
);

create index mensagens_conversa_criada_idx on mensagens (conversa_id, criada_em);
create index mensagens_nao_lidas_idx on mensagens (conversa_id) where lida_em is null;

-- ---------------------------------------------------------------------------
-- Participação (security definer: a RLS de mensagens não depende da de conversas)
-- ---------------------------------------------------------------------------
create function participa_da_conversa(conversa_id bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversas c
    where c.id = participa_da_conversa.conversa_id
      and auth.uid() in (c.cliente_id, c.prestadora_id)
  );
$$;

-- ---------------------------------------------------------------------------
-- Triggers de mensagens
-- ---------------------------------------------------------------------------
-- Quem insere não escolhe a data nem já marca como lida.
create function mensagens_antes_de_inserir()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.criada_em := now();
  new.lida_em := null;
  return new;
end;
$$;

create trigger mensagens_antes_de_inserir
  before insert on mensagens
  for each row execute function mensagens_antes_de_inserir();

-- Mantém a lista de conversas ordenada pela mais recente.
-- security definer: conversas não tem policy de update.
create function conversas_atualizar_ultima_mensagem()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversas
  set ultima_mensagem_em = new.criada_em
  where id = new.conversa_id;
  return null;
end;
$$;

create trigger mensagens_depois_de_inserir
  after insert on mensagens
  for each row execute function conversas_atualizar_ultima_mensagem();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table conversas enable row level security;
alter table mensagens enable row level security;

create policy conversas_leitura_das_participantes on conversas
  for select to authenticated
  using (auth.uid() in (cliente_id, prestadora_id));

-- Sem policy de insert/update/delete em conversas: só iniciar_conversa() cria.

create policy mensagens_leitura_das_participantes on mensagens
  for select to authenticated
  using (participa_da_conversa(conversa_id));

create policy mensagens_insert_da_autora on mensagens
  for insert to authenticated
  with check (
    autor_id = auth.uid()
    and participa_da_conversa(conversa_id)
  );

-- Sem policy de update/delete em mensagens: só marcar_lidas() muda lida_em.

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------
-- Devolve a conversa da cliente logada com a prestadora, criando se não existir.
-- Chamada do front: supabase.rpc('iniciar_conversa', { prestadora_id })
create function iniciar_conversa(prestadora_id uuid)
returns conversas
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cliente  uuid := auth.uid();
  v_conversa public.conversas;
begin
  if v_cliente is null then
    raise exception 'É preciso estar logada para conversar.'
      using errcode = '28000';
  end if;

  if not public.perfil_tem_papel(v_cliente, 'cliente') then
    raise exception 'Só clientes podem iniciar uma conversa.'
      using errcode = '42501';
  end if;

  if not public.perfil_tem_papel(iniciar_conversa.prestadora_id, 'prestadora') then
    raise exception 'Prestadora não encontrada.'
      using errcode = 'P0002';
  end if;

  insert into public.conversas (cliente_id, prestadora_id)
  values (v_cliente, iniciar_conversa.prestadora_id)
  on conflict on constraint conversas_par_unico do nothing;

  select c.* into v_conversa
  from public.conversas c
  where c.cliente_id = v_cliente
    and c.prestadora_id = iniciar_conversa.prestadora_id;

  return v_conversa;
end;
$$;

-- Marca como lidas as mensagens recebidas na conversa. Devolve quantas marcou.
-- Chamada do front: supabase.rpc('marcar_lidas', { conversa_id })
create function marcar_lidas(conversa_id bigint)
returns integer
language sql
volatile
security definer
set search_path = ''
as $$
  with marcadas as (
    update public.mensagens m
    set lida_em = now()
    where m.conversa_id = marcar_lidas.conversa_id
      and m.autor_id <> auth.uid()
      and m.lida_em is null
      and public.participa_da_conversa(m.conversa_id)
    returning 1
  )
  select count(*)::int from marcadas;
$$;

-- Total de mensagens não lidas da usuária logada (para o <UnreadBadge />).
-- security invoker: a RLS de mensagens já limita às conversas dela.
-- Chamada do front: supabase.rpc('nao_lidas')
create function nao_lidas()
returns integer
language sql
stable
set search_path = ''
as $$
  select count(*)::int
  from public.mensagens m
  where m.autor_id <> auth.uid()
    and m.lida_em is null;
$$;

revoke execute on function participa_da_conversa(bigint) from public, anon;
revoke execute on function iniciar_conversa(uuid) from public, anon;
revoke execute on function marcar_lidas(bigint) from public, anon;
revoke execute on function nao_lidas() from public, anon;
grant execute on function participa_da_conversa(bigint) to authenticated;
grant execute on function iniciar_conversa(uuid) to authenticated;
grant execute on function marcar_lidas(bigint) to authenticated;
grant execute on function nao_lidas() to authenticated;

-- ---------------------------------------------------------------------------
-- Lista de conversas: uma linha por conversa da usuária logada
--   outra_*: a outra participante (para nome e avatar na lista)
--   ultima_mensagem_*: prévia na lista
--   nao_lidas: mensagens recebidas ainda não lidas nesta conversa
-- security_invoker: a view respeita a RLS de conversas, mensagens e perfis.
-- ---------------------------------------------------------------------------
create view conversas_resumo
with (security_invoker = true) as
select
  c.id,
  c.cliente_id,
  c.prestadora_id,
  c.criada_em,
  c.ultima_mensagem_em,
  outra.id         as outra_id,
  outra.nome       as outra_nome,
  outra.avatar_url as outra_avatar_url,
  outra.papel      as outra_papel,
  u.texto          as ultima_mensagem_texto,
  u.autor_id       as ultima_mensagem_autor_id,
  coalesce(n.nao_lidas, 0) as nao_lidas
from conversas c
join perfis outra
  on outra.id = case when c.cliente_id = auth.uid() then c.prestadora_id else c.cliente_id end
left join lateral (
  select m.texto, m.autor_id
  from mensagens m
  where m.conversa_id = c.id
  order by m.criada_em desc, m.id desc
  limit 1
) u on true
left join lateral (
  select count(*)::int as nao_lidas
  from mensagens m
  where m.conversa_id = c.id
    and m.autor_id <> auth.uid()
    and m.lida_em is null
) n on true;

revoke select on conversas_resumo from anon;
grant select on conversas_resumo to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime: mensagens novas chegam no front (respeitando a RLS de select)
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.mensagens;
  end if;
end;
$$;
