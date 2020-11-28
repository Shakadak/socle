defmodule Socle.Meta.Curry do
  defmacro __using__(_opts) do
    quote do
      @before_compile {unquote(__MODULE__), :before_compile_curry}

      import unquote(__MODULE__), only: [defcurried: 2, defoverridable_curried: 2]
    end
  end

  defmacro before_compile_curry(_env) do
    curried_accumulator = Module.get_attribute(__CALLER__.module, :defcurried_accumulator, [])
    overridable_accumulator = Module.get_attribute(__CALLER__.module, :defoverridable_curried_accumulator, [])
    _ = Module.delete_attribute(__CALLER__.module, :defcurried_accumulator)
    _ = Module.delete_attribute(__CALLER__.module, :defoverridable_curried_accumulator)

    functions =
      Enum.reverse(curried_accumulator)
      |> Enum.map(fn {call, body} -> {name_x_arity(call), call, body} end)
      |> Enum.chunk_by(fn {name_x_arity, _call, _body} -> name_x_arity end)
      |> Enum.map(fn xs -> Enum.group_by(xs, fn {name_x_arity, _call, _body} -> name_x_arity end, fn {_name_x_arity, call, body} -> {call, body} end) end)
      |> Enum.map(&Enum.to_list/1)
      |> Enum.map(fn [x] -> x end)

    names = MapSet.new(functions, fn {nxa, _} -> elem(nxa, 0) end)

    overridable_functions =
      Enum.reverse(overridable_accumulator)
      |> Enum.filter(fn {call, _} -> not (elem(name_x_arity(call), 0) in names) end)
      |> Enum.map(fn {call, body} -> {name_x_arity(call), call, body} end)
      |> Enum.chunk_by(fn {name_x_arity, _call, _body} -> name_x_arity end)
      |> Enum.map(fn xs -> Enum.group_by(xs, fn {name_x_arity, _call, _body} -> name_x_arity end, fn {_name_x_arity, call, body} -> {call, body} end) end)
      |> Enum.map(&Enum.to_list/1)
      |> Enum.map(fn [x] -> x end)

    Enum.concat(functions, overridable_functions)
    |> Enum.flat_map(fn
      {{_, 0}, defs} ->
        Enum.map(defs, fn {call, body} ->
          quote do
            def unquote(call) do
              unquote(body)
            end
          end
        end)

      {{name, arity}, defs} ->
      proto_args = Enum.map(1..arity, fn n -> {:"arg#{n}", [], nil} end)
      body = to_body(proto_args, defs)
      defs = Enum.flat_map(arity..0, fn n ->
        case Enum.split(proto_args, n) do
          {_args, []} ->
            Enum.map(defs, fn {call, body} ->
              quote do
                def unquote(call) do
                  unquote(body)
                end
              end
            end)

          {args, following_args} ->
            body = List.foldr(following_args, body, fn arg, body -> quote do: fn unquote(arg) -> unquote(body) end end)
            [quote do
              def unquote({name, [], args}) do
                unquote(body)
              end
            end]
        end
      end)

      defs
    end)
    |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  def name_x_arity({:when, _, [{name, _, args} | _ ]}), do: {name, Enum.count(args)}
  def name_x_arity({name, _metadata, args}), do: {name, Enum.count(args)}

  def to_body(proto_args, defs) do
    clauses = Enum.flat_map(defs, fn {call, body} ->
      stripped_call = case call do
        {:when, metadata, [{_name, _, args} | guards]} ->
          as_tuple = quote do: {unquote_splicing(args)}
          {:when, metadata, [as_tuple | guards]}

        {_name, _, args} ->
          quote do: {unquote_splicing(args)}
      end

      quote do
        unquote(stripped_call) -> unquote(body)
      end
    end)

    quote do
      case {unquote_splicing(proto_args)} do
        unquote(clauses)
      end
    end
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  defmacro defcurried(call, do: body)do
    call = case call do
      {name, meta, nil} -> {name, meta, []}
      call -> call
    end
    attribute = :defcurried_accumulator
    _ = Module.register_attribute(__CALLER__.module, attribute, accumulate: true)
    _ = Module.put_attribute(__CALLER__.module, attribute, {call, body})
  end

  defmacro defoverridable_curried(call, do: body)do
    call = case call do
      {name, meta, nil} -> {name, meta, []}
      call -> call
    end
    attribute = :defoverridable_curried_accumulator
    _ = Module.register_attribute(__CALLER__.module, attribute, accumulate: true)
    _ = Module.put_attribute(__CALLER__.module, attribute, {call, body})
  end
end
