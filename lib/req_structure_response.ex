defmodule ReqStructureResponse do
  @moduledoc """
  [Req](https://github.com/wojtekmach/req) plugin for applying structure to
  response bodies.

  ## Request Options

  * `:apply_structure` - a 1-arity function that transforms the response body.
    When `nil` (the default), the response is returned unchanged. See `into/2`
    for a convenient helper that converts map bodies into structs.

  > #### Order Matters! {: .info}
  >
  > By default, `apply_structure/1` runs as the **FINAL** response step.

  > #### Sensitive Response Data {: .warning}
  >
  > This step returns `ReqStructureResponse.ApplyStructureError` which contains the
  > full `Req.Response`. Since response headers/body can contain sensitive data, be
  > careful about raising this error and automatically logging it, sending to
  > exception trackers, etc.

  """

  @type unwrap_option :: String.t() | atom()

  @spec attach(Req.Request.t(), keyword()) :: Req.Request.t()
  def attach(request, options \\ []) do
    request
    |> Req.Request.register_options([:apply_structure])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_response_steps(apply_structure: &apply_structure/1)
  end

  defp apply_structure({request, response}) do
    case request.options[:apply_structure] do
      nil ->
        {request, response}

      fun when is_function(fun, 1) ->
        try do
          {request, %{response | body: fun.(response.body)}}
        rescue
          e -> {request, apply_structure_exception(response, fun, e)}
        end

      bad ->
        {request, %ArgumentError{message: "expected 1-arity function, got: #{inspect(bad)}"}}
    end
  end

  defp validate_struct_module!(module) do
    cond do
      not is_atom(module) ->
        raise ArgumentError, "expected a module, got: #{inspect(module)}"

      not Code.ensure_loaded?(module) ->
        raise ArgumentError, "module #{inspect(module)} could not be loaded"

      not function_exported?(module, :__struct__, 0) ->
        raise ArgumentError, "module #{inspect(module)} is not a struct"

      true ->
        module
    end
  end

  defp struct_from_body(module, body) when is_map(body) do
    fields = module.__struct__() |> Map.keys() |> MapSet.new()

    body
    |> Enum.flat_map(fn
      {k, v} when is_atom(k) ->
        if k in fields, do: [{k, v}], else: []

      {k, v} when is_binary(k) ->
        atom =
          try do
            String.to_existing_atom(k)
          rescue
            ArgumentError -> nil
          end

        if atom && atom in fields, do: [{atom, v}], else: []
    end)
    |> then(&struct(module, &1))
  end

  @doc """
  Returns a function that converts a response body into a struct (or list of structs).

  ## Variants

  * `into(Module)` — returns a 1-arity function that converts a map body into
    a `%Module{}` struct. String keys are converted to existing atoms and matched
    against the struct's fields; unknown keys are silently dropped.

  * `into([Module])` — same as above but expects the body to be a list of maps,
    returning a list of structs.

  Raises `ArgumentError` if `module` cannot be loaded or is not a struct.
  """
  @spec into(module() | [module()]) :: (map() | [map()] -> struct() | [struct()])
  def into(module) when is_atom(module) do
    validate_struct_module!(module)
    &struct_from_body(module, &1)
  end

  def into([module]) when is_atom(module) do
    validate_struct_module!(module)
    fn body when is_list(body) -> Enum.map(body, &struct_from_body(module, &1)) end
  end

  @doc """
  Like `into/1`, but first extracts a nested key from the response body.

  Useful when the API wraps the data in an envelope, e.g. `%{"data" => [...]}`.
  """
  @spec into(module() | [module()], unwrap: unwrap_option()) ::
          (map() -> struct() | [struct()])
  def into(module, unwrap: key) do
    inner = into(module)
    fn body -> body |> Map.fetch!(key) |> inner.() end
  end

  defp apply_structure_exception(response, fun, error) do
    ReqStructureResponse.ApplyStructureError.exception(
      constructor: fun,
      response: response,
      error: error
    )
  end
end
