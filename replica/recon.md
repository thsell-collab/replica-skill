# Recon map: Exemplifica Concursos + Corte da Nota (web, PWA)

Scope: o laço de estudo dos dois apps unidos num só produto: registrar estudo, planejar (ciclo/cronograma), revisar (espaçada + caderno de erros), estatísticas, edital verticalizado, questões e lei seca.
For: produto próprio para vender a concurseiros, divulgado por influenciadores do Instagram. Nome, marca e textos próprios.
Date: 2026-10-31

Legenda de origem: [EX] Exemplifica Concursos, [CN] Corte da Nota. Confiança: alta = visto na tela, média = deduzido e conferido com números, baixa = só descrito ou inferido.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | documentação de navegação do Exemplifica (feita na conta do usuário, com registros de teste) | app.exemplificaconcursos.com.br | estados com dados, fórmulas conferidas, sem prints entregues |
| 2 | documentação de navegação do Corte da Nota (conta vazia, nada salvo) | app.cortedanota.com.br | muitos estados só "vazio", FAQ com 23 respostas (11 abertas) |
| 3 | 32 prints + 4 transcrições de áudio do curso (Exemplifica) | pasta Referência 01 | prints com conta vazia; áudios explicam as regras do método |
| 4 | página de vendas do Corte da Nota (PDF) | cortedanota.com.br | preços e promessa de marketing |

Não tenho prints do Corte da Nota nem do celular dos dois. Versão responsiva: NÃO OBSERVADA.

## Core loop

O aluno escolhe o concurso, recebe um ciclo de estudo pronto, estuda com cronômetro, registra tempo e questões, e o app mostra onde a nota escapa e agenda as revisões certas.

```
edital/matérias -> ciclo -> estudar (cronômetro) -> registrar (tempo, questões, confiança)
      -> revisões agendadas + caderno de erros -> estatísticas e constância -> ajusta o ciclo
```

## Screens

| ID | screen | route / how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Login / primeiro acesso / recuperar senha | `/login` [EX] | entrar | e-mail, senha, 3 botões | só login visto |
| S02 | Boas-vindas (1º acesso) | pop-up após criar conta [EX] | coletar nome de usuário, área, meta semanal | 3 campos | visto |
| S03 | Home / Visão geral | `/` [EX+CN] | painel do dia | saudação, alvo, resumo de horas e questões, revisões pendentes, mapa de constância, metas, "estudado hoje" | vazio e preenchido |
| S04 | Registrar estudo (pop-up) | botão flutuante [EX], "registrar manual" [CN] | lançar sessão | data, matéria, tarefa, aula, páginas, cronômetro, tempo, questões, confiança, comentário, aula concluída | vazio; salvo (EX) |
| S05 | Cronômetro flutuante + modo foco | rodapé [CN] | medir tempo | matéria, relógio, play, parar e registrar, tela de foco | pausado |
| S06 | Planejamento | `/planejamento` [EX+CN] | horas por matéria, metas, ciclo, cronograma | tabela de horas, gerador, metas | vazio |
| S07 | Assistente "ciclo em 30 segundos" | de S06 [CN] | ciclo em 3 respostas | busca de concurso, horas, duração da sessão | visto |
| S08 | Assistente "montar planejamento" (5 passos) | de S06 [CN] | ciclo ou semana organizada com controle total | formato, matérias, rotina, período, conferir | visto |
| S09 | Ciclo / cronograma gerado | S06 [EX] | executar a semana | blocos por matéria, marcar, arrastar entre dias | só descrito em áudio |
| S10 | Matérias e carreira | `/planejamento?aba=materias` [CN] + Configurações [EX] | cadastrar matérias | sugestões por carreira, nova disciplina, lista de aulas | visto |
| S11 | Revisões | `/revisoes` [EX] | revisão por tempo e por aulas | A fazer / Futuras / Feitas, Fazer, Adiar, Editar | com 80 revisões |
| S12 | Caderno de erros | `/caderno` [CN] | guardar questões erradas | cartões de número, calendário, motivo do erro, abas, nova questão | vazio |
| S13 | Histórico | `/historico` [EX] | listar e editar registros | filtros, tabela, editar/remover | preenchido |
| S14 | Estatísticas | `/estatisticas` [EX+CN] | análise | evolução, por matéria, por aula, por tipo, precisão, confiança x resultado | EX preenchido, CN vazio |
| S15 | Edital verticalizado | `/edital` [CN] | seguir edital e marcar tópicos | catálogo de 105 editais, checklist | só catálogo |
| S16 | Banco de questões | `/questoes` [CN] | resolver questões | filtros, cartão de questão, certeza/dúvida, gabarito | sem respostas |
| S17 | Lei seca (lista e leitor) | `/lei-seca` [CN] | ler e treinar lacunas | abas Ler/Lacunas/Desafio, índice, revisão de hoje | visto, sem interação |
| S18 | Leis mapeadas | `/leis-mapeadas` [CN] | onde cada artigo caiu | mapa de calor por artigo, lista de provas | visto |
| S19 | Flashcards | `/flashcards` [CN] | cartões por lei | bloqueado no plano pago | bloqueado |
| S20 | Provas e concursos | `/provas` [CN] | radar de concursos e alvos | cartões com situação e contagem regressiva | visto |
| S21 | Notas | `/notas` [CN] | anotações com #tags | busca, filtros | vazio |
| S22 | Materiais (biblioteca) | `/biblioteca` [CN] | PDFs e cursos | cartões Pro/grátis | visto |
| S23 | Ranking | `/ranking` [EX] | comparar com outros | Top 10 de horas, constância, questões | preenchido |
| S24 | Mentores | `/mentores` [CN] | painel de acompanhamento de alunos | só tela de convite | só convite |
| S25 | Perfil | `/perfil` [EX] | foto, usuário, área, dados | 2 cartões | visto |
| S26 | Configurações | `/configuracoes` [EX] | preferências e intervalos | semana, meta, bloco, intervalos de revisão, tema, apagar dados, importar | visto |
| S27 | Ajuda / FAQ / Tutoriais / Reportar bug | `/ajuda` [CN], `/tutoriais` [EX] | suporte | busca, acordeão, pop-up de bug | visto |
| S28 | Pedido de edital (novo, ideia sua) | a definir | usuário pede edital que não existe | formulário, status do pedido | não existe nos originais |

