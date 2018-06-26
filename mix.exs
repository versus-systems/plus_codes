defmodule PlusCodes.MixProject do
  use Mix.Project

  def project do
    [
      app: :plus_codes,
      version: "1.0.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "PlusCodes",
      source_url: "https://github.com/versus-systems/plus_codes"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "1.0.0-rc.2", runtime: false, only: [:dev]},
      {:ex_doc, "~> 0.16", only: [:dev], runtime: false}
    ]
  end

  defp description() do
    "An Elixir implemention of Google Open Location Code(Plus+Codes)"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE*"],
      maintainers: ["Alex Peachey, Versus Systems LLC"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/versus-systems/plus_codes"}
    ]
  end
end
