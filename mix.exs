defmodule ReqStructureResponse.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/aeturnumfluctus/req_structure_response"

  def project do
    [
      app: :req_structure_response,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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

  defp package do
    [
      description: "Req plugin for applying structure to response bodies.",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Josh Adams"]
    ]
  end
end