## Flows

```
F01 Primeiro acesso
    S01 -> criar conta -> S02 (nome, área, meta) -> S03
    happy path clicks: 6   edge: e-mail não pago (futuro checkout), link expira em 7 dias [EX]

F02 Montar o plano a partir do edital  [CN]
    S15 seguir edital -> S06 "montar meu ciclo" -> S07 (concurso, horas, sessão) -> S09 ciclo pronto
    happy path clicks: 8   edge: edital fora do catálogo -> S28; poucas horas -> matérias de menor peso ficam de fora

F03 Montar o plano sem edital
    S10 (carreira ou disciplina avulsa) -> S06 horas por matéria -> ciclo ou cronograma [EX]
    edge: soma dos dias diferente da meta semanal -> não gera cronograma [EX]

F04 Estudar e registrar
    S05 play -> estudar -> parar e registrar -> S04 pré-preenchido -> salvar -> S03 atualizado
    happy path clicks: 5   edge: esqueceu de marcar -> lançamento manual; segundos descartados no "Finalizar" [EX, média]

F05 Concluir aula e agendar revisões  [EX]
    S04 "aula concluída" (+ tipo da próxima revisão ou divisão em baterias do PDF) -> S11 revisão futura
    edge: matéria "por aulas" só agenda ao chegar na aula N; "nenhuma" não agenda

F06 Fazer revisão  [EX]
    S11 Fazer -> registro pré-preenchido (questões e acertos) -> salvar -> vai para "feitas" + agenda a próxima (data feita + intervalo)
    edge: Adiar por N dias (soma à data agendada, não a hoje)

F07 Responder questão e alimentar o caderno  [CN]
    S16 resposta + certeza/dúvida -> responder -> erro ou acerto na dúvida vai a S12 com revisão em 7/15/30 dias
    edge: falso positivo (certeza errada) e falso negativo (dúvida certa) entram em S14

F08 Ler lei seca com lacunas  [CN]
    S17 Ler -> Lacunas (lembrei/errei) -> erradas voltam em "Revisar hoje" -> Desafio (digitar)

F09 Ver a semana e a constância
    S03 / S14: horas por dia, termômetro de 30 dias, mapa de 6 meses, recorde de dias seguidos

F10 Pedir edital que não existe  (novo)
    S15 não achou -> S28 pedido (concurso, banca, ano, link ou PDF) -> fila admin -> importar do PDF -> publicar -> aviso ao usuário
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| Menu lateral recolhível | claro, escuro; item ativo com barra | normal, recolhido | todas |
| Botão flutuante "Registrar estudo" | laranja | normal | todas [EX] |
| Cronômetro | rodapé, modo foco em tela cheia | parado, rodando, pausado | todas [CN] |
| Pop-up de formulário | registrar, editar, adiar, nova matéria, novo alvo, esqueceu de marcar | aberto, erro de validação (não visto) | S04 S06 S11 S12 S13 S20 |
| Cartão de número (KPI) | horas, precisão, semana, revisões | vazio, preenchido | S03 S12 S14 |
| Gráfico de barras e linha | semanal/mensal, horas/questões, meta tracejada | vazio, preenchido | S03 S14 |
| Pizza / rosca | horas por matéria, acertos x erros | vazio, preenchido | S03 S14 |
| Mapa de calor | 30 dias, 6 meses, artigos de lei | vazio, preenchido | S03 S14 S18 |
| Tabela com filtros e edição por linha | histórico, revisões, estatísticas | vazio, preenchido | S11 S13 S14 |
| Seletor de abas / chips | hoje/semana/mês/total, categorias | ativo | S03 S14 S15 S16 S17 S23 |
| Assistente em passos | 3 perguntas, 5 passos | em andamento | S07 S08 |
| Acordeão | revisões, FAQ, análise de confiança | aberto/fechado | S11 S27 S04 |
| Cartão de concurso/edital | situação, banca, vagas, contagem | normal, bloqueado (Pro) | S15 S20 S22 |
| Cartão de questão | certo/errado, múltipla escolha, confiança, gabarito recolhível | respondida (não vista) | S16 |
| Leitor de lei | ler, lacunas, desafio | normal | S17 |
| Aviso (faixa colorida) | informação, alerta, erro | visível | todas |
| Tema claro/escuro | | | todas |

## Inferred data model

```
User            id, email, nome completo, nascimento, cpf?, username, área (fiscal/controle/policial/
                tribunais/administrativa/bancária/outra), foto, tema, fuso (Brasília)
                evidence: S01 S02 S25  confidence: alta
