defmodule DeeperHubTest do
  use ExUnit.Case
  doctest DeeperHub

  test "greets the world" do
    assert DeeperHub.hello() == :world
  end
end
