defmodule Socle.Data.Function do
  use Socle.Meta.Curry

  require Socle.Meta

  Socle.Meta.mk_open

  defcurried id(x), do: x

  defcurried const(x, _), do: x

  defcurried compose(f, g, x), do: f.(g.(x))
  defcurried f .. g, do: fn x -> f.(g.(x)) end

  defcurried flip(f, x, y) when is_function(f, 2), do: f.(y, x)
  defcurried flip(f, x, y) when is_function(f, 1), do: f.(y).(x)

  defcurried fix(f, x) when is_function(f, 2), do: f.(fix(f), x) # would it even work ?
  defcurried fix(f, x) when is_function(f, 1), do: f.(fix(f)).(x)

  defcurried on(bi, f, x, y) when is_function(bi, 2), do: bi.(f.(x), f.(y))
  defcurried on(bi, f, x, y) when is_function(bi, 1), do: bi.(f.(x)).(f.(y))

  defcurried ap(f, x), do: f.(x)
  defcurried pa(x, f), do: f.(x)
end
