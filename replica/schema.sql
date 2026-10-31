-- Schema do clone (Supabase / Postgres 15+). Primeira migration.
-- Convenções: uuid em tudo, timestamptz em UTC, datas de estudo em `date` no fuso do usuário,
-- tempo em minutos inteiros, RLS ligado em toda tabela com dono.

create extension if not exists pgcrypto;

-- ---------- utilitários ----------
create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

-- ---------- perfil e preferências ----------
create table profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 30),
  full_name text,
  birth_date date,
  area text check (area in ('fiscal','controle','policial','tribunais','administrativa','bancaria','outra')),
  avatar_path text,
  theme text not null default 'light' check (theme in ('light','dark')),
  timezone text not null default 'America/Sao_Paulo',
  week_start_day smallint not null default 1 check (week_start_day between 0 and 6), -- 0 domingo
  weekly_minutes_goal int not null default 900 check (weekly_minutes_goal >= 0),
  weekly_questions_goal int not null default 0 check (weekly_questions_goal >= 0),
  block_minutes int not null default 60 check (block_minutes in (30,60,90,120)),
  session_min_minutes int not null default 45 check (session_min_minutes > 0),
  session_max_minutes int not null default 90,
  review_intervals int[] not null default '{7,15,30,30,60}', -- o último intervalo se repete
  ranking_opt_in boolean not null default false,
  is_admin boolean not null default false,
  onboarded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint session_range check (session_max_minutes >= session_min_minutes),
  constraint intervals_positive check (review_intervals <> '{}' and 0 < all (review_intervals))
);
create trigger trg_profiles_updated before update on profiles for each row execute function set_updated_at();

-- ---------- catálogo de editais (conteúdo do próprio produto) ----------
create table editais (
  id uuid primary key default gen_random_uuid(),
  org text not null,                    -- ex.: PC-MG
  cargo text not null,
  year smallint not null check (year between 2000 and 2100),
  banca text,
  category text not null check (category in ('policial','policia_judicial','guarda_municipal','tribunais','controle','fiscal','bancaria','administrativa')),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  source_url text,
  published_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org, cargo, year)
);
create index on editais (status, category);
create trigger trg_editais_updated before update on editais for each row execute function set_updated_at();

create table edital_subjects (
  id uuid primary key default gen_random_uuid(),
  edital_id uuid not null references editais(id) on delete cascade,
  name text not null,
  weight numeric(8,2) check (weight is null or weight >= 0), -- nº de questões; null = base 1
  position int not null default 0,
  created_at timestamptz not null default now(),
  unique (edital_id, name)
);
create index on edital_subjects (edital_id, position);

create table edital_topics (
  id uuid primary key default gen_random_uuid(),
  edital_subject_id uuid not null references edital_subjects(id) on delete cascade,
  parent_id uuid references edital_topics(id) on delete cascade,
  title text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);
create index on edital_topics (edital_subject_id, position);
create index on edital_topics (parent_id);

-- pedidos de edital feitos pelos usuários
create table edital_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  concurso text not null,
  cargo text,
  banca text,
  year smallint check (year between 2000 and 2100),
  source_url text,
  pdf_path text,                         -- Storage, bucket privado
  status text not null default 'pending' check (status in ('pending','in_review','published','rejected')),
  edital_id uuid references editais(id) on delete set null,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint has_source check (source_url is not null or pdf_path is not null or cargo is not null)
);
create index on edital_requests (status, created_at);
create index on edital_requests (user_id);
create trigger trg_requests_updated before update on edital_requests for each row execute function set_updated_at();

create table edital_request_votes (   -- "eu também quero" conta pedidos duplicados
  request_id uuid not null references edital_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (request_id, user_id)
);

-- ---------- matérias do usuário ----------
create table subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  parent_id uuid references subjects(id) on delete set null,
  edital_subject_id uuid references edital_subjects(id) on delete set null,
  name text not null,
  color text not null default '#64748b',
  pages_total int check (pages_total is null or pages_total > 0),
  review_mode text not null default 'time' check (review_mode in ('time','lessons','none')),
  review_every_n_lessons smallint check (review_every_n_lessons is null or review_every_n_lessons > 0),
  lesson_names jsonb not null default '{}',   -- {"1": "Direitos fundamentais"}
  active boolean not null default true,
  in_cycle boolean not null default true,
  cycle_minutes int not null default 90 check (cycle_minutes >= 0),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lessons_need_n check (review_mode <> 'lessons' or review_every_n_lessons is not null)
);
create unique index subjects_user_name on subjects (user_id, lower(name)) where archived_at is null;
create index on subjects (user_id, active);
create index on subjects (parent_id);
create trigger trg_subjects_updated before update on subjects for each row execute function set_updated_at();

