// Quando true, os service.ts devolvem os mocks em vez de chamar o Supabase.
// Só o valor exato "true" liga os mocks; sem .env.local o padrão é Supabase real.
export const USAR_MOCKS = process.env.NEXT_PUBLIC_USE_MOCKS === "true";
