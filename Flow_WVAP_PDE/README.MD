# Flow VWAP PDE: Modelagem Analítica baseada em Equação de Difusão e Séries de Fourier

Este repositório contém a especificação matemática, dedução teórica e a implementação prática do indicador **Flow VWAP PDE**, desenvolvido para o **MetaTrader 5 (MQL5)** e **ProfitChart (NTSL)**. 

O modelo substitui a ponderação convencional por volume acumulado por uma solução analítica da **Equação do Calor (EDP)** com condições de contorno de Dirichlet, utilizando uma **Série de Fourier** para modelar o fluxo de ordens e a dissipação de preços ao longo do tempo de pregão.

---

## 1. Formulação do Campo de Fluxo e EDP

O campo de fluxo de ordens e preços $V(p, t)$ é modelado no domínio espacial do preço $p$ (com $0 < p < P$, onde $P = P_{\text{teto}} - P_{\text{piso}}$) e no domínio temporal $t$ a partir da abertura do pregão ($t > 0$), governado pela equação diferencial parcial de difusão[cite: 1]:

$$\frac{\partial V}{\partial t} = \kappa \frac{\partial^2 V}{\partial p^2}, \quad 0 < p < P, \ t > 0$$

Sujeita às condições de contorno de anulação nos nós extremos e à condição inicial dada pelo perfil agressivo de prêmios/ordens na abertura $\Pi(p)$[cite: 1]:

$$V(0, t) = V(P, t) = 0, \quad V(p, 0) = \Pi(p)$$

---

## 2. Solução por Separação de Variáveis e Série de Fourier

Aplicando o método de separação de variáveis, cada modo espacial decai de forma independente de acordo com sua frequência e com o coeficiente de difusão $\kappa$[cite: 1]:

$$V_n(p, t) = A_n e^{-\kappa \left(\frac{n\pi}{P}\right)^2 t} \sin\left(\frac{n\pi p}{P}\right), \quad n = 1, 2, 3, \dots$$

A solução geral é a superposição de todos os modos (Série de Fourier senoidal)[cite: 1]:

$$V(p, t) = \sum_{n=1}^{\infty} A_n e^{-\kappa \left(\frac{n\pi}{P}\right)^2 t} \sin\left(\frac{n\pi p}{P}\right)$$

---

## 3. Determinação Rigorosa dos Coeficientes $A_n$

Substituindo a condição inicial $V(p, 0) = \Pi(p)$ (o perfil inicial de fluxo observado na abertura)[cite: 1], os coeficientes espectrais da série são obtidos por projeção ortogonal[cite: 1]:

$$A_n = \frac{2}{P} \int_{0}^{P} \Pi(p) \sin\left(\frac{n\pi p}{P}\right) dp, \quad n = 1, 2, 3, \dots$$

* **Implementação Prática (Discretização em Plataformas):** Na ausência de uma função analítica contínua $\Pi(p)$, o perfil inicial de fluxo é construído através de um histograma discreto de volume real acumulado por faixa de preço $p_k$ desde o instante de abertura:
  $$A_n \approx \frac{2}{P} \sum_{k} \left[ \text{Vol}(p_k) \cdot \sin\left(\frac{n\pi (p_k - P_{\text{piso}})}{P}\right) \right]$$

---

## 4. Definição Correta do Domínio e da Flow VWAP Absoluta

O intervalo de preços $P$ deve ser mantido estavelmente consistente durante a evolução da sessão. Definindo o tamanho do canal como:
$$P = P_{\text{teto}} - P_{\text{piso}}$$

A **Flow VWAP** é definida analiticamente como o preço médio ponderado pelo campo de fluxo $V(p, t)$[cite: 1]:

$$\text{VWAP}_{\text{flow}}(t) = \frac{\int_{0}^{P} p \, V(p, t) \, dp}{\int_{0}^{P} V(p, t) \, dp}$$

Resolvendo as integrais analíticas padrão e reajustando para o preço absoluto do gráfico somando-se o piso ($P_{\text{piso}}$), obtém-se a expressão fechada final:

$$\text{VWAP}_{\text{flow}}(t) = P_{\text{piso}} + \frac{P}{2} \cdot \frac{\sum_{n=1}^{N} \frac{(-1)^{n+1}}{n} A_n e^{-\kappa(n\pi/P)^2 t}}{\sum_{n=1, \text{ímpar}}^{N} \frac{1}{n} A_n e^{-\kappa(n\pi/P)^2 t}}$$
---

## 5. Calibração do Coeficiente de Difusão $\kappa$ (Kappa)

O parâmetro $\kappa$ rege a taxa de dissipação energética e temporal dos modos de Fourier. A taxa de decaimento para o $n$-ésimo modo é dada por:
$$\lambda_n = \kappa \left(\frac{n\pi}{P}\right)^2$$

Como os modos superiores decaem exponencialmente mais rápido, apenas o primeiro modo ($n = 1$) sobrevive quando $t \to \infty$, fazendo o indicador convergir assintoticamente para o ponto médio geométrico do canal[cite: 1]:
$$\lim_{t \to \infty} \text{VWAP}_{\text{flow}}(t) = P_{\text{piso}} + \frac{P}{2}$$

### Metodologia de Calibração por Meia-Vida ($T_{1/2}$)
Em vez de arbitrar valores fixos para $\kappa$, a calibração profissional fixa o tempo de meia-vida desejado ($T_{1/2}$, em minutos) para o modo fundamental ($n=1$):
$$\kappa = \frac{P^2 \ln(2)}{\pi^2 T_{1/2}}$$

---

## 6. Resumo da Implementação Prática

| Plataforma | Linguagem | Tratamento de Domínio | Método de Coleta de Perfil |
| :--- | :--- | :--- | :--- |
| **MetaTrader 5** | MQL5 | Fixo no dia (`High`/`Low`) ou Lookback Móvel | Acumulação por barras ou ticks via `CopyTicksRange` |
| **ProfitChart** | NTSL | Fixo na Máxima e Mínima do dia atual (`DayHigh`/`DayLow`) | Varredura linear das barras intradiárias com preço típico |