-- edital que o usuário segue e checklist de tópicos
create table user_edital_follows (
  user_id uuid not null references auth.users(id) on delete cascade,
  edital_id uuid not null references editais(id) on delete cascade,
  followed_at timestamptz not null default now(),
  suggest_next_topic boolean not null default false,
  primary key (user_id, edital_id)
);
create index on user_edital_follows (edital_id);

create table topic_checks (
  user_id uuid not null references auth.users(id) on delete cascade,
  topic_id uuid not null references edital_topics(id) on delete cascade,
  checked_at timestamptz not null default now(),
  primary key (user_id, topic_id)
);

-- alvos (data da prova e horas)
create table targets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  edital_id uuid references editais(id) on delete set null,
  label text not null,
  exam_date date,
  hours_goal_minutes int check (hours_goal_minutes is null or hours_goal_minutes > 0),
  count_from date not null default current_date,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_primary_target on targets (user_id) where is_primary;
create index on targets (user_id);
create trigger trg_targets_updated before update on targets for each row execute function set_updated_at();

-- ---------- planejamento: ciclo e semana ----------
create table study_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('cycle','week')),
  edital_id uuid references editais(id) on delete set null,
  minutes_per_lap int not null check (minutes_per_lap > 0),
  starts_on date not null default current_date,
  ends_on date,
  weight_by_edital boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint plan_dates check (ends_on is null or ends_on >= starts_on)
);
create unique index one_active_plan on study_plans (user_id) where active;
create trigger trg_plans_updated before update on study_plans for each row execute function set_updated_at();

create table plan_slots (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references study_plans(id) on delete cascade,
  subject_id uuid not null references subjects(id) on delete cascade,
  position int not null,
  minutes int not null check (minutes > 0),
  weekday smallint check (weekday between 0 and 6), -- só para kind = week
  created_at timestamptz not null default now()
);
create index on plan_slots (plan_id, position);
create index on plan_slots (subject_id);

