# Plano Emagrecer (iOS)

App em SwiftUI (iOS 17+) feita a partir da folha "Plano para emagrecer — ementa e registo".

## O que tem

| Separador | O quê |
|---|---|
| **Hoje** | Ementa do dia com as 5 refeições para marcar; botão ✏️ em cada refeição para **trocar** pela de outro dia, registar **o que comi** (lista de ~115 pratos e alimentos com calorias e porções) ou **escrever** à mão. Calorias do dia (comidas / previstas / meta, extras e cervejas). **Água** com copos de 250 ml e meta diária. As 4 regras que dão pontos, peso, notas, resumo da semana. |
| **Progresso** | Peso inicial / atual / meta, ritmo e data prevista, gráfico do peso, pontos das últimas 8 semanas, média de calorias, histórico editável (com água e peso). |
| **Ementa** | Os 7 dias, com as calorias de cada refeição e do dia. |
| **Compras** | Os 34 produtos, para marcar; adicionar, apagar, desmarcar tudo, partilhar. |
| **Mais** | Regras, objetivos (peso, pontos, cervejas, calorias, água), lembretes (registo, pesagem, caminhada, **água de X em X horas**), exportar CSV. |

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
