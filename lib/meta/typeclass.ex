defmodule Socle.Meta.Typeclass do
  defmacro define(name, required_deps \\ [], do: default_body) do
    deps_check_ast = case required_deps do
      [] -> quote do
        # no check on deps needed
      end
      _ ->
        quote do
          required_deps = unquote(required_deps)
          _ = case required_deps -- Keyword.keys(deps) do
            [] -> :ok
            missing_deps -> raise("Missing dependencies to instanciate #{__MODULE__} : #{inspect(missing_deps)}")
          end
        end
    end
    quote location: :keep do
      defmodule unquote(name) do
        defmacro instanciate(do: body) do
          instanciate_go([], body)
          |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
        end

        defmacro instanciate(deps, do: body) do
          IO.inspect(deps)
          IO.inspect(body)
          instanciate_go(deps, body)
          |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
        end

        defmacro definstance(module, do: body) do
          body = instanciate_go([], body)
          quote do
            defmodule unquote(module) do
              unquote(body)
            end
          end
          |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
        end

        defmacro definstance(module, deps, do: body) do
          body = instanciate_go(deps, body)
          quote do
            defmodule unquote(module) do
              unquote(body)
            end
          end
          |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
        end

        def instanciate_go(deps, instance_body) do
          default_body = unquote(Macro.escape(default_body))

          unquote(deps_check_ast)
          
          deps_ast = Enum.map(deps, fn {name, module} ->
            quote do def unquote(name)(), do: unquote(module) end
          end)

          quote do
            use Socle.Meta.Curry

            unquote(deps_ast)

            unquote(default_body)

            unquote(instance_body)
          end
        end
      end
    end
    #|> case do x -> _ = IO.puts("#{__MODULE__}.define : #{Macro.to_string(x)}") ; x end
  end
end
