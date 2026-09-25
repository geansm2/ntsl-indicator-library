# Dynamic Risk ATR Map (v4.05)

O **Dynamic Risk ATR Map** é um indicador técnico focado em análise de volatilidade, estrutura de mercado e níveis de invalidação técnica, disponível em versões para **MetaTrader 5 (MQL5)** e **ProfitChart (NTSL)**.

O indicador calcula e projeta linhas de stop dinâmicas (níveis de invalidação para compra e venda) ajustadas continuamente ao regime de volatilidade do mercado, além de identificar suportes e resistências estruturais e sinalizar a direção do momento por meio de coloração baseada em **Momentum Relativo (normalizado por ATR)**.

---
<img width="1362" height="673" alt="image" src="https://github.com/user-attachments/assets/0837d7fd-8333-4239-96ed-0fb0c04dda5e" />

## Principais Funcionalidades

* **Níveis de Invalidação Dinâmicos**: Ajusta a distância dos níveis de stop (compra e venda) com base na relação entre a volatilidade de curto prazo e a volatilidade base de longo prazo.
* **Proteção Estrutural de Preço**: Combina a variação do ATR com as extremidades de preço (máximas e mínimas) dos últimos $N$ candles, aplicando um buffer de segurança contra ruídos de mercado.
* **Coloração por Momentum em ATR**: Altera a cor das linhas no gráfico (Verde/Azul, Vermelho e Amarelo) de acordo com a força e direção do deslocamento de preço em relação à volatilidade atual.
* **Mapeamento Espacial e Projeções**: Desenha projeções visuais das linhas no gráfico, incluindo níveis de volatilidade ($\pm 1$ ATR e $\pm 2$ ATR), caixas de suporte/resistência e projeções futuras.

---

## Lógica e Referência Teórica

A mecânica do indicador fundamenta-se nos seguintes pilares matemáticos:

### 1. Volatilidade Relativa e Multiplicador Dinâmico ($K_{\text{final}}$)
Para mensurar a expansão ou compressão da volatilidade, o indicador calcula a razão entre o ATR curto ($ATR$) e a sua média de longo prazo ($ATR_{\text{Base}}$):

$$\text{VolRatio} = \frac{ATR}{ATR_{\text{Base}}}$$

O multiplicador base ($K_{\text{base}}$) é ajustado proporcionalmente a essa razão e limitado ao intervalo $[K_{\text{min}}, K_{\text{max}}]$:

$$K_{\text{dynamic}} = K_{\text{base}} \times \text{VolRatio}$$

$$K_{\text{final}} = \text{Clamp}\left(K_{\text{dynamic}}, K_{\text{min}}, K_{\text{max}}\right)$$

$$dATR = ATR \times K_{\text{final}}$$

*Se a volatilidade se expande, a distância do stop aumenta para evitar saídas prematuras; durante momentos de baixa volatilidade, o nível de stop se aproxima do preço.*

### 2. Níveis de Invalidação Estruturais (Stop Compra e Venda)
O cálculo das linhas de invalidação considera as máximas e mínimas do período determinado ($N$), somadas a um buffer proporcional ao ATR ($\text{Buffer} = ATR \times \text{InpStructureBuffer}$):

* **Distância do Stop de Compra ($d_{\text{Buy}}$)**:
  $$d_{\text{Buy}} = \max\left(dATR, \text{Preço} - (\text{Mínima}_{N} - \text{Buffer})\right)$$
  $$\text{Stop Compra} = \text{Preço} - d_{\text{Buy}}$$

* **Distância do Stop de Venda ($d_{\text{Sell}}$)**:
  $$d_{\text{Sell}} = \max\left(dATR, (\text{Máxima}_{N} + \text{Buffer}) - \text{Preço}\right)$$
  $$\text{Stop Venda} = \text{Preço} + d_{\text{Sell}}$$

### 3. Momentum Normalizado em ATR (Coloração)
O momentum mede o deslocamento do preço atual em relação ao fechamento de $K$ candles passados, medido em múltiplos do ATR atual:

$$\text{Momentum}_{\text{Pts}} = \text{Preço Atual} - \text{Fechamento}_{K}$$

$$\text{Momentum}_{\text{ATR}} = \frac{\text{Momentum}_{\text{Pts}}}{ATR}$$

**Critério de Coloração:**
* $\text{Momentum}_{\text{ATR}} > +0.10$ $\rightarrow$ **Verde / Azul** (Momentum Autoral / Alta)
* $\text{Momentum}_{\text{ATR}} < -0.10$ $\rightarrow$ **Vermelho** (Momentum Baixista)
* $-0.10 \le \text{Momentum}_{\text{ATR}} \le +0.10$ $\rightarrow$ **Amarelo** (Neutro / Consolidação)

---

## Parâmetros do Indicador (Inputs)

### Volatilidade e Estrutura
| Parâmetro | Padrão | Descrição |
| :--- | :--- | :--- |
| `InpATRPeriod` | `20` | Período do ATR curto ($N$) |
| `InpATRBasePeriod` | `100` | Período da média histórica do ATR ($M$) |
| `InpMAType` | `MODE_EMA_TYPE` | Tipo de média móvel para o cálculo do ATR |
| `InpBaseMultiplier`| `1.50` | Multiplicador Base do ATR ($K_{\text{base}}$) |
| `InpMinMultiplier` | `1.00` | Multiplicador Mínimo aceito ($K_{\text{min}}$) |
| `InpMaxMultiplier` | `3.00` | Multiplicador Máximo aceito ($K_{\text{max}}$) |
| `InpStructurePeriod`| `10` | Período de busca para suporte e resistência |
| `InpStructureBuffer`| `0.25` | Proporção do ATR aplicada ao buffer estrutural |

### Momentum
| Parâmetro | Padrão | Descrição |
| :--- | :--- | :--- |
| `InpMomentumPeriod`| `10` | Quantidade de barras para o cálculo do Momentum |

### Visualização Gráfica
| Parâmetro | Padrão | Descrição |
| :--- | :--- | :--- |
| `InpShowMapObjects`| `true` | Ativa a renderização dos objetos visuais e projeções no gráfico |

---

## Instalação (MetaTrader 5)

1. No MetaTrader 5, acesse **Arquivo $\rightarrow$ Abrir Pasta de Dados**.
2. Navegue até o diretório `MQL5/Indicators/` e cole o arquivo `DynamicRiskATR.v8.mq5`.
3. Abra o MetaEditor (`F4`), selecione o arquivo na árvore do navegador e clique em **Compilar**.
4. Arraste o indicador a partir da janela *Navegador* do MT5 para o gráfico.

## Instalação (MetaTrader 5)
1. No ProfitPro acesse **Extratégias>Importar/Exportar Estratégias$ para Abrir pasta onde foi salvo o arquivo**.
2. Navegue até o diretório `Stop_ATR_Dinamico_Estrutural.psf`.
3. Selecione a estratégias e clique em importar.
---

## 📚 Referências Teóricas

* **Wilder, J. Welles (1978)**. *New Concepts in Technical Trading Systems*. Trend Research. (Conceito e cálculo do *Average True Range - ATR*).
* **Guppy, Daryl (2004)**. *Trend Trading*. John Wiley & Sons. (Uso de múltiplos de volatilidade para filtragem de ruído e linhas de invalidação).

---

## 📄 Licença
Este código é disponibilizado para fins educacionais e de estudo. Licença MIT.
Este projeto está sob a licença [MIT](LICENSE).
