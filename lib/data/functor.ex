require Socle.Meta.Typeclass
Socle.Meta.Typeclass.define Functor do
  defoverridable_curried map(_, _), do: raise("Missing `map` definition for functor instance #{__MODULE__}")

  defoverridable_curried constF(x, ty), do: map(Socle.Data.Function.const(x), ty)
end
