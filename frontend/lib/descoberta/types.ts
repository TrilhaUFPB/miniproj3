// Contrato da Pessoa 2. Ids: bigint identity (number); ids de perfis são uuid (string).
import type { FotoPortfolio, Perfil } from "../identidade/types";

export type Avaliacao = {
  id: number;
  prestadoraId: string;
  clienteId: string;
  clienteNome: string;
  prestadoraNome: string; // usado em "Minhas indicações"
  prestadoraAvatarUrl: string | null;
  nota: 1 | 2 | 3 | 4 | 5;
  comentario: string | null;
  criadaEm: string; // ISO 8601 UTC
};

export type PrestadoraResumo = {
  id: string;
  nome: string;
  avatarUrl: string | null;
  cidade: string | null;
  categorias: { id: number; nome: string }[];
  notaMedia: number | null; // null sem avaliações
  totalAvaliacoes: number;
};

export type FiltrosBusca = {
  categoriaId?: number;
  cidade?: string; // comparação sem acento e sem diferença de maiúscula ("Joao Pessoa" = "João Pessoa")
  ordenarPor?: "nota";
};

// Dados da página /prestadoras/[id]: monta-se com Perfil + categorias + fotos + avaliações.
export type PrestadoraDetalhe = {
  perfil: Perfil;
  categorias: { id: number; nome: string }[];
  fotos: FotoPortfolio[];
  avaliacoes: Avaliacao[];
  notaMedia: number | null;
  totalAvaliacoes: number;
};
