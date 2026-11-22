// Contrato da Pessoa 3.

export type Conversa = {
  id: number;
  clienteId: string;
  prestadoraId: string;
  outraPessoaNome: string;
  ultimaMensagem: string | null;
  ultimaMensagemEm: string | null; // ISO 8601 UTC
  naoLidas: number;
};

export type Mensagem = {
  id: number;
  conversaId: number;
  autorId: string;
  texto: string;
  criadaEm: string; // ISO 8601 UTC
  lidaEm: string | null;
};
