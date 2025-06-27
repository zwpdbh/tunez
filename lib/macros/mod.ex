# it’s important to be aware of what context a macro
# is executing in and to respect hygiene.
defmodule Macros.Mod do
  defmacro definfo do
    IO.puts("In macros's context (#{__MODULE__})")

    quote do
      IO.puts("In caller's context (#{__MODULE__})")

      def friendly_info do
        IO.puts("""
        My name is #{__MODULE__}
        My function are #{inspect(__MODULE__.__info__(:functions))}
        """)
      end
    end
  end
end
