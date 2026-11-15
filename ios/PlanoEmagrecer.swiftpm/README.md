# Plano Emagrecer (iOS)

App em SwiftUI (iOS 17+) feita a partir da folha "Plano para emagrecer — ementa e registo".

## O que tem

| Separador | O quê |
|---|---|
| **Hoje** | Ementa do dia com as 5 refeições para marcar, as 4 regras que dão pontos (ementa, doces, caminhada, cerveja), peso, notas, resumo da semana (pontos /28, meta 22, cervejas /4). Setas para registar dias anteriores. |
| **Progresso** | Peso inicial / atual / meta, kg perdidos e em falta, gráfico do peso, ritmo semanal e data prevista para a meta, gráfico de pontos das últimas 8 semanas, sequência de dias 4/4, histórico editável. |
| **Ementa** | Os 7 dias da semana, com o dia de hoje destacado. |
| **Compras** | Os 34 produtos, para marcar; adicionar e apagar produtos, desmarcar tudo para a semana seguinte, partilhar o que falta comprar. |
| **Mais** | As 11 regras, objetivos editáveis, lembretes (registo à noite, pesagem à segunda, caminhada, preparação ao domingo), exportar CSV. |

Pontos por dia (igual à folha): cumpri a ementa + doces só os planeados + caminhei 30 min + cerveja dentro da regra (0 cervejas, ou até 2 à quarta, sábado ou domingo).

Os dados ficam só no telemóvel (ficheiro `plano.json` na pasta Documentos da app).

## Como instalar

**Num Mac (para pôr no iPhone):**
1. Instalar o Xcode (App Store).
2. Fazer duplo clique em `PlanoEmagrecer.swiftpm`: abre no Xcode.
3. Ligar o iPhone por cabo e escolhê-lo como destino lá em cima.
4. Em *Signing*, escolher a tua conta Apple (a conta gratuita dá).
5. Carregar ▶︎. No iPhone: Definições → Geral → VPN e gestão de dispositivos → confiar no programador.
   (Com conta gratuita a app expira ao fim de 7 dias e é preciso voltar a carregar ▶︎; com a conta de programador paga dura 1 ano.)

**Num iPad (sem Mac):** abrir `PlanoEmagrecer.swiftpm` na app Swift Playgrounds e carregar em ▶︎. A app corre no iPad.
