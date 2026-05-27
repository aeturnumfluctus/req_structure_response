defmodule ReqStructureResponseTest do
  use ExUnit.Case, async: true

  defmodule User do
    defstruct [:name, :email, :age]
  end

  describe "attach/2" do
    test "passes response through unchanged when :apply_structure is nil" do
      req = Req.new(plug: {Req.Test, __MODULE__}) |> ReqStructureResponse.attach()

      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{name: "Alice"})
      end)

      resp = Req.get!(req)
      assert resp.body == %{"name" => "Alice"}
    end

    test "applies the :apply_structure function to the response body" do
      req =
        Req.new(plug: {Req.Test, __MODULE__})
        |> ReqStructureResponse.attach(apply_structure: &Map.put(&1, "extra", true))

      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{name: "Alice"})
      end)

      resp = Req.get!(req)
      assert resp.body == %{"name" => "Alice", "extra" => true}
    end

    test "returns an error when :apply_structure is not a 1-arity function" do
      req =
        Req.new(plug: {Req.Test, __MODULE__})
        |> ReqStructureResponse.attach(apply_structure: :not_a_function)

      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{ok: true})
      end)

      assert {:error, %ArgumentError{message: msg}} = Req.get(req)
      assert msg =~ "expected 1-arity function"
    end

    test "returns an error when the :apply_structure function raises" do
      req =
        Req.new(plug: {Req.Test, __MODULE__})
        |> ReqStructureResponse.attach(apply_structure: fn _ -> raise "boom" end)

      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{ok: true})
      end)

      assert {:error, %RuntimeError{message: "boom"}} = Req.get(req)
    end
  end

  describe "into/1 with a module" do
    test "converts a map with string keys into a struct" do
      fun = ReqStructureResponse.into(User)

      assert fun.(%{"name" => "Bob", "email" => "bob@example.com"}) == %User{
               name: "Bob",
               email: "bob@example.com"
             }
    end

    test "converts a map with atom keys into a struct" do
      fun = ReqStructureResponse.into(User)
      assert fun.(%{name: "Bob", age: 30}) == %User{name: "Bob", age: 30}
    end

    test "ignores keys not in the struct" do
      fun = ReqStructureResponse.into(User)
      assert fun.(%{"name" => "Bob", "unknown_field" => "ignored"}) == %User{name: "Bob"}
    end

    test "raises for a module that is not a struct" do
      assert_raise ArgumentError, ~r/is not a struct/, fn ->
        ReqStructureResponse.into(Enum)
      end
    end

    test "raises for a module that cannot be loaded" do
      assert_raise ArgumentError, ~r/could not be loaded/, fn ->
        ReqStructureResponse.into(NoSuchModule)
      end
    end
  end

  describe "into/1 with a list" do
    test "converts a list of maps into a list of structs" do
      fun = ReqStructureResponse.into([User])
      result = fun.([%{"name" => "A"}, %{"name" => "B"}])
      assert result == [%User{name: "A"}, %User{name: "B"}]
    end
  end

  describe "into/2 with unwrap" do
    test "unwraps a key before applying structure" do
      fun = ReqStructureResponse.into([User], unwrap: "data")
      body = %{"data" => [%{"name" => "Alice"}, %{"name" => "Bob"}]}
      assert fun.(body) == [%User{name: "Alice"}, %User{name: "Bob"}]
    end

    test "raises KeyError when unwrap key is missing" do
      fun = ReqStructureResponse.into([User], unwrap: "results")
      assert_raise KeyError, fn -> fun.(%{"data" => []}) end
    end
  end

  describe "integration with Req" do
    test "into/1 works end-to-end via attach" do
      req =
        Req.new(plug: {Req.Test, __MODULE__})
        |> ReqStructureResponse.attach(apply_structure: ReqStructureResponse.into(User))

      Req.Test.stub(__MODULE__, fn conn ->
        Req.Test.json(conn, %{name: "Carol", email: "carol@test.com"})
      end)

      resp = Req.get!(req)
      assert %User{name: "Carol", email: "carol@test.com"} = resp.body
    end
  end
end
