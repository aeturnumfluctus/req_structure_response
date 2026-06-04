defmodule ReqStructureResponse.ApplyStructureErrorTest do
  use ExUnit.Case, async: true

  alias ReqStructureResponse.ApplyStructureError

  describe "message/1" do
    test "includes constructor, body, and error details" do
      error =
        ApplyStructureError.exception(
          constructor: &Function.identity/1,
          response: %Req.Response{status: 200, body: %{"name" => "test"}},
          error: %RuntimeError{message: "oops"}
        )

      msg = Exception.message(error)
      assert msg =~ "Failed to apply structure!"
      assert msg =~ "response body"
      assert msg =~ "oops"
    end
  end
end
