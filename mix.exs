defmodule HuiMon.MixProject do
  use Mix.Project

  def project do
    [
      app: :hui_mon,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HuiMon.Application, name: :default_solr}
    ]
  end

  defp aliases, do: [test: "test --no-start"]

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bypass, "~> 2.1", only: :test},
      {:hammox, "~> 0.5", only: :test},
      {:hui, "~> 0.10.5"},
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host}
    ]
  end
end
