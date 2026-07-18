-- ============================================================
-- NEXUS IA — Setup do banco no Supabase
-- Rode este script inteiro em: Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1) Tabela de artigos
create table if not exists articles (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  excerpt text not null default '',
  body text not null default '',
  image_url text not null default '',
  category text not null default 'IA & Ferramentas',
  category_class text not null default 'cl-ia',   -- cl-ia | cl-neg | cl-cri | cl-edu | cl-seg | cl-din | cl-not
  emoji text not null default '🤖',
  read_minutes int not null default 5,
  featured boolean not null default false,          -- aparece no destaque (topo do site)
  published boolean not null default false,         -- só aparece no site quando marcado
  author text not null default 'Redação NEXUS IA',
  created_at timestamptz not null default now(),
  published_at timestamptz
);

-- 2) Segurança (RLS) — protege a tabela de escrita por qualquer visitante
alter table articles enable row level security;

-- qualquer pessoa pode LER artigos publicados (site público)
create policy "Leitura pública de artigos publicados"
on articles for select
using (published = true);

-- só usuário logado (você, no admin) pode ler tudo, inclusive rascunhos
create policy "Leitura total para logados"
on articles for select
using (auth.role() = 'authenticated');

-- só usuário logado pode inserir/editar/apagar
create policy "Escrita só para logados"
on articles for insert
with check (auth.role() = 'authenticated');

create policy "Update só para logados"
on articles for update
using (auth.role() = 'authenticated');

create policy "Delete só para logados"
on articles for delete
using (auth.role() = 'authenticated');

-- 3) Índices úteis
create index if not exists idx_articles_published on articles(published, published_at desc);
create index if not exists idx_articles_category on articles(category);

-- ============================================================
-- 4) Storage — bucket público para as imagens dos artigos
-- Isso aqui você faz pelo painel (não dá pra criar bucket 100% por SQL
-- de forma confiável em todas as versões do Supabase):
--
--   Supabase > Storage > New bucket
--   Nome: article-images
--   Public bucket: SIM (marcar essa opção)
--
-- Depois, rode este bloco abaixo pra liberar upload/leitura desse bucket:
-- ============================================================

create policy "Leitura pública das imagens"
on storage.objects for select
using (bucket_id = 'article-images');

create policy "Upload só para logados"
on storage.objects for insert
with check (bucket_id = 'article-images' and auth.role() = 'authenticated');

create policy "Delete de imagem só para logados"
on storage.objects for delete
using (bucket_id = 'article-images' and auth.role() = 'authenticated');
