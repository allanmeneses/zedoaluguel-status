#!/usr/bin/env bash
# Confere os /health do TocToc Aluguel e abre ou fecha a issue de alarme
# só na mudança de estado. Duas falhas seguidas no mesmo endereço confirmam a queda.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-allanmeneses/zedoaluguel-status}"
PRINCIPAL="${URL_PRINCIPAL:-https://toctocaluguel.com.br/health}"
ANTIGO="${URL_ANTIGO:-https://zedoaluguel.com.br/health}"
MODO="${MODO:-producao}"
TITULO_PROD="Site fora do ar"
TITULO_TESTE="Teste do monitor: simulacao de queda"
LABEL_PROD="alerta-site"
LABEL_TESTE="alerta-teste"

if [[ "$MODO" == "teste" ]]; then
  TITULO="$TITULO_TESTE"
  LABEL="$LABEL_TESTE"
else
  TITULO="$TITULO_PROD"
  LABEL="$LABEL_PROD"
fi

conferir() {
  local url="$1"
  local code
  code=$(curl -s -o /tmp/health-body.txt -w '%{http_code}' --max-time 20 "$url" || true)
  echo "$url -> ${code:-sem resposta}"
  [[ "$code" == "200" ]]
}

tentar() {
  local url="$1"
  local i
  for i in 1 2 3; do
    if conferir "$url"; then return 0; fi
    if [[ "$i" -lt 3 ]]; then sleep 5; fi
  done
  return 1
}

garantir_label() {
  local nome="$1"
  local cor="$2"
  local desc="$3"
  gh label create "$nome" --repo "$REPO" --color "$cor" --description "$desc" 2>/dev/null || true
}

issue_aberta() {
  gh issue list --repo "$REPO" --label "$LABEL" --state open --json number,title \
    --jq ".[] | select(.title==\"$TITULO\") | .number" | head -1
}

numero_da_issue() {
  # gh issue create imprime a URL.
  local url="$1"
  echo "$url" | grep -oE '[0-9]+$' || true
}

abrir_alarme() {
  local corpo="$1"
  local n url
  n=$(issue_aberta)
  if [[ -n "$n" ]]; then
    echo "Alarme já aberto: #$n"
    gh issue comment --repo "$REPO" "$n" --body "$corpo" >/dev/null
    echo "$n"
    return
  fi
  garantir_label "$LABEL" "B60205" "O site nao respondeu 200 no /health"
  url=$(gh issue create --repo "$REPO" --title "$TITULO" --label "$LABEL" --body "$corpo")
  n=$(numero_da_issue "$url")
  echo "Alarme aberto: $url"
  echo "$n"
}

fechar_alarme() {
  local corpo="$1"
  local n
  n=$(issue_aberta)
  if [[ -z "$n" ]]; then
    echo "Nenhum alarme aberto."
    return
  fi
  gh issue comment --repo "$REPO" "$n" --body "$corpo" >/dev/null
  gh issue close --repo "$REPO" "$n" --reason completed --comment "O site voltou a responder. Alarme encerrado."
  echo "Alarme fechado: #$n"
}

agora_br() {
  TZ=America/Sao_Paulo date '+%d/%m/%Y %H:%M:%S (Brasilia)'
}

resumo_falha() {
  local url="$1"
  cat <<TXT
O endereco $url nao respondeu 200 em 3 tentativas.

Quando: $(agora_br)
Confirmacao: 2 conferencias seguidas falharam neste endereco.
O que olhar: Container App zedoaluguel-web no grupo rg-parking, revisao ativa e GET /health.

Esta issue abre so na queda e fecha sozinha na volta, para nao repetir aviso.
TXT
}

resumo_volta() {
  local url="$1"
  cat <<TXT
Volta confirmada em $url.

Quando: $(agora_br)
HTTP 200 no /health.
TXT
}

