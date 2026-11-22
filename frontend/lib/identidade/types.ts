// Contrato da Pessoa 1. As Pessoas 2 e 3 só leem estes tipos.

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

export type FotoPortfolio = {
  id: number;
  prestadoraId: string;
  url: string;
  legenda: string | null;
};
