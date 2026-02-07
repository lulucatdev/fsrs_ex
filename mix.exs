defmodule Fsrs.MixProject do
  use Mix.Project

  def project do
    version = "0.1.1"

    [
      app: :fsrs_ex,
      version: version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: "https://github.com/lulucatdev/fsrs_ex",
      homepage_url: "https://github.com/lulucatdev/fsrs_ex",
      docs: [
        main: "readme",
        source_ref: "v#{version}",
        extras: [
          "README.md",
          "guides/PORTING_POLICY.md",
          "guides/PARITY_TESTING.md",
          "guides/RELEASE_PROCESS.md",
          "LICENSE"
        ],
        groups_for_extras: [
          Guides: Path.wildcard("guides/*.md")
        ],
        groups_for_modules: [
          "Core API": [Fsrs, Fsrs.Scheduler, Fsrs.Card, Fsrs.ReviewLog],
          "Enums & Constants": [Fsrs.Rating, Fsrs.State, Fsrs.Constants]
        ]
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
    "Direct Elixir port of open-spaced-repetition/py-fsrs (FSRS-6)."
  end

  defp package do
    [
      name: "fsrs_ex",
      maintainers: ["lulucatdev"],
      licenses: ["MIT"],
      files: [
        "lib",
        "guides",
        "mix.exs",
        "Makefile",
        "llms.txt",
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
