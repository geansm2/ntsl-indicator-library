//+------------------------------------------------------------------+
//|                        MicrostructureMeanReversion.mq5     |
//|                 Based on L. R. Amaral (2026) Microstructure Paper|
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "https://github.com/geansm2"
#property link      "https://arxiv.org/abs/2608.00885"
#property version   "2.01"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   4

//--- Configuração dos Gráficos Plotados
#property indicator_label1  "Gap (MicroPrice - Mid)"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Upper Band (+Theta*)"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrCrimson
#property indicator_style2  STYLE_DASH
#property indicator_width2  1

#property indicator_label3  "Lower Band (-Theta*)"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSeaGreen
#property indicator_style3  STYLE_DASH
#property indicator_width3  1

#property indicator_label4  "Zero Line"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDarkGray
#property indicator_style4  STYLE_DOT
#property indicator_width4  1

//--- Entradas de Parâmetros
input group "--- Estimacao do Preco Eficiente (Micro-Price) ---"
input bool     InpUseBookDepth     = true;      // Usar Livro de Ofertas (DOM) para Micro-Price
input int      InpEfficientPeriod  = 10;        // Periodo Fallback (EMA) se o Book nao estiver disponivel

input group "--- Calibracao do Modelo Ornstein-Uhlenbeck (OU) ---"
input int      InpEstimationWindow = 100;       // Janela de Regressao AR(1) (Velas/Ticks)
input double   InpMaxHalfLifeBars  = 50.0;      // Half-Life Maximo Aceito (em barras)

input group "--- Custos de Transacao e Fritura (Phi) ---"
input double   InpCommissionPoints = 0.5;       // Comissão Convertida em Pontos/Ticks
input double   InpSlippagePoints   = 0.5;       // Slippage Estimado em Pontos/Ticks

input group "--- Alertas ---"
input bool     InpEnableAlerts     = true;      // Ativar Alertas de Disparo