Preferences     week_start_day, weekly_hours_goal, weekly_questions_goal, block_minutes (30/60/90/120),
                session_min, session_max, review_intervals[] (padrão 7,15,30,30,60...)
                evidence: S26 S06 S08  confidence: alta
Target          cargo/concurso, exam_date, hours_goal, count_from_date
                evidence: S03 S20  confidence: alta
Subject         name, parent_id (submatéria), pages_total?, review_mode (time|lessons|none),
                review_every_n_lessons?, lesson_names[], active, in_cycle, cycle_minutes, color, status
                evidence: S10 S06 S26  confidence: alta (status: baixa)
Edital          org, cargo, year, banca, category + EditalSubject(weight = nº de questões) + Topic
                UserEditalFollow, TopicCheck (checklist manual)
                evidence: S15 S08 FAQ  confidence: média (estrutura do tópico não vista)
StudySession    date, subject_id?, task (pdf|video|questions|law|flashcards|summary|other|theory|review|mock),
                lesson, page_start, page_end, video_name?, stopped_at?, minutes, questions_done,
                correct, confident_done/correct, doubt_done/correct, topic?, comment, lesson_completed
                evidence: S04 S13  confidence: alta
Review          subject_id, lesson, kind (time|lessons), number, scheduled_date, done_date?, type_label,
                battery (n/total), questions_total, done_questions, correct, wrong, status
                evidence: S11 S12  confidence: alta
ErrorNotebook   subject, topic, banca, source, exam, solved_on, statement, alternatives, my_answer,
                key, reason (não sabia|confundi|atenção|chutei|acertei na dúvida), note, highlights[],
                intervals "7,15,30", next_review
                evidence: S12  confidence: alta
Question        banca, exam, year, cargo, subject, topic, type (CE|ME), statement, key, law refs
Answer          user, question, answer, confidence, correct, answered_at (vale a última por questão)
                evidence: S16  confidence: alta (modelo de dados da banca: baixa)
Law / Article / LawGapProgress   text, article numbers, "caiu em N questões", gaps remembered/missed, next review
                evidence: S17 S18  confidence: média
CycleLap        started_on, slots[subject, minutes, done_minutes]  | WeeklyPlan  day -> blocks
                evidence: S06 S07 S08 FAQ  confidence: média (tela do ciclo gerado não vista)
