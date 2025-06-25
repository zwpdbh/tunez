defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation

  # This will be executed in elixir
  @impl true
  def calculate(tracks, _opts, _context) do
    Enum.map(tracks, fn %{duraiton_second: duration} ->
      seconds =
        rem(duration, 60)
        |> Integer.to_string()
        |> String.pad_leading(2, "0")

      "#{div(duration, 60)}:#{seconds}"
    end)
  end

  # To use an expression in a calculation module,it will be executed in postgres
  @impl true
  def expression(_opts, _context) do
    expr(
      fragment("? / 60 || to_char(? * interval '1s', ':SS')", duration_seconds, duration_seconds)
    )
  end
end
