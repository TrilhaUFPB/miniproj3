// Contrato da Pessoa 1. As Pessoas 2 e 3 só leem estes tipos.
// Ids: uuid (string) só em perfis; demais tabelas usam bigint identity (number).

export type PapelPerfil = "cliente" | "prestadora";

export type Perfil = {
  id: string; // = auth.users.id
  papel: PapelPerfil;
  nome: string;
  avatarUrl: string | null;
  bio: string | null;
  cidade: string | null;
};

export type CategoriaServico = {
  id: number;
  nome: string;
};

export type ServicoPrestadora = {
  prestadoraId: string;
  categoriaId: number;
};

export type FotoPortfolio = {
  id: number;
  prestadoraId: string;
  url: string;
  legenda: string | null;
};
