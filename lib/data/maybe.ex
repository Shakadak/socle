defmodule Socle.Data.Maybe do
  use Socle.Meta.Curry

  require Functor
  require Applicative

  defcurried just(x), do: {:Just, x}
  defcurried nothing, do: :Nothing

  defcurried maybe(n, _, :Nothing  ), do: n
  defcurried maybe(_, f, {:Just, x}), do: f.(x)

  defcurried isJust({:Just, _}), do: true
  defcurried isJust(:Nothing  ), do: false

  defcurried isNothing(:Nothing  ), do: true
  defcurried isNothing({:Just, _}), do: false

  Functor.instanciate do
    defcurried map(_, :Nothing  ), do: :Nothing
    defcurried map(f, {:Just, x}), do: {:Just, f.(x)}
  end

  Applicative.instanciate [functor: __MODULE__] do
    defcurried pure(x), do: {:Just, x}

    defcurried {:Just, f} <~> {:Just, x}, do: {:Just, f.(x)}
  end
end
