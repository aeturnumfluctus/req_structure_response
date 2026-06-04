defmodule ReqStructureResponse.ApplyStructureError do
  @moduledoc """
  An exception returned when applying structure to a response fails.

  The public fields are:

    * `:constructor` - the 1-arity function passed as `:apply_structure`

    * `:error` - the error that occurred when construction was attempted

    * `:response` - the HTTP response
  """

  defexception [:constructor, :error, :response]

  @impl true
  def message(%{constructor: constructor, error: error, response: response}) do
    """
    Failed to apply structure!

    Attempting to apply constructor:
    #{inspect(constructor)}

    using the given response body:
    #{inspect(response.body, pretty: true)}

    resulted in the following error:
    #{inspect(error)}
    """
  end
end
