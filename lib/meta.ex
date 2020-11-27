defmodule Socle.Meta do
  ### TODO : define this in module too
  defmacro open(module, only: only, except: except, do: ast) do
    do_open(module, %{only: only, except: except}, ast, __CALLER__)
  end
  defmacro open(module, only: only, do: ast) do
    do_open(module, %{only: only}, ast, __CALLER__)
  end
  defmacro open(module, except: except, do: ast) do
    do_open(module, %{except: except}, ast, __CALLER__)
  end
  defmacro open(module, do: ast) do
    do_open(module, %{}, ast, __CALLER__)
  end
  defmacro open(module, ast) do
    do_open(module, %{}, ast, __CALLER__)
  end
  defmacro open(module, [only: only, except: except], do: ast) do
    do_open(module, %{only: only, except: except}, ast, __CALLER__)
  end
  defmacro open(module, [only: only], do: ast) do
    do_open(module, %{only: only}, ast, __CALLER__)
  end
  defmacro open(module, [except: except], do: ast) do
    do_open(module, %{except: except}, ast, __CALLER__)
  end

  defmacro mk_open do
    quote do
      defmacro open(only: only, except: except, do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{only: only, except: except}, ast, __CALLER__)
      end
      defmacro open(only: only, do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{only: only}, ast, __CALLER__)
      end
      defmacro open(except: except, do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{except: except}, ast, __CALLER__)
      end
      defmacro open(do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{}, ast, __CALLER__)
      end
      defmacro open(ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{}, ast, __CALLER__)
      end
      defmacro open([only: only, except: except], do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{only: only, except: except}, ast, __CALLER__)
      end
      defmacro open([only: only], do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{only: only}, ast, __CALLER__)
      end
      defmacro open([except: except], do: ast) do
        unquote(__MODULE__).do_open(__MODULE__, %{except: except}, ast, __CALLER__)
      end
    end
    |> case do x -> IO.puts(Macro.to_string(x)) ; x end
  end

  def do_open(module_ast, opts, ast, caller) do
    module = Macro.expand(module_ast, caller)

    ast = if module == caller.module do
      do_open_on_self(module, ast)
    else
      do_open_go(module_ast, module, opts, ast, caller)
    end

    ast
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  def do_open_on_self(module, ast) do
    updated_ast = Macro.prewalk(ast, fn
      {_, _, _} = x ->
        Macro.update_meta(x, fn m -> Keyword.put(m, :import, module) end)

      x -> x
    end)

    updated_ast
  end

  def do_open_go(module_ast, module, opts, ast, _caller) do
    only = Map.get(opts, :only, [])
    except = Map.get(opts, :except, [])

    functions = 
      module.__info__(:functions)
      |> Enum.filter(fn x when only != [] -> x in only ; _ -> true end)
      |> Enum.filter(fn x -> x not in except end)

    macros = 
      module.__info__(:macros)
      |> Enum.filter(fn x when only != [] -> x in only ; _ -> true end)
      |> Enum.filter(fn x -> x not in except end)

    name_x_arity = functions ++ macros

    _ = if {:open, 2} in name_x_arity or {:open, 3} in name_x_arity do
      require Logger
      _ = Logger.warn("Warning: open/2,3 in #{inspect(module)} may override inner uses of Socle.Meta.open/2,3 macro")
    end

    updated_ast = Macro.prewalk(ast, fn
      {name, _, xs} = x when is_list(xs) ->
        if {name, length(xs)} in name_x_arity do
          #Macro.update_meta(x, fn m -> Keyword.put(m, :import, module) end)
          {{:., [], [module_ast, name]}, [], xs}
        else
          x
        end

      x -> x
    end)

    updated_ast
  end
  #def do_open_without_info()
  #def do_open_with_info()
end