Note            title, body, #tags, created_at   evidence: S21  confidence: baixa
EditalRequest   user, concurso, banca, year, link/pdf, status, votes  (novo)
RankingEntry    derivado: horas líquidas e questões da semana, dias seguidos; opt-in
```

Relationships: User 1-n Subject, StudySession, Review, ErrorNotebook, Answer, Note, Target. Subject 1-n Subject (submatérias) e 1-n StudySession. Edital 1-n EditalSubject n-1 Subject. StudySession (aula concluída) 1-n Review. Review feita gera a próxima Review.

## Cálculos conferidos [EX, média/alta] e declarados [CN, alta]

- Progresso de leitura = págs lidas / págs totais, teto 100%; págs/h = págs lidas / horas de PDF; horas restantes = págs restantes / págs/h.
- Média por dia estudado = horas do ano / dias estudados; média por todos os dias = horas do ano / dias desde o primeiro registro (não 365).
- Próxima revisão = data realizada + intervalo da linha seguinte; depois da última linha, repete o último intervalo. Revisão estimada em 30 min cada.
- Erros = resolvidas - acertos; precisão = acertos / resolvidas.
- Meta semanal conta como batida a partir de 70% [CN]. Mínimo diário = (meta de horas - horas desde a data) / dias até a véspera da prova [CN].
- Tempo do ciclo distribuído pelo peso do edital (nº de questões), teto 1,5x a média; sem peso, base 1; nenhuma matéria abaixo do mínimo da sessão; sobra fica com as de maior peso [CN].
- Ponto fraco = tópico com menor acerto entre os que têm 5 ou mais questões [CN].
- Falso positivo = certeza que estava errada; falso negativo = dúvida que estava certa [CN].
- Aula concluída: revisão por aulas agenda ao chegar na aula N, revisando as aulas anteriores exceto a atual [EX, áudio].

## Decisões ao unir os dois

| tema | Exemplifica | Corte da Nota | proposta para o clone |
| --- | --- | --- | --- |
| Planejamento | horas por matéria + ciclo ou cronograma | assistente em 30 s guiado pelo edital + semana organizada | assistente guiado (CN) gerando ciclo ou semana (EX); horas por matéria editáveis |
| Revisão | por tempo e por aulas, com baterias do PDF | caderno de erros 7/15/30 | manter as duas: revisões espaçadas por aula/tempo e caderno de erros |
| Questões | só registra acertos e erros | banco com 14.896 questões + confiança | registro manual no MVP; banco só com conteúdo próprio ou importado pelo usuário |
| Constância | termômetro de 30 dias, recorde | mapa de 6 meses, dias seguidos | os dois; mesmo cálculo de dia estudado |
| Semana | início configurável | segunda a domingo | configurável, padrão segunda |
| Social | ranking Top 10 | mentores | ranking e mentores ficam para quando houver base de usuários |

## Feature matrix

See `features.csv`. A coluna `notes` traz a origem ([EX], [CN]) e o motivo da prioridade.

## Out of scope (cannot or should not be cloned)

- Banco de 14.896 questões oficiais, 616 provas e a classificação por assunto: conteúdo de terceiros e curado. Fica fora do MVP. Alternativa: o usuário registra suas questões, ou você monta um acervo com licença.
- Leis mapeadas (mapa de incidência por artigo): depende do banco de questões.
- Catálogo de 105 editais e o radar de concursos (curadoria do Corte da Nota): conteúdo de terceiros. Você monta o seu a partir dos editais públicos.
- Texto das leis: vem da Câmara (público), mas o recorte, os termos escondidos e as marcações "caiu em N questões" são curadoria deles.
- Cursos em PDF, resumos e legislação em PDF do plano Pro; vídeos tutoriais do curso.
- Ranking com usuários reais e a base de mentores/alunos.
- Importação da planilha do Guia (formato proprietário do curso).
- Marca, mascote (busto com venda), textos, frases motivacionais, cores e nomes ("Guia", "Pro", "Arsenal", "Exemplifica").

## Size

Screens 28, flows 10, entities cerca de 20.
Hard parts: (1) motor de planejamento (ciclo por pesos com mínimo e máximo de sessão, semana organizada, volta do ciclo), (2) motor de revisões (intervalos configuráveis, baterias do PDF, adiar, próxima automática), (3) conteúdo: editais, questões e lei seca, (4) sincronização offline do PWA com fuso de Brasília, (5) ranking e privacidade. Pagamento e acesso por assinatura ficam para depois, como combinado.
Size: MVP (registro, cronômetro, ciclo, revisões, estatísticas, constância) = M. Produto completo com edital, questões e lei seca = L; o conteúdo pesa mais que o código.

## Perguntas em aberto

1. Tela do ciclo e do cronograma gerados, e se os blocos são editáveis (só descrição em áudio).
2. Telas do edital seguido, do ciclo ativo, do painel do mentor e do caderno com dados.
3. Fórmula de "horas líquidas" do ranking, de "acerto nas revisões" e de "% dominado".
4. Versão celular dos dois apps.
5. Tooltips (ⓘ) e o asterisco de "Média por dia estudado*" do Exemplifica.
6. Se os campos do registro mudam por tipo de estudo no Corte da Nota.
7. Validações e mensagens de erro, e telas de login, cadastro e recuperação de senha do Corte da Nota.
