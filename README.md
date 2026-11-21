# TocToc Aluguel: site no ar

Repositório público de conferência. Não guarda segredo. Os minutos do GitHub Actions em runner padrão (`ubuntu-24.04`) são gratuitos e ilimitados em repositório público. Se este repositório virar privado, o mesmo fluxo deixa de ser gratuito.

## O que é conferido

* https://toctocaluguel.com.br/health
* https://zedoaluguel.com.br/health (domínio antigo, que redireciona para o mesmo aplicativo)

Cada endereço tem 3 tentativas, com 5 s entre elas. Resposta esperada: HTTP 200 e o texto `Healthy`.

## Alarme, sem repetir aviso

Quando o mesmo endereço falha em 2 execuções seguidas, abre a issue **Site fora do ar**. Quando os dois endereços voltam a responder 200, a issue é fechada. O GitHub avisa o dono do repositório por e-mail e no aplicativo, de graça.

## Frequência real

O workflow `Site no ar` está com cron `*/5 * * * *`. No plano gratuito de repositório público o GitHub atrasa esse agendamento; as execuções recentes saíram a cada 6 a 8 horas, não a cada 5 minutos. Isso já acontecia antes desta atualização.

Não foi ligado um laço que fique 5 horas no ar e se reagende. Esse caminho usaria muitos minutos (ainda gratuitos neste repositório público), mas passaria a chamar o /health de produção dezenas de vezes por hora. Enquanto o `minReplicas` do Container App `zedoaluguel-web` não for lido no Azure, essa frequência fica desligada, para não impedir um eventual scale to zero nem criar custo novo. Detalhes em [docs/custo-e-limites.md](docs/custo-e-limites.md).

O workflow `Manter ativo` faz um commit no dia 1 de cada mês, porque o GitHub desliga workflows agendados de repositório público depois de 60 dias sem atividade.

## Como testar o alarme (sem afetar o de produção)

No GitHub: Actions > **Teste do alarme** > Run workflow. Ele aponta para um endereço inválido, abre a issue **Teste do monitor: simulação de queda** na 2ª falha e fecha essa issue quando o /health real responde 200. A issue de produção não é mexida.
