# Custo e limites do monitor

Atualizado em 21/11/2026, 18:50 (horário de Brasília). O laço de 5 minutos foi ligado depois da leitura de `minReplicas=1`.

## GitHub Actions

* Repositório: [allanmeneses/zedoaluguel-status](https://github.com/allanmeneses/zedoaluguel-status), **público**.
* Runner: `ubuntu-24.04`, runner padrão hospedado pelo GitHub.
* Segundo a documentacao do GitHub (2026): o uso de runners padrao em repositório público é gratuito e ilimitado. A cota de 2.000 minutos por mes do GitHub Free vale para repositório **privado**.
* Com o laço de quase 6 horas, o consumo fica na ordem de 10 horas por dia, cerca de 18.000 minutos por mes. Neste repositório público, isso é gratuito. Se o repositório viesse a ser privado, estouraria a cota (2.000 minutos no GitHub Free) e passaria a ter custo (cerca de 16.000 minutos extras, na ordem de USD 100 por mes no preço de Linux de 2026). Por isso este repositório precisa continuar público.

## Azure (Container App zedoaluguel-web, Brazil South)

Plano de consumo do Azure Container Apps, preços públicos de 21/11/2026 na região Brazil South:

* vCPU ativo: USD 0,000024 por segundo
* vCPU ocioso: USD 0,000003 por segundo
* Memória (ativa ou ociosa): USD 0,000003 por GiB-segundo
* Requisições: USD 0,40 por milhão, depois da faixa gratuita
* Faixa gratuita por assinatura e por mês: 180.000 vCPU-segundos, 360.000 GiB-segundos e 2 milhoes de requisições

Uma conferência nos dois /health, a cada 5 minutos, dá cerca de 17.280 requisições por mes, bem abaixo dos 2 milhoes gratuitos. Cada resposta tem 7 bytes (`Healthy`). O egresso é desprezível.

Leitura do `minReplicas` em 21/11/2026, 18:50 (horário de Brasília), via o fluxo `operacao.yml` do repositório do produto (OIDC, ação `conferir`):

* `minReplicas=1`
* `maxReplicas=1`

O aplicativo já fica ligado o tempo todo. A conferência a cada 5 minutos não acorda réplica nova e não muda a conta de computação de forma mensuravel. Não há custo adicional no Azure por ligar o laço.

Se no futuro o `minReplicas` voltar a 0, a conferência a cada 5 minutos impediria o scale to zero. Com uma alocação típica de 0,25 vCPU e 0,5 GiB, o custo ocioso em Brazil South ficaria em torno de USD 4 a 5 por mes, depois da faixa gratuita. Com 0,5 vCPU e 1 GiB, em torno de USD 10 por mes. Isso só seria custo adicional se o aplicativo passasse boa parte do tempo em zero.
