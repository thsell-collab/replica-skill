# Componentes (specs)

Base de acessibilidade: shadcn/ui sobre Radix. Ícones: Lucide (MIT). Fontes: Inter (texto) e Manrope (títulos e números), ambas abertas.
Regras para todos: foco visível com anel de 2 px na cor `accent`, alvo de toque mínimo de 44 px no celular, nunca só a cor para indicar estado (sempre ícone ou texto), e `prefers-reduced-motion` desliga as animações.

## Layout

```
AppShell
  desktop   sidebar 248 px (72 px recolhida) + conteúdo até 1200 px; cabeçalho 56 px
  celular   barra de abas embaixo (Início, Estudar, Plano, Revisões, Mais); sidebar vira gaveta
  estados   menu recolhido, gaveta aberta; com menu recolhido cada ícone mostra rótulo ao focar
  usado em  todas as telas
```

## Navegação e ação

```
Sidebar item
  estados   default, hover (surface-2), ativo (accent-soft + barra de 3 px accent), focus-visible, desabilitado
  a11y      <nav>, aria-current="page"

Botão
  variantes primário (accent), secundário (surface-2), fantasma, perigo
  tamanhos  sm 32, md 40, lg 48
  estados   default, hover, active, focus-visible, disabled, loading (mantém o rótulo para leitor de tela)

Botão de registrar estudo (flutuante)
  posição   canto inferior direito no desktop; no celular fica acima da barra de abas
  estados   default, hover, foco; abre S04
  a11y      <button> com rótulo "Registrar estudo", não só ícone

Abas / chips de período (hoje, semana, mês, total)
  estados   inativa, ativa (accent), foco, desabilitada
  a11y      role="tablist", setas do teclado trocam de aba
```

## Cronômetro (S05)

```
Cronômetro flutuante
  partes    ponto de estado, seletor de matéria, relógio, play/pausa, expandir, "Parar e registrar"
  estados   parado, rodando (ponto pulsa, desligado com reduced-motion), pausado
  regra     o tempo vive no servidor (tabela timers); recarregar a página não perde nada
  a11y      relógio com role="timer", sem anunciar a cada segundo (anuncia a cada minuto)

Modo foco
  tela cheia com matéria, relógio grande e botões Retomar/Parar e salvar; Esc minimiza; o tempo continua
```

## Formulários e pop-ups

```
Campo (texto, número, data, seleção, área de texto)
  estados   default, hover, focus (anel accent), preenchido, erro (borda danger + texto + ícone), desabilitado, somente leitura
  a11y      <label> visível, erro ligado por aria-describedby, obrigatório marcado em texto, não só com *

Seleção de matéria
  mostra a cor da matéria ao lado do nome; busca ao digitar acima de 8 itens

Campos por tipo de tarefa (S04)
  PDF          aula, página inicial, página final, "Continuar de onde parei"
  Videoaula    aula, nome da videoaula, "Parou em" (hh:mm:ss)
  Questões     aula, resolvidas, acertos, análise de confiança (recolhível)
  Resumo       aula, páginas
  Outros       só aula
  regra        trocar o tipo troca os campos na hora e conserva o que já foi digitado nos campos comuns

Pop-up (modal)
  tamanhos  sm 420, md 560, lg 720; no celular vira folha de baixo para cima
  estados   aberto, enviando, erro de validação (resumo no topo + campo marcado)
  a11y      foco preso dentro, Esc fecha, devolve o foco ao botão que abriu

Caixa de seleção e opção única
  alvo de 44 px com o texto clicável; estados marcado, indeterminado, foco, desabilitado
```

## Dados

```
Cartão de número (KPI)
  partes    rótulo, valor grande (Manrope 32), legenda
  variantes neutro, com meta (barra), com alerta (danger)
  estados   vazio ("0h00"), preenchido, carregando (esqueleto)

Barra de progresso
  partes    trilho surface-2, preenchimento accent, valor em texto
  variantes meta semanal (marca de 70%), leitura de PDF, edital por matéria
  a11y      role="progressbar" com valor

Gráficos (barras, linha, rosca, mapa de calor)
  cores     série 1 a 10 (tokens `series`), meta em linha tracejada; mapa de calor em 5 níveis do accent
  regra     toda série tem rótulo ou legenda em texto; tabela alternativa recolhível para leitor de tela
  estados   vazio ("Sem dados ainda" + ação), carregando, erro
  celular   rolagem horizontal só nos gráficos largos; rótulos reduzidos

Termômetro de disciplina (30 dias) e mapa de 6 meses
  cada dia é um botão focável com rótulo "12 de março: 2h10"; cor accent por faixa, nunca só a cor (o tooltip diz o valor)

Tabela
  recursos  ordenar, filtrar, editar na linha, rolagem horizontal no celular com a 1ª coluna fixa
  estados   vazio com mensagem e ação, carregando, erro
  celular   vira lista de cartões abaixo de 640 px

Cartão de revisão
  partes    matéria (com cor), aula, tipo, nº da revisão, data, etiqueta "atrasada" (danger + ícone)
  ações     Fazer, Adiar, Editar
```

## Edital

```
Cartão de edital (catálogo)
  partes    categoria, ano, órgão e cargo, banca, "Seguir este edital"
  estados   normal, seguido, indisponível

Árvore de tópicos
  matéria > tópico > subtópico, recolhíveis; caixa de marcar em cada tópico final
  mostra % marcado por matéria e total; atalho para "Levar matérias ao planejamento"
  a11y      role="tree", setas do teclado navegam

Pedido de edital
  campos    concurso, cargo, banca, ano, link ou PDF (até 20 MB)
  estados   enviado, em análise, publicado, recusado; botão "Eu também quero" com contagem
```

## Feedback e ajuda

```
Faixa de aviso (informação, sucesso, alerta, erro)
  ícone + texto; role="status" ou "alert"; fecha só quando for descartável

Toast
  confirma o que o app NÃO confirmou nos originais: salvar registro, adiar, fazer revisão (com "Desfazer" por 6 s)

Estado vazio
  ilustração própria simples, uma frase e a ação que resolve (ex.: "Escolher edital")

Esqueleto de carregamento
  mesmo formato do conteúdo; sem animação com reduced-motion

Pop-up de ajuda/bug
  campos: o que deu errado, descrição; a rota atual vai junto automaticamente
```
