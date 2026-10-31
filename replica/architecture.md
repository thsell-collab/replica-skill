# Architecture: app de rotina de estudos para concursos (rebuild das funções de Exemplifica Concursos + Corte da Nota)

Lê `replica/recon.md` e `replica/features.csv`. O SQL está em `replica/schema.sql` (testado: aplica limpo no Postgres 16 e as regras de acesso e restrições se comportam como descrito).

## Stack

| layer | choice | why |
| --- | --- | --- |
| web | Next.js (App Router) + TypeScript, PWA | uma base de código para o computador e o celular; instala na tela inicial como os dois originais |
| styling | Tailwind, tokens do `replica-design`, tema claro e escuro | os dois apps têm os dois temas |
| database | Postgres no Supabase | uma só base; RLS faz o isolamento por usuário sem código extra |
| ORM | SQL das migrations + Drizzle só para tipos e consultas | o schema já é SQL; Drizzle evita reescrevê-lo |
| auth | Supabase Auth (e-mail e senha, recuperar senha) | o login dos originais é só e-mail e senha |
| payments | adiado. Camada `billing` com tabela `entitlements` e `billing_events` | você escolhe depois (Kiwify, Hotmart etc.); o app só lê "tem acesso?" |
| email | Resend | redefinir senha, aviso de edital publicado, lembrete de revisão |
| jobs | Vercel Cron + Supabase pg_cron | ranking semanal, lembretes, limpeza |
| files | Supabase Storage (bucket privado) | PDFs de edital enviados pelos usuários |
| import de edital | job que lê o texto do PDF e pede a uma IA para sugerir matérias e tópicos; um administrador revisa e publica | transforma o gargalo de conteúdo em minutos por edital |
| hosting | Vercel | simples e barato com poucos usuários |

Um banco, sem microsserviços. Se você já usa outra stack, troque; o schema e as regras valem igual.

## Schema

Tabelas: 23 (22 de dados e 1 de idempotência). Regras de acesso: **RLS no Postgres**.
SQL completo em `replica/schema.sql`. Resumo:

| grupo | tabelas |
| --- | --- |
| perfil | `profiles` (preferências, fuso, início da semana, metas, intervalos de revisão, `is_admin`) |
| edital (catálogo) | `editais`, `edital_subjects` (peso), `edital_topics` (árvore), `edital_requests`, `edital_request_votes` |
| do usuário | `subjects` (submatérias, modo de revisão), `user_edital_follows`, `topic_checks`, `targets` |
| planejamento | `study_plans` (ciclo ou semana), `plan_slots`, `cycle_laps` |
| estudo | `study_sessions`, `timers` |
| revisões | `reviews`, `review_lessons`, `notebook_items`, `notebook_reviews` |
| social | `ranking_weekly` |
| suporte e cobrança | `bug_reports`, `entitlements`, `billing_events` |
| visões | `study_days`, `subject_reading` |

Decisões que valem destacar:
- **Fuso:** `study_sessions.studied_on` é `date` no fuso do usuário (padrão Brasília). Os instantes ficam em `timestamptz` UTC.
- **Tempo em minutos inteiros.** O cronômetro guarda segundos em `timers`; ao salvar, o app arredonda (regra a decidir, ver "Perguntas").
- **Revisão duplicada é problema do banco:** `unique (user_id, subject_id, kind, lesson, number)` impede que um duplo clique em "Fazer" crie duas próximas revisões.
- **Um plano ativo e um alvo principal por usuário** (índices únicos parciais).
- **Confiança nas questões:** colunas `sure_*` e `doubt_*` com checagem de soma; falso positivo e falso negativo saem de uma consulta, sem tabela extra.
- **Páginas lidas** = fim - início + 1 por registro de PDF. É suposição: o Exemplifica não deixou claro. A visão `subject_reading` muda num só lugar se a regra for outra.
- **Admin:** `profiles.is_admin` só pode ser alterado por um admin (testado). O catálogo de editais só admin escreve; o usuário comum só lê o que está publicado.
- **LGPD:** CPF **não** é coletado (o Exemplifica coleta, mas o clone não precisa). Apagar a conta remove tudo em cascata a partir de `auth.users`.
- **Ficou de fora desta migration (segunda migration, quando houver conteúdo):** banco de questões, lei seca, leis mapeadas, flashcards, notas, radar de concursos. Ver `features.csv`.

## API

Server actions e route handlers do Next.js. "Quem" = dono (autenticado, filtrado por RLS), admin ou público.

