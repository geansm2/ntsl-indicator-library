# Order Flow Imbalance (OFI Quant) - Manual do Indicador

O **OFI Quant** é um indicador avançado de Microestrutura de Mercado que traduz o fluxo invisível do Livro de Ofertas (Level 1) em um formato visual intuitivo. Diferente de indicadores tradicionais que rastreiam o passado (preço fechado), o OFI rastreia a **intenção futura**, medindo o desequilíbrio entre a entrada e o cancelamento de ordens de limite.

---

## 1. Como o Indicador Funciona?

A cada tick do mercado, o indicador observa a melhor linha de Compra (Bid) e a melhor linha de Venda (Ask). 
- Se novos lotes são adicionados na compra (ou cancelados na venda), ele soma pontos positivos.
- Se novos lotes são adicionados na venda (ou cancelados na compra), ele soma pontos negativos.

> [!TIP]
> **Normalização de Liquidez**
> O volume bruto calculado é dividido pela liquidez total visível no topo do book. Isso transforma o indicador em uma **porcentagem** (oscilador universal). Assim, você não precisa calibrar o indicador caso troque do Mini-Índice (muita liquidez) para o Mini-Dólar (baixa liquidez). A escala se ajusta sozinha.

---

## 2. Guia Visual da Tela

O indicador plota 3 elementos gráficos simultaneamente:

### A. O Histograma (Semáforo do Fluxo)
O corpo principal do indicador são as barras coloridas. Elas revelam não apenas a direção do fluxo, mas a sua **aceleração**:
*   🟢 **Verde Claro:** Fluxo Comprador Dominante e **Acelerando** (maior que o candle anterior).
*   🔴 **Vermelho:** Fluxo Vendedor Dominante e **Acelerando** (mais negativo que o candle anterior).
*   🟡 **Amarelo:** O fluxo dominante (seja compra ou venda) está **desacelerando**. Funciona como um sinal amarelo de trânsito: a pressão que estava movendo o preço entrou em exaustão/realização.

### B. A Linha de Sinal (Média Móvel)
Uma linha desenhada sobre o histograma (padrão de 5 períodos). Ela filtra os ruídos e solavancos bruscos do livro de ofertas, mostrando a verdadeira "inércia" das intenções institucionais.

### C. A Linha Zero
Uma reta fixa central. Tudo acima dela é território dominado por compradores no limite. Tudo abaixo é território vendedor.

---

## 3. O Parâmetro Oculto: "AcumularNoDia" (COFI)

Por padrão, o OFI funciona como um **Oscilador**, zerando a contagem a cada novo candle para te dar uma visão cirúrgica do micro-movimento. 
No entanto, nas propriedades do indicador, você pode ligar a opção `AcumularNoDia`. 

> [!IMPORTANT]
> **O Poder do COFI (Cumulative OFI)**
> Ao ligar essa opção, o indicador deixa de zerar e soma o fluxo o dia inteiro. Ele se transforma num rastreador de tendência macro. Excelente para descobrir se os grandes players estão passando o dia todo "enchendo o carrinho" de forma escondida.

---

## 4. Setups e Gatilhos (Como Operar)

Use o OFI sempre em conjunto com o Gráfico (Inferência Bayesiana). O gráfico te diz **ONDE** (suportes, resistências, VWAP), e o OFI te diz **QUANDO** agir.

1. **O Cruzamento da Linha de Sinal:** 
   O setup mais clássico. Quando o mercado toca num suporte e as barras coloridas cruzam a Linha Branca para cima com uma barra 🟢 Verde, você tem a confirmação estatística de que o fluxo virou para a compra.
2. **A Divergência de Absorção:**
   O preço (gráfico de velas) rompe um fundo fazendo uma nova mínima, mas o Histograma do OFI não faz um novo fundo. Em vez disso, ele fica Amarelo ou Verde. Isso prova que os vendedores agrediram o rompimento, mas caíram em uma armadilha de liquidez de grandes compradores limitados (Absorção). O preço tende a reverter forte.
3. **Fuga de Momentum:**
   Se o OFI rompe a sua própria máxima recente, significa que a urgência institucional atingiu um pico. É a confirmação de que um rompimento no gráfico de velas é real e tem combustível financeiro para continuar.

> [!WARNING]
> **Limitação Técnica de Tempo Gráfico**
> Como as plataformas (Profit/MT5) não possuem banco de dados histórico do Livro de Ofertas, o indicador reconstrói a leitura ao vivo na sua tela. **Se você trocar o tempo gráfico (ex: de 5 Min para 15 Min), o indicador irá reiniciar do zero.** A melhor prática é deixar um gráfico isolado (ex: WIN 5 Min) apenas para a leitura do OFI, sem mudar de tempo.