//--- Indicator Buffers
double BufferGap[];
double BufferUpperBand[];
double BufferLowerBand[];
double BufferZero[];
double BufferEfficientPrice[];
double BufferAlpha[];
double BufferHalfLife[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Indicadores visíveis
   SetIndexBuffer(0, BufferGap, INDICATOR_DATA);
   SetIndexBuffer(1, BufferUpperBand, INDICATOR_DATA);
   SetIndexBuffer(2, BufferLowerBand, INDICATOR_DATA);
   SetIndexBuffer(3, BufferZero, INDICATOR_DATA);
   
   // Buffers internos de cálculo
   SetIndexBuffer(4, BufferEfficientPrice, INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, BufferAlpha, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, BufferHalfLife, INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME, "Microstructure Reversion (Quant v2.01)");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   // Inscrever no Book de Ofertas caso ativado
   if(InpUseBookDepth)
   {
      if(!MarketBookAdd(_Symbol))
         Print("Aviso: Nao foi possivel se inscrever no Market Book para ", _Symbol, ". Usando fallback EMA.");
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(InpUseBookDepth)
      MarketBookRelease(_Symbol);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < InpEstimationWindow + InpEfficientPeriod)
      return(0);

   int start = (prev_calculated > 0) ? prev_calculated - 1 : 0;

   //------------------------------------------------------------------
   // 1. Cálculo do Preço Eficiente X_t e do Gap G_t
   //------------------------------------------------------------------
   for(int i = start; i < rates_total; i++)
   {
      double mid = close[i];
      double X_t = mid;

      // Cálculo via Micro-Price de Stoikov se disponível na barra atual
      bool microPriceCalculated = false;
      if(InpUseBookDepth && i == rates_total - 1) // Book em tempo real para a barra atual
      {
         MqlBookInfo book[];
         if(MarketBookGet(_Symbol, book))
         {
            double best_bid = 0.0, best_ask = 0.0;
            long vol_bid = 0, vol_ask = 0;

            for(int k = 0; k < ArraySize(book); k++)
            {
               if(book[k].type == BOOK_TYPE_BUY && best_bid == 0.0)
               {
                  best_bid = book[k].price;
                  vol_bid = book[k].volume;
               }
               else if(book[k].type == BOOK_TYPE_SELL && best_ask == 0.0)
               {
                  best_ask = book[k].price;
                  vol_ask = book[k].volume;
               }
               if(best_bid > 0 && best_ask > 0) break;
            }

            if((vol_bid + vol_ask) > 0 && (best_ask > best_bid))
            {
               double imbalance = (double)(vol_bid - vol_ask) / (double)(vol_bid + vol_ask);
               double current_spread = best_ask - best_bid;
               double current_mid = (best_bid + best_ask) / 2.0;
               
               // Fórmula do Micro-Price: X_t = Mid + Imbalance * (Spread / 2)
               X_t = current_mid + imbalance * (current_spread / 2.0);
               microPriceCalculated = true;
            }
         }
      }

      // Fallback: EMA do preço de fechamento para barras históricas
      if(!microPriceCalculated)
      {
         double alpha_ema = 2.0 / (InpEfficientPeriod + 1.0);
         double prev_ema = (i > 0) ? BufferEfficientPrice[i-1] : mid;
         X_t = (mid * alpha_ema) + (prev_ema * (1.0 - alpha_ema));
      }

      BufferEfficientPrice[i] = X_t;
      BufferGap[i] = mid - X_t;
      BufferZero[i] = 0.0;
   }

   //------------------------------------------------------------------
   // 2. Calibração AR(1) do Processo Ornstein-Uhlenbeck e Bandas Ótimas
   //------------------------------------------------------------------
   for(int i = start; i < rates_total; i++)
   {
      if(i < InpEstimationWindow)
      {
         BufferUpperBand[i] = 0.0;
         BufferLowerBand[i] = 0.0;
         BufferAlpha[i]     = 0.0;
         BufferHalfLife[i]  = 0.0;
         continue;
      }

      // Estimação OLS de G_t = a * G_{t-1} + e_t
      double sum_xy = 0.0, sum_x2 = 0.0;
      double mean_y = 0.0, mean_x = 0.0;

      for(int j = 0; j < InpEstimationWindow; j++)
      {
         mean_y += BufferGap[i - j];
         mean_x += BufferGap[i - j - 1];
      }
      mean_y /= InpEstimationWindow;
      mean_x /= InpEstimationWindow;

      for(int j = 0; j < InpEstimationWindow; j++)
      {
         double y = BufferGap[i - j] - mean_y;
         double x = BufferGap[i - j - 1] - mean_x;
         sum_xy += x * y;
         sum_x2 += x * x;
      }

      double a = (sum_x2 > 0) ? (sum_xy / sum_x2) : 0.0;
      
      // Restrição de Estacionariedade (0 < a < 1)
      if(a <= 0.0 || a >= 0.9999)
      {
         BufferUpperBand[i] = BufferUpperBand[i-1];
         BufferLowerBand[i] = BufferLowerBand[i-1];
         continue;
      }

      // Parâmetros do Processo Contínuo
      double dt = 1.0; // 1 barra/tick por unidade de tempo
      double alpha = -MathLog(a) / dt;
      
      // Cálculo do Erro Residual (Variância dos resíduos)
      double sum_e2 = 0.0;
      for(int j = 0; j < InpEstimationWindow; j++)
      {
         double e = (BufferGap[i - j] - mean_y) - a * (BufferGap[i - j - 1] - mean_x);
         sum_e2 += e * e;
      }
      double sigma_e2 = sum_e2 / (InpEstimationWindow - 2);

      // Variância Estacionária do Gap: s_G^2 = sigma_e2 / (1 - a^2)
      double s_G2 = sigma_e2 / (1.0 - MathPow(a, 2.0));

      // Half-Life (em barras/ticks)
      double half_life = MathLog(2.0) / alpha;
      BufferAlpha[i]    = alpha;
      BufferHalfLife[i] = half_life;

      // Custo Total Ajustado: phi_total = (Spread/2) + Comissão + Slippage
      double spread_cost = (spread[i] * _Point) / 2.0;
      double extra_costs = (InpCommissionPoints + InpSlippagePoints) * _Point;
      double phi_total   = spread_cost + extra_costs;

      // Condição do Artigo de Amaral (2026): \theta* = 0.5 * (\phi + \sqrt{\phi^2 + 4 * s_G^2})
      double theta_star = 0.5 * (phi_total + MathSqrt(MathPow(phi_total, 2.0) + 4.0 * s_G2));

      // Filtro de Qualidade Quântica: Se o Half-Life for muito longo, desativa entradas
      if(half_life > InpMaxHalfLifeBars)
      {
         BufferUpperBand[i] = EMPTY_VALUE;
         BufferLowerBand[i] = EMPTY_VALUE;
      }
      else
      {
         BufferUpperBand[i] = theta_star;
         BufferLowerBand[i] = -theta_star;
      }

      //------------------------------------------------------------------
      // Alertas de Gatilho na Barra Fechada Recente
      //------------------------------------------------------------------
      if(InpEnableAlerts && i == rates_total - 2)
      {
         if(BufferUpperBand[i] != EMPTY_VALUE)
         {
            if(BufferGap[i] <= BufferLowerBand[i] && BufferGap[i-1] > BufferLowerBand[i-1])
            {
               Alert(StringFormat("[%s] SINAL QUANT COMPRA: Gap (%.5f) <= Band (-Theta*: %.5f) | Half-Life: %.1f barras", 
                     _Symbol, BufferGap[i], BufferLowerBand[i], half_life));
            }
            else if(BufferGap[i] >= BufferUpperBand[i] && BufferGap[i-1] < BufferUpperBand[i-1])
            {
               Alert(StringFormat("[%s] SINAL QUANT VENDA: Gap (%.5f) >= Band (+Theta*: %.5f) | Half-Life: %.1f barras", 
                     _Symbol, BufferGap[i], BufferUpperBand[i], half_life));
            }
         }
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+