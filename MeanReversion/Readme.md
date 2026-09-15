# Microstructure Mean Reversion Indicator (MQL5 / MetaTrader 5)

Este diretório contém a implementação quantitativa do indicador de reversão à média de microestrutura para MetaTrader 5, desenvolvido em MQL5.

## 📌 Origem do Modelo Teórico

A arquitetura teórica deste indicador é baseada no artigo científico:

> **Amaral, Lucas Rabechini (2026).** *Optimal Trading of Microstructure Mean Reversion*.

### Conceito Científico
No nível de microestrutura de mercado, o preço médio (*mid price*) oscila em torno de um **preço eficiente latente** ($X_t$). O desvio entre o preço observado e o valor de equilíbrio é definido pelo **Gap** ($G_t = M_t - X_t$), que exibe uma forte propriedade de reversão à média estacionária modelada por um processo **Ornstein-Uhlenbeck (OU)**.

O artigo demonstra que a largura de banda ótima ($\theta^*$) para execução sem *churning* (fricção excessiva) é dada pela solução analítica:

$$\theta^* = \frac{1}{2} \left( \phi + \sqrt{\phi^2 + 4 s_G^2} \right)$$

Onde:
* $\phi$: Custo total de fricção por transação (meio-spread e custos).
* $s_G^2$: Variância estacionária contínua do gap.

---

## 🚀 Adaptações Quantitativas de Produção (v2.0)

Para adaptar o modelo teórico acadêmico a um ambiente de execução real em alta frequência (HFT), realizamos as seguintes evoluções quantitativas:

### 1. Preço Eficiente ($X_t$) via Micro-Price de Stoikov
* **Abordagem Teórica:** Média móvel ou componente permanente de Hasbrouck.
* **Implementação Real:** Captura do Livro de Ofertas Nível 2 (DOM) em tempo real via API do MT5 (`MqlBookInfo`). O preço eficiente é calculado dinamicamente usando o desbalanço de volume (*Volume Imbalance*):
  $$X_t^{\text{micro}} = \text{Mid}_t + I_t \cdot \frac{\text{Spread}_t}{2}$$

### 2. Calibração dos Parâmetros OU via Regressão AR(1)
* **Abordagem Teórica:** Medição estática por desvio padrão.
* **Implementação Real:** Regressão autoregressiva AR(1) em janela móvel sobre o gap ($G_t = a G_{t-1} + \epsilon_t$). A velocidade de reversão ($\alpha$) e a variância estacionária do processo contínuo ($s_G^2$) são extraídas em tempo real:
  $$\alpha = -\frac{\ln(a)}{\Delta t}, \quad s_G^2 = \frac{\sigma_{\epsilon}^2}{1 - a^2}$$

### 3. Modelo Integrado de Custos e Fritura ($\phi_{\text{total}}$)
* **Abordagem Teórica:** Apenas meio-spread do tick.
* **Implementação Real:** Incorporação dinâmica do spread do livro somado a parâmetros ajustáveis de **comissão da corretora** e **slippage estimado**:
  $$\phi_{\text{total}} = \frac{\text{Spread}}{2} + \text{Comissão} + \text{Slippage}$$

### 4. Filtro de Qualidade por *Half-Life*
* Para evitar *false breakouts* ou entradas contra a tendência em momentos de baixa estacionariedade, o código calcula o tempo meio da reversão ($\text{Half-Life} = \frac{\ln(2)}{\alpha}$). Se o Half-Life exceder o limite aceitável (`InpMaxHalfLifeBars`), as bandas são desativadas temporariamente.

---

## 🛠️ Arquivos do Repositório

* `MicrostructureMeanReversion_Quant.mq5`: Código fonte do indicador em MQL5.
* `README.md`: Documentação técnica.

---

## ⚖️ Licença e Uso

Este código foi desenvolvido para fins educacionais e de pesquisa quantitativa. Sinais gerados por este indicador devem ser testados em ambiente de simulação (*backtest/demo*) antes do uso em contas reais.
