defmodule Rpi4MouseTest do
  use ExUnit.Case
  doctest Rpi4Mouse

  test "greets the world" do
    assert Rpi4Mouse.hello() == :world
  end
end
