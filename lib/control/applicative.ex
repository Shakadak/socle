require Socle.Meta.Typeclass
Socle.Meta.Typeclass.define Applicative, [:functor] do
  alias Socle.Data.Function

  defoverridable_curried pure(_), do: raise("Missing `pure` definition for applicative instance #{__MODULE__}")

  defoverridable_curried tf <~> tx, do: liftA2(Function.id, tf, tx)

  defoverridable_curried liftA2(f, tx, ty), do: functor().map(f, tx) <~> ty

  defoverridable_curried leftA(tx, ty), do: liftA2(&Function.const/2, tx, ty)
  defoverridable_curried rightA(tx, ty), do: liftA2(fn _, y -> y end, tx, ty)
end
