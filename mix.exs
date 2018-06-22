defmodule PlusCodes.MixProject do
  use Mix.Project

  def project do
    [
      app: :plus_codes,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "1.0.0-rc.2", runtime: false, only: [:dev]},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end
end
