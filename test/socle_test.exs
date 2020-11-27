defmodule SocleTest do
  use ExUnit.Case
  doctest Socle

  test "greets the world" do
    assert Socle.hello() == :world
  end
end