create table cycle_laps (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references study_plans(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create unique index one_open_lap on cycle_laps (plan_id) where ended_at is null;

-- ---------- registro de estudo ----------
create table study_sessions (
  id uuid primary key default gen_random_uuid(),   -- gerado no cliente, para o modo offline
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null, -- null = estudo livre
  studied_on date not null,                         -- dia no fuso do usuário
  task text not null check (task in ('pdf','video','questions','law','flashcards','summary','theory','review','mock','other')),
  source text not null default 'manual' check (source in ('timer','manual','forgot','review')),
  lesson text,
  topic text,
  topic_id uuid references edital_topics(id) on delete set null,
  page_start int check (page_start is null or page_start >= 0),
  page_end int check (page_end is null or page_end >= 0),
  video_name text,
  video_stopped_at interval,
  minutes int not null default 0 check (minutes >= 0),
  questions_done int not null default 0 check (questions_done >= 0),
  correct int not null default 0 check (correct >= 0),
  sure_done int check (sure_done is null or sure_done >= 0),     -- análise de confiança
  sure_correct int check (sure_correct is null or sure_correct >= 0),
  doubt_done int check (doubt_done is null or doubt_done >= 0),
  doubt_correct int check (doubt_correct is null or doubt_correct >= 0),
  comment text,
  lesson_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint has_time_or_questions check (minutes > 0 or questions_done > 0),
  constraint correct_le_done check (correct <= questions_done),
  constraint pages_order check (page_end is null or page_start is null or page_end >= page_start),
  constraint confidence_sums check (
    (sure_done is null and doubt_done is null)
    or (coalesce(sure_done,0) + coalesce(doubt_done,0) <= questions_done
        and coalesce(sure_correct,0) <= coalesce(sure_done,0)
        and coalesce(doubt_correct,0) <= coalesce(doubt_done,0))
  )
);
create index on study_sessions (user_id, studied_on);
create index on study_sessions (user_id, subject_id, studied_on);
create index on study_sessions (subject_id, lesson);
create trigger trg_sessions_updated before update on study_sessions for each row execute function set_updated_at();

-- cronômetro em andamento (um por usuário; sobrevive a recarregar a página)
create table timers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  running boolean not null default false,
  started_at timestamptz,               -- início do trecho atual, quando running
  accumulated_seconds int not null default 0 check (accumulated_seconds >= 0),
  updated_at timestamptz not null default now()
);

-- ---------- revisões espaçadas ----------
create table reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid not null references subjects(id) on delete cascade,
  source_session_id uuid references study_sessions(id) on delete set null, -- aula concluída que originou
  kind text not null check (kind in ('time','lessons')),
  number int not null check (number > 0),
  lesson text not null default '',
  label text,                            -- ex.: PDF 1/6, TEC, Lei seca
  battery_index int,
  battery_total int,
  questions_total int check (questions_total is null or questions_total > 0),
  scheduled_on date not null,
  status text not null default 'pending' check (status in ('pending','done')),
  done_on date,
  done_session_id uuid references study_sessions(id) on delete set null,
  questions_done int check (questions_done is null or questions_done >= 0),
  correct int check (correct is null or correct >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint done_consistent check ((status = 'done') = (done_on is not null)),
  constraint battery_ok check (battery_index is null or (battery_total is not null and battery_index between 1 and battery_total)),
  constraint correct_le_done check (correct is null or questions_done is null or correct <= questions_done),
  -- evita que "Fazer" clicado duas vezes crie a próxima revisão em duplicidade
  unique (user_id, subject_id, kind, lesson, number)
);
create index on reviews (user_id, status, scheduled_on);
create index on reviews (subject_id);
create trigger trg_reviews_updated before update on reviews for each row execute function set_updated_at();

-- revisão por aulas: quais aulas já foram revisadas dentro de uma revisão
create table review_lessons (
  review_id uuid not null references reviews(id) on delete cascade,
  lesson text not null,
  session_id uuid references study_sessions(id) on delete set null,
  done_on date not null default current_date,
  primary key (review_id, lesson)
);

-- ---------- caderno de erros ----------
create table notebook_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references subjects(id) on delete set null,
  topic text,
  banca text,
  origin text,                           -- onde fez
  exam text,
  solved_on date not null default current_date,
  statement text not null check (char_length(statement) > 0),
  alternatives text,
  my_answer text,
  answer_key text,
  reason text check (reason in ('nao_sabia','confundi','atencao','chutei','acertei_duvida')),
  note text,
  highlights jsonb not null default '[]', -- [{start,end,kind: 'grifo'|'pegadinha'|'nota'}]
  intervals int[] not null default '{7,15,30}',
  log_in_stats boolean not null default false,
  mastered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notebook_intervals check (intervals <> '{}' and 0 < all (intervals))
);
create index on notebook_items (user_id, mastered_at);
create index on notebook_items (subject_id);
create trigger trg_notebook_updated before update on notebook_items for each row execute function set_updated_at();

create table notebook_reviews (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references notebook_items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  number int not null check (number > 0),
  scheduled_on date not null,
  done_on date,
  correct boolean,
  unique (item_id, number),
  constraint nb_done_consistent check ((done_on is null) = (correct is null))
);
create index on notebook_reviews (user_id, scheduled_on) where done_on is null;

-- ---------- ranking (instantâneo semanal, só quem aceitou) ----------
create table ranking_weekly (
  week_start date not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  minutes int not null default 0,
  questions int not null default 0,
  streak_days int not null default 0,
  primary key (week_start, user_id)
);
create index on ranking_weekly (week_start, minutes desc);

-- ---------- suporte ----------
create table bug_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  title text not null,
  details text,
  page text,
  created_at timestamptz not null default now()
);

-- ---------- cobrança (adiada; só o gancho de acesso) ----------
create table entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan text not null default 'none' check (plan in ('none','basic','pro')),
  status text not null default 'inactive' check (status in ('inactive','active','past_due','refunded','canceled')),
  provider text,                          -- kiwify, hotmart... (camada trocável)
  provider_ref text,
  current_period_end timestamptz,
  full_access_from timestamptz,           -- libera abas só depois da garantia, se desejado
  updated_at timestamptz not null default now()
);
create table billing_events (             -- idempotência dos webhooks
  provider text not null,
  event_id text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  primary key (provider, event_id)
);

-- ---------- visões de apoio ----------
create view study_days with (security_invoker = true) as
  select user_id, studied_on as day,
         sum(minutes)::int as minutes,
         sum(questions_done)::int as questions,
         sum(correct)::int as correct
  from study_sessions group by user_id, studied_on;

