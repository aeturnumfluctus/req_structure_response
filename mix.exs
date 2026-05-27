defmodule ReqStructureResponse.MixProject do
  use Mix.Project

  def project do
    [
      app: :req_structure_response,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
