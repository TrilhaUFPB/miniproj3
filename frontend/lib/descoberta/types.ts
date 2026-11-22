// Contrato da Pessoa 2.

export type Avaliacao = {
  id: number;
  prestadoraId: string;
  clienteId: string;
  clienteNome: string;
  nota: 1 | 2 | 3 | 4 | 5;
  comentario: string | null;
  criadaEm: string; // ISO 8601 UTC
};

export type PrestadoraResumo = {
  id: string;
  nome: string;
  avatarUrl: string | null;
  cidade: string | null;
  categorias: string[];
  notaMedia: number | null; // null sem avaliações
  totalAvaliacoes: number;
};

export type FiltrosBusca = {
  categoriaId?: number;
  cidade?: string;
  ordenarPor?: "nota";
};
