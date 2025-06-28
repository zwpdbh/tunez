defmodule Macros.Playground do
  require Macros.Loop
  import Macros.Loop

  def case03_generate_loop do
    spawn(fn ->
      while true do
        receive do
          :stop ->
            IO.puts("Stopping")
            break()

          message ->
            IO.puts("Got #{inspect(message)}")
        end
      end
    end)
  end
end

# when compile it it output:
# Compiling 2 files (.ex)
# In macros's context (Elixir.Macros.Mod)
# In caller's context (Elixir.MyModule)
defmodule MyModule do
  require Macros.Mod
  Macros.Mod.definfo()
end

defmodule MathTest do
  use Assertion

  # the `run` function is available because it
  # is injected from Assertion

  test "integers can be added and subtracted" do
    assert 1 + 1 == 2
    assert 2 + 3 == 5
    assert 5 - 5 == 10
  end

  def demo() do
    MathTest.run()
  end
end
