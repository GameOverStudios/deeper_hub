[
  inputs: [
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "scripts/**/*.exs"
  ],
  line_length: 120,
  locals_without_parens: [
    # Phoenix
    plug: 1,
    plug: 2,
    forward: 2,
    forward: 3,
    forward: 4,
    pipe_through: 1,

    # Ecto
    field: 2,
    field: 3,
    belongs_to: 2,
    belongs_to: 3,
    has_one: 2,
    has_one: 3,
    has_many: 2,
    has_many: 3,
    many_to_many: 2,
    many_to_many: 3,

    # Guardian
    subject_for_token: 2,
    resource_from_claims: 1,

    # Telemetry
    execute: 2,
    execute: 3,

    # Custom
    require: 1,
    import: 1,
    import: 2,
    alias: 1,
    alias: 2
  ]
]
