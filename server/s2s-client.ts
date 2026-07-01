/**
 * GBO Ads — server-side S2S postbacks (registration + deposit).
 * Copy into your money-site backend or adapt to PHP/Python (see README).
 * Kit version: see ../VERSION
 */

export type S2sEvent = 'registration' | 'deposit';

export type PostConversionInput = {
  event: S2sEvent;
  clkId: string;
  value?: number;
  currency?: string;
  properties?: Record<string, unknown>;
};

export type S2sResponse = {
  attributed: boolean;
  clk_id: string | null;
  crid: string | null;
  campaign_id: string | null;
  source: string | null;
  platform_postback?: { platform: string | null; status: string; message: string } | null;
};

export function getTrackerConfig(): { origin: string; apiKey: string } {
  const origin = process.env.TRACKER_ORIGIN?.replace(/\/$/, '');
  const apiKey = process.env.S2S_API_KEY?.trim();
  if (!origin) throw new Error('TRACKER_ORIGIN is not set');
  if (!apiKey) throw new Error('S2S_API_KEY is not set');
  return { origin, apiKey };
}

export async function postConversion(input: PostConversionInput): Promise<S2sResponse> {
  const { origin, apiKey } = getTrackerConfig();
  const body: Record<string, unknown> = {
    event: input.event,
    clk_id: input.clkId
  };
  if (input.value !== undefined) body.value = input.value;
  if (input.currency) body.currency = input.currency;
  if (input.properties) body.properties = input.properties;

  const res = await fetch(`${origin}/api/v1/s2s/event`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });

  const text = await res.text();
  if (!res.ok) {
    throw new Error(`S2S ${res.status}: ${text}`);
  }
  return JSON.parse(text) as S2sResponse;
}

/** Call after account creation — user must have clk_id stored. */
export async function postRegistration(clkId: string, properties?: Record<string, unknown>) {
  return postConversion({ event: 'registration', clkId, properties });
}

/** Call on payment webhook success only — same clk_id as registration. */
export async function postDeposit(
  clkId: string,
  value: number,
  currency: string,
  properties?: Record<string, unknown>
) {
  return postConversion({ event: 'deposit', clkId, value, currency, properties });
}
