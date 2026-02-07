defmodule Fsrs.MixProject do
  use Mix.Project

  def project do
    [
      app: :fsrs_ex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: "https://github.com/lulucatdev/fsrs_ex",
      homepage_url: "https://github.com/lulucatdev/fsrs_ex",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "FSRS (Free Spaced Repetition Scheduler) implementation for Elixir."
  end

  defp package do
    [
      name: "fsrs_ex",
      maintainers: ["lulucatdev"],
      licenses: ["MIT"],
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
        "test/fixtures/generate_py_fixture.py",
        "test/fixtures/py_fsrs_v6_3_0_fixture.json"
      ],
      links: %{
        "GitHub" => "https://github.com/lulucatdev/fsrs_ex",
        "Py-FSRS" => "https://github.com/open-spaced-repetition/py-fsrs",
        "FSRS Algorithm Wiki" =>
          "https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm",
        "Jarrett Ye (X)" => "https://x.com/JarrettYe"
      }
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
