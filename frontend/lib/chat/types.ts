// Contrato da Pessoa 3. Ids: bigint identity (number); ids de pessoas são uuid (string).

export type Conversa = {
  id: number;
  clienteId: string;
  prestadoraId: string;
  outraPessoaNome: string; // join com perfis.nome
  outraPessoaAvatarUrl: string | null; // join com perfis.avatar_url
  ultimaMensagem: string | null;
  ultimaMensagemEm: string | null; // ISO 8601 UTC
  naoLidas: number; // vem da função nao_lidas()
};

export type Mensagem = {
  id: number;
  conversaId: number;
  autorId: string;
  texto: string;
  criadaEm: string; // ISO 8601 UTC
  lidaEm: string | null;
};
