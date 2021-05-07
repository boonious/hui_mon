defmodule HuiMon.MixProject do
  use Mix.Project

  def project do
    [
      app: :hui_mon,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HuiMon.Application, name: :default_solr}
    ]
  end

  defp deps do
    [
      {:bypass, "~> 2.1", only: :test},
      {:hui, "~> 0.10.5"}
    ]
  end
end