| method path | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| POST /auth/signup, /auth/login, /auth/reset | conta, entrar, recuperar | público | e-mail, senha | sessão | F01 |
| PATCH /me | nome, área, metas, preferências, tema | dono | campos | perfil | F01 |
| GET /subjects · POST · PATCH · DELETE | matérias e submatérias | dono | nome, páginas, modo de revisão | matéria | F03 |
| GET /editais?categoria&q | catálogo publicado | logado | filtros | lista | F02 |
| GET /editais/:id | edital com matérias e tópicos | logado | id | árvore | F02 |
| POST /editais/:id/follow · DELETE | seguir ou deixar | dono | id | follow | F02 |
| PUT /topics/:id/check · DELETE | marcar tópico | dono | id | check | F02 |
| POST /editais/:id/subjects/import | levar matérias do edital ao planejamento | dono | matérias escolhidas | `subjects` criadas, nomes iguais reaproveitados | F02 |
| POST /edital-requests | pedir edital | dono | concurso, cargo, banca, ano, link ou PDF | pedido `pending` | F10 |
| POST /edital-requests/:id/vote | "eu também quero" | dono | id | voto | F10 |
| GET /edital-requests/mine | status dos meus pedidos | dono | — | lista | F10 |
| GET /admin/edital-requests · PATCH | fila e mudança de status | admin | filtros | lista | F10 |
| POST /admin/edital-requests/:id/import | extrai matérias e tópicos do PDF e cria rascunho | admin | id | edital `draft` | F10 |
| PATCH /admin/editais/:id · POST publish | revisar e publicar | admin | árvore | edital `published` | F10 |
| POST /plans/preview | calcula ciclo sem salvar (assistente) | dono | concurso, horas, sessão, pesos | slots | F02 |
| POST /plans | cria ou refaz o plano ativo | dono | slots, kind | plano | F02 F03 |
| POST /plans/:id/laps · PATCH | começar nova volta | dono | — | volta | F04 |
| GET /plans/active/progress | minutos da volta por matéria | dono | — | progresso | F04 |
| PUT /timer · POST /timer/stop | iniciar, pausar, retomar, parar | dono | matéria | sessão pré-preenchida | F04 |
| POST /sessions · PATCH · DELETE | registrar, editar, remover estudo | dono | campos do registro | sessão; agenda revisões se `lesson_completed` | F04 F05 |
| GET /sessions?período&matéria&tarefa&aula | histórico | dono | filtros | lista | F13 |
| GET /reviews?status&matéria | A fazer, futuras, feitas | dono | filtros | lista | F06 |
| POST /reviews/:id/do | marca como feita e agenda a próxima | dono | questões, acertos, tempo, tipo da próxima | revisão e sessão | F06 |
| POST /reviews/:id/postpone | adiar N dias | dono | dias | revisão | F06 |
| PATCH/DELETE /reviews/:id | editar ou excluir | dono | campos | revisão | F06 |
| GET/POST /notebook · PATCH · DELETE | caderno de erros | dono | enunciado, motivo, intervalos | item | F07 |
| POST /notebook/:id/review | revisão do item | dono | acertou? | próxima data | F07 |
| GET /stats/overview, /stats/subjects, /stats/lessons, /stats/weekly, /stats/confidence | todos os números das telas | dono | período, matéria | séries | F09 |
| GET /streak | dias seguidos, recorde, dias estudados no ano | dono | — | números | F09 |
| GET /ranking?aba=horas\|constancia\|questoes | Top 10 da última semana | logado | — | lista de quem aceitou | F09 |
| POST /bug-reports | reportar bug | logado | texto | ok | — |
| DELETE /me/data | apagar todos os dados | dono | confirmação | ok | — |

Webhooks in: `POST /api/webhooks/billing/:provider` (adiado). Grava em `billing_events` com chave `(provider, event_id)` e só então atualiza `entitlements`; o mesmo evento duas vezes não faz nada.
Webhooks out: nenhum no MVP.

Jobs:
| name | schedule | what |
| --- | --- | --- |
| `ranking_snapshot` | segunda 03:00 UTC (domingo 23:59 em Brasília) | soma minutos, questões e dias seguidos da semana de quem aceitou, grava em `ranking_weekly` |
| `review_reminder` | diário, 09:00 de Brasília | e-mail com revisões de hoje e atrasadas, só para quem ativou |
| `edital_published_notify` | ao publicar | avisa quem pediu e quem votou |
| `edital_pdf_import` | sob demanda | lê o PDF, sugere matérias e tópicos, grava rascunho |
| `cleanup` | diário | remove PDFs de pedidos rejeitados e timers parados há mais de 7 dias |

Só APIs públicas e as suas próprias chaves. Nenhuma chamada a endpoints dos apps originais.

## Os cálculos que viram código

Escritos como funções puras, com testes, porque são o coração do produto e tinham fórmulas espalhadas nos relatórios:

1. **Distribuição do ciclo:** minutos por matéria proporcionais ao peso do edital, com teto de 1,5x a média (o excesso vai para as outras), base 1 sem peso, mínimo por sessão, divisão em blocos até o máximo, e matérias de menor peso saem se não couber. Arredondamento pelo maior resto para a soma fechar exatamente.
2. **Próxima revisão:** data realizada + intervalo da posição seguinte; depois do último intervalo, repete o último. Revisão por aulas: agenda ao concluir a aula N, revisando as anteriores.
3. **Baterias do PDF:** total de questões e questões por bateria geram `PDF i/n` e quais questões fazer (1, 7, 13... pulando n).
4. **Estatísticas de leitura:** págs/h = págs lidas / horas de PDF; horas restantes = págs restantes / págs/h; teto de 100%.
5. **Constância:** dia estudado = ao menos um registro com tempo ou questões; dias seguidos e recorde; denominador de "dias no ano" = desde o primeiro registro.
6. **Mínimo diário:** (meta de horas - horas desde a data de início) / dias até a véspera da prova.
7. **Meta semanal batida** a partir de 70%.

