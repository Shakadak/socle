defmodule Socle.Control.Lazy do
  defmacro delay(ast) do
    quote do: {:Lazy, fn -> unquote(ast) end}
  end
  defmacro force(ast) do
    quote do
      {:Lazy, thunk} = unquote(ast) ; thunk.()
    end
  end
end
