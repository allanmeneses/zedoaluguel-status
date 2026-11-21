# TocToc Aluguel: site no ar

Repositório público de conferência. Não guarda segredo. Os minutos do GitHub Actions em runner padrão (`ubuntu-24.04`) são gratuitos e ilimitados em repositório público. Se este repositório virar privado, o mesmo fluxo deixa de ser gratuito.

## O que é conferido

* https://toctocaluguel.com.br/health
* https://zedoaluguel.com.br/health (domínio antigo, que redireciona para o mesmo aplicativo)

Cada endereço tem 3 tentativas, com 5 s entre elas. Resposta esperada: HTTP 200 e o texto `Healthy`.

## Alarme, sem repetir aviso

Quando o mesmo endereço falha em 2 conferências seguidas, abre a issue **Site fora do ar**. Quando os dois endereços voltam a responder 200, a issue é fechada. O GitHub avisa o dono do repositório por e-mail e no aplicativo, de graça.

## Frequência

O workflow `Site no ar` permanece com cron `*/5 * * * *`. Em repositório público o GitHub costuma atrasar esse agendamento (antes desta atualização, as execuções saíam a cada 6 a 8 horas). Para cobrir o atraso, cada execução entra num laço: confere os /health a cada 5 minutos por quase 6 horas (teto do runner hospedado). Só um laço roda de cada vez; o próximo agendamento espera o atual terminar e começa em seguida.

O `minReplicas` do Container App `zedoaluguel-web` foi lido em 21/11/2026, 18:50 (horário de Brasília): valor 1 (e `maxReplicas` 1). O aplicativo já fica ligado. A conferência a cada 5 minutos não acorda réplica nova e não cria custo adicional no Azure. Os minutos do Actions continuam gratuitos enquanto este repositório for público. Detalhes em [docs/custo-e-limites.md](docs/custo-e-limites.md).

O workflow `Manter ativo` faz um commit no dia 1 de cada mês, porque o GitHub desliga workflows agendados de repositório público depois de 60 dias sem atividade.

## Como testar o alarme (sem afetar o de produção)

No GitHub: Actions > **Teste do alarme** > Run workflow. Ele aponta para um endereço inválido, abre a issue **Teste do monitor: simulação de queda** na 2ª falha e fecha essa issue quando o /health real responde 200. A issue de produção não é mexida.
