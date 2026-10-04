# Zé do Aluguel: site no ar

O workflow `Site no ar` confere `https://zedoaluguel.com.br/health` a cada 5 minutos. Se o site não responder 200 em
3 tentativas (30 s entre elas), a execução falha e o GitHub avisa por e-mail.

O repositório é público porque, assim, os minutos do GitHub Actions são gratuitos. Não há segredo aqui: o endereço
conferido é público. O workflow `Manter ativo` faz um commit por mês, porque o GitHub desliga workflows agendados
de repositório público depois de 60 dias sem atividade.

Para testar o alarme: Actions > Site no ar > Run workflow, com um endereço que falha (ex.: `https://zedoaluguel.com.br/nao-existe`).
