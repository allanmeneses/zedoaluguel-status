# Custo e limites do monitor

Atualizado em 21/11/2026 (Brasília). Nenhuma checagem extra a cada 5 minutos foi ligada.

## GitHub Actions

* Repositório: [allanmeneses/zedoaluguel-status](https://github.com/allanmeneses/zedoaluguel-status), **público**.
* Runner: `ubuntu-24.04`, runner padrão hospedado pelo GitHub.
* Segundo a documentacao do GitHub (2026): o uso de runners padrao em repositório público é gratuito e ilimitado. A cota de 2.000 minutos por mes do GitHub Free vale para repositório **privado**.
* Consumo atual (agendamento atrasado, cerca de 3 a 4 execuções por dia, uns 15 segundos cada): cerca de 2 minutos por mes. Gratuito.
* Se alguem ligasse um laço de 5 horas, duas vezes ao dia, para cobrir 24 horas: cerca de 10 horas por dia, 18.000 minutos por mes. Neste repositório público, isso ainda seria gratuito. No mesmo repositório se viesse a ser privado, estouraria a cota (2.000 minutos no GitHub Free) e passaria a ter custo (cerca de 16.000 minutos extras, na ordem de USD 100 por mes no preço de Linux de 2026). Por isso este repositório precisa continuar público, e o laço não foi ligado.

## Azure (Container App zedoaluguel-web, Brazil South)

Plano de consumo do Azure Container Apps, preços públicos de 21/11/2026 na região Brazil South:

* vCPU ativo: USD 0,000024 por segundo
* vCPU ocioso: USD 0,000003 por segundo
* Memória (ativa ou ociosa): USD 0,000003 por GiB-segundo
* Requisições: USD 0,40 por milhão, depois da faixa gratuita
* Faixa gratuita por assinatura e por mês: 180.000 vCPU-segundos, 360.000 GiB-segundos e 2 milhoes de requisições

Uma conferência nos dois /health, a cada 5 minutos, daria cerca de 17.280 requisições por mes, bem abaixo dos 2 milhoes gratuitos. Cada resposta tem 7 bytes (`Healthy`). O egresso é desprezível.

O ponto que pode gerar custo novo é o **minReplicas**:

* Se `minReplicas` já é 1 ou mais, o aplicativo já fica ligado o tempo todo. A conferencia a cada 5 minutos não acorda réplica nova e não muda a conta de computação de forma mensuravel.
* Se `minReplicas` é 0, o aplicativo pode ir a zero e, nesse caso, a conferência a cada 5 minutos impede o scale to zero. Com uma alocação típica de 0,25 vCPU e 0,5 GiB, o custo ocioso em Brazil South ficaria em torno de USD 4 a 5 por mes, depois da faixa gratuita. Com 0,5 vCPU e 1 GiB, em torno de USD 10 por mes. Isso só é custo **adicional** se hoje o aplicativo passa boa parte do tempo em zero.

O `minReplicas` atual **não foi lido no Azure** (não há `az` nem credencial da assinatura neste computador; o deploy no GitHub só atualiza a imagem e não imprime a escala). Evidência indireta: as 12 execuções recentes do vigia, inclusive de madrugada (01:03, 02:37, 04:21 em UTC, madrugada em Brasília), terminaram em 7 a 12 segundos no total, o que combina com aplicativo já quente, não com um cold start longo de .NET. Isso não substitui a leitura do `minReplicas`.

Por isso o laço de 5 minutos **não foi ligado**. Quando alguém rodar, com permissão de leitura:

```
az containerapp show -g rg-parking -n zedoaluguel-web --query "properties.template.scale.{min:minReplicas,max:maxReplicas}" -o json
az containerapp show -g rg-parking -n zedoaluguel-web --query "properties.template.containers[0].resources" -o json
```

Se `minReplicas` for 1 ou mais, o laço pode ser ligado sem custo adicional relevante no Azure e ainda gratuito no GitHub, desde que o repositório continue público.