-- páginas lidas por matéria: fim - início + 1 por registro de PDF (regra a confirmar)
create view subject_reading with (security_invoker = true) as
  select s.id as subject_id, s.user_id, s.pages_total,
         coalesce(sum(greatest(ss.page_end - ss.page_start + 1, 0)) filter (where ss.task = 'pdf'), 0)::int as pages_read,
         coalesce(sum(ss.minutes) filter (where ss.task = 'pdf'), 0)::int as pdf_minutes
  from subjects s left join study_sessions ss on ss.subject_id = s.id
  group by s.id;

-- ---------- RLS ----------
create or replace function is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select p.is_admin from profiles p where p.user_id = auth.uid()), false)
$$;

do $$
declare t text;
begin
  -- tabelas do usuário: só o dono lê e escreve
  foreach t in array array['profiles','subjects','user_edital_follows','topic_checks','targets','study_plans',
    'study_sessions','timers','reviews','notebook_items','notebook_reviews','bug_reports','entitlements']
  loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

create policy own_profile      on profiles            for all using (user_id = auth.uid()) with check (user_id = auth.uid() and (is_admin = false or is_admin()));
create policy own_subjects     on subjects            for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_follows      on user_edital_follows for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_checks       on topic_checks        for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_targets      on targets             for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_plans        on study_plans         for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_sessions     on study_sessions      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_timers       on timers              for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_reviews      on reviews             for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_notebook     on notebook_items      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_nb_reviews   on notebook_reviews    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_bugs         on bug_reports         for insert with check (user_id = auth.uid());
create policy read_own_ent     on entitlements        for select using (user_id = auth.uid()); -- escrita só pelo servidor (service role)

-- tabelas filhas de um dono indireto
alter table plan_slots enable row level security;
create policy own_slots on plan_slots for all
  using (exists (select 1 from study_plans p where p.id = plan_id and p.user_id = auth.uid()))
  with check (exists (select 1 from study_plans p where p.id = plan_id and p.user_id = auth.uid()));
alter table cycle_laps enable row level security;
create policy own_laps on cycle_laps for all
  using (exists (select 1 from study_plans p where p.id = plan_id and p.user_id = auth.uid()))
  with check (exists (select 1 from study_plans p where p.id = plan_id and p.user_id = auth.uid()));
alter table review_lessons enable row level security;
create policy own_review_lessons on review_lessons for all
  using (exists (select 1 from reviews r where r.id = review_id and r.user_id = auth.uid()))
  with check (exists (select 1 from reviews r where r.id = review_id and r.user_id = auth.uid()));

-- catálogo: todo usuário logado lê o que está publicado; só admin escreve
alter table editais enable row level security;
alter table edital_subjects enable row level security;
alter table edital_topics enable row level security;
create policy read_editais on editais for select using (status = 'published' or is_admin());
create policy admin_editais on editais for all using (is_admin()) with check (is_admin());
create policy read_edital_subjects on edital_subjects for select
  using (exists (select 1 from editais e where e.id = edital_id and (e.status = 'published' or is_admin())));
create policy admin_edital_subjects on edital_subjects for all using (is_admin()) with check (is_admin());
create policy read_edital_topics on edital_topics for select
  using (exists (select 1 from edital_subjects s join editais e on e.id = s.edital_id
                 where s.id = edital_subject_id and (e.status = 'published' or is_admin())));
create policy admin_edital_topics on edital_topics for all using (is_admin()) with check (is_admin());

-- pedidos: o autor vê e cria os seus; admin vê e trata todos
alter table edital_requests enable row level security;
create policy own_requests on edital_requests for select using (user_id = auth.uid() or is_admin());
create policy create_requests on edital_requests for insert with check (user_id = auth.uid() and status = 'pending');
create policy admin_requests on edital_requests for update using (is_admin()) with check (is_admin());
alter table edital_request_votes enable row level security;
create policy own_votes on edital_request_votes for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ranking: lê quem aceitou aparecer; escreve só o job (service role)
alter table ranking_weekly enable row level security;
create policy read_ranking on ranking_weekly for select
  using (exists (select 1 from profiles p where p.user_id = ranking_weekly.user_id and p.ranking_opt_in));

-- billing_events: sem policy = só service role
alter table billing_events enable row level security;
