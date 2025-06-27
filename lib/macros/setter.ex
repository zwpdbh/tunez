defmodule Macros.Setter do
  defmacro bind_name(string) do
    quote do
      name = unquote(string)
    end
  end
end

defmodule Macros.SetterOverwriteCaller do
  defmacro bind_name(string) do
    quote do
      # By using var!, we were able to override hygiene to rebind name to a new value.
      var!(name) = unquote(string)
    end
  end
end