## The parts that bite

- **Fuso e início da semana:** guardar `timezone` e `week_start_day`; toda agregação por semana usa os dois. Horário de verão não existe mais no Brasil, mas o campo evita bug se mudar.
- **Idempotência:** webhooks de cobrança (quando existirem), duplo clique em "Fazer revisão" e reenvio de formulário. IDs gerados no cliente (`uuid`) para registros que podem ser reenviados.
- **Corridas:** duas abas com o cronômetro aberto. O estado vive em `timers` no servidor; a segunda aba só lê.
- **Offline e sincronização** (o Corte da Nota promete): fila local de registros com id gerado no cliente e a regra "última escrita vence". É o item mais caro do PWA; fica para a fase de acabamento.
- **Importar edital de PDF:** a extração por IA erra. Sempre entra como rascunho e só um admin publica. Guardar o PDF original e a URL de origem.
- **Conteúdo e licenças:** editais são públicos, mas o catálogo deles é curadoria. Monte o seu a partir dos documentos oficiais. Não copie o banco de questões nem os textos dos cursos.
- **Desempenho das estatísticas:** índices em `(user_id, studied_on)` já existem. Se um usuário tiver anos de registros, criar uma tabela de totais diários por usuário e matéria.
- **Ranking e privacidade:** só aparece quem aceitou (`ranking_opt_in`); mostrar nome de usuário e área, nunca o nome completo. A média geral deve usar só quem estudou na semana.
- **Dados pessoais:** não coletar CPF. Data de nascimento só se houver uso claro.
- **Rate limit e abuso:** limitar pedidos de edital por usuário (por exemplo 5 por semana) e tamanho do PDF (por exemplo 20 MB).
- **Acesso por assinatura:** o Exemplifica só libera as abas completas no 8º dia (garantia de 7). `entitlements.full_access_from` guarda isso se você quiser a mesma regra.

## Build order

1. **Fatia vertical (primeira semana).** Cadastro e login (S01 S02), Home mínima (S03), matérias (S10), registrar estudo com cronômetro (S04 S05) e histórico (S13). Tabelas: `profiles`, `subjects`, `study_sessions`, `timers`. Rotas: auth, `/me`, `/subjects`, `/timer`, `/sessions`. Prova a stack: criar conta, estudar, ver o total subir.
2. **Edital verticalizado (decisão sua: entra no MVP).** Catálogo e seguir edital (S15), checklist de tópicos, levar matérias ao planejamento, pedido de edital (S28) e painel admin com importador de PDF. Tabelas: `editais`, `edital_subjects`, `edital_topics`, `user_edital_follows`, `topic_checks`, `edital_requests`, `edital_request_votes`. Comece com 3 ou 4 editais publicados à mão (PRF, PF, INSS e Banco do Brasil) para testar o fluxo antes do importador.
3. **Planejamento.** Horas por matéria, metas, ciclo guiado pelo edital (S06 S07), plano passo a passo (S08), volta do ciclo, cronograma. Tabelas: `targets`, `study_plans`, `plan_slots`, `cycle_laps`.
4. **Revisões (S11).** Por tempo, por aulas, baterias do PDF, adiar, editar, próxima automática. Tabelas: `reviews`, `review_lessons`.
5. **Estatísticas e constância (S03 S14).** Todos os gráficos, leitura, aulas, tipos, termômetro e mapa de 6 meses. Visões `study_days` e `subject_reading`.
6. **Should-haves:** caderno de erros (S12), análise de confiança e falsos positivos e negativos, perfil, ajuda e bug, apagar dados.
7. **Could-haves:** ranking (S23), lei seca, flashcards, notas, radar de concursos, mentores, offline.
8. **Cobrança e afiliados:** checkout, `entitlements`, cupons por influenciador. Por decisão sua, depois do app pronto.
9. **Correções do `replica-entrepreneur`**, depois que ele rodar.

## Perguntas que mudam o schema

1. "Finalizar" do cronômetro descarta segundos ou arredonda? (Exemplifica descarta; recomendo arredondar para cima a partir de 30 s.)
2. Páginas lidas = fim - início + 1, ou só a página final?
3. A tela do ciclo gerado é editável (arrastar entre dias, mudar minutos)? Se sim, `plan_slots` precisa de histórico de mudanças.
4. Pedido de edital: o usuário vê quantas pessoas pediram o mesmo? (As tabelas já suportam.)
5. Quem é admin no começo: só você? Se houver equipe, é preciso um papel de "revisor de edital" separado.
