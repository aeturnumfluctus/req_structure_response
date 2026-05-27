[![CI](https://github.com/aeturnumfluctus/req_structure_response/actions/workflows/ci.yml/badge.svg)](https://github.com/aeturnumfluctus/req_structure_response/actions/workflows/ci.yml)

# ReqStructureResponse

[Req](https://github.com/wojtekmach/req) plugin for applying structure to
response bodies.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `req_structure_response` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:req_structure_response, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
Mix.install([
  {:req, "~> 0.5.0"},
  {:req_structure_response, "~> 0.1.0"}
])

defmodule SomeStructure do
  defstruct [:slideshow]
end

req = Req.new() |> ReqStructureResponse.attach()

#-- passing an anonymous function
Req.get!(req, url: "https://httpbin.org/json", apply_structure: fn body ->
  %SomeStructure{slideshow: body["slideshow"]}
end).body
#=> %SomeStructure{...}

#-- ReqStructureResponse.into/1

Req.get!(req, url: "https://httpbin.org/json", apply_structure: ReqStructureResponse.into(SomeStructure)).body
#=> %SomeStructure{...}
```

## Misc.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/req_structure_response>.

## License

Copyright (c) 2026 Joshua Adams

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