if [[ "$MODO" == "teste" ]]; then
  leftover=$(issue_aberta || true)
  if [[ -n "$leftover" ]]; then
    echo "Encerrando alarme de teste leftover #$leftover de uma execucao anterior."
    gh issue close --repo "$REPO" "$leftover" --reason completed --comment "Encerrado para comecar um novo teste do alarme." >/dev/null
    sleep 2
  fi
  echo "== 1) Primeira falha (URL invalida, ainda sem alarme) =="
  URL_FALHA="${URL_TESTE_FALHA:-https://toctocaluguel.com.br/nao-existe}"
  if tentar "$URL_FALHA"; then
    echo "::error::$URL_FALHA respondeu 200; o teste precisa de um endereco que falhe."
    exit 1
  fi
  if [[ -n "$(issue_aberta)" ]]; then
    echo "::error::Havia alarme aberto antes da 2a falha."
    exit 1
  fi
  echo "Primeira falha registrada, sem abrir alarme."

  echo "== 2) Segunda falha seguida (abre o alarme de teste) =="
  if tentar "$URL_FALHA"; then
    echo "::error::$URL_FALHA respondeu 200 na 2a tentativa."
    exit 1
  fi
  criar_saida=$(abrir_alarme "$(resumo_falha "$URL_FALHA")")
  echo "$criar_saida"
  n=$(issue_aberta)
  if [[ -z "$n" ]]; then
    # A lista de issues pode atrasar um pouco logo apos criar.
    sleep 3
    n=$(issue_aberta)
  fi
  if [[ -z "$n" ]]; then
    n=$(echo "$criar_saida" | grep -oE 'issues/[0-9]+' | tail -1 | grep -oE '[0-9]+' || true)
  fi
  if [[ -z "$n" ]]; then
    echo "::error::O alarme de teste nao abriu na 2a falha."
    exit 1
  fi
  echo "ISSUE_TESTE=#$n"
  echo "Alarme de teste aberto: https://github.com/${REPO}/issues/${n}"

  echo "== 3) Volta (enderecos reais no ar) =="
  if ! tentar "$PRINCIPAL"; then
    echo "::error::$PRINCIPAL nao respondeu 200 na volta do teste. O alarme de teste pode ter ficado aberto."
    exit 1
  fi
  if ! tentar "$ANTIGO"; then
    echo "::warning::$ANTIGO nao respondeu 200. O principal esta no ar; mesmo assim encerro o teste."
  fi
  fechar_alarme "$(resumo_volta "$PRINCIPAL")"
  sleep 2
  n=$(issue_aberta)
  if [[ -n "$n" ]]; then
    echo "::error::O alarme de teste #$n nao fechou na volta."
    exit 1
  fi
  echo "Teste ok: o alarme abriu na 2a falha e fechou na volta."
  exit 0
fi

# Producao: duas falhas seguidas exigem que a ultima execucao agendada tambem tenha falhado.
ultima_falhou=0
wf="${GITHUB_WORKFLOW:-Site no ar}"
last=$(gh run list --repo "$REPO" --workflow "$wf" --event schedule --status completed --limit 5 \
  --json conclusion,databaseId,createdAt --jq '.[] | "\(.createdAt) \(.conclusion) \(.databaseId)"' 2>/dev/null || true)
# Ignora a execucao atual, se ja aparecer na lista.
current="${GITHUB_RUN_ID:-}"
prev=""
while read -r line; do
  [[ -z "$line" ]] && continue
  id="${line##* }"
  [[ "$id" == "$current" ]] && continue
  prev="$line"
  break
done <<< "$last"
if [[ -n "$prev" ]]; then
  echo "Ultima execucao agendada anterior: $prev"
  conc=$(echo "$prev" | awk '{print $2}')
  if [[ "$conc" == "failure" || "$conc" == "timed_out" ]]; then
    ultima_falhou=1
  fi
else
  echo "Sem execucao agendada anterior."
fi

ok_p=1
ok_a=1
tentar "$PRINCIPAL" || ok_p=0
tentar "$ANTIGO" || ok_a=0

if [[ "$ok_p" -eq 1 && "$ok_a" -eq 1 ]]; then
  fechar_alarme "$(resumo_volta "$PRINCIPAL")"
  echo "Os dois enderecos responderam 200."
  exit 0
fi

falhou=""
[[ "$ok_p" -eq 0 ]] && falhou="$PRINCIPAL"
[[ "$ok_a" -eq 0 ]] && falhou="${falhou:+$falhou e }$ANTIGO"

if [[ "$ultima_falhou" -eq 1 ]]; then
  abrir_alarme "$(resumo_falha "$falhou")" >/dev/null
  echo "::error::$falhou nao respondeu 200 (2a conferencia seguida)."
  exit 1
fi

echo "::error::$falhou nao respondeu 200 (1a falha; o alarme so abre na proxima se continuar fora)."
exit 1
