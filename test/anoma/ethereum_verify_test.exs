defmodule Anoma.EthereumTest do
  use ExUnit.Case, async: true

  alias Anoma.Ethereum

  describe "verify/3" do
    test "verifies a valid signature correctly" do
      message = "foobar"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      assert Ethereum.verify(message, signature, address)
    end

    test "handles uppercase addresses correctly" do
      message = "foobar"
      address = "0X514327FEED51353DC2ABEFAE9CB5CCF96D1B9E89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      assert Ethereum.verify(message, signature, address)
    end

    test "handles mixed case messages correctly" do
      message = "FooBar"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end

    test "handles signature with 0x prefix" do
      message = "foobar"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      assert Ethereum.verify(message, signature, address)
    end

    test "handles signature without 0x prefix" do
      message = "foobar"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      assert Ethereum.verify(message, signature, address)
    end

    test "rejects invalid signature for given address" do
      message = "foobar"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"
      # Modified signature (changed last character)
      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1d"

      refute Ethereum.verify(message, signature, address)
    end

    test "rejects valid signature with wrong address" do
      message = "foobar"
      # Different address
      address = "0x1234567890abcdef1234567890abcdef12345678"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end

    test "rejects signature for different message" do
      # Different message
      message = "different message"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end

    test "handles empty message" do
      message = ""
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end

    test "handles unicode characters in message" do
      message = "hello L"
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end

    test "handles very long message" do
      message = String.duplicate("a", 1000)
      address = "0x514327feed51353dc2abefae9cb5ccf96d1b9e89"

      signature =
        "0x81e62cf94b92823280f1cdf8971aa2cfdc8b70690c3d0b628a215c8b0c54091f4eb4749c1c57f6e81417a643b489aea63ab27d88b46b233c828ba806c1bff07a1c"

      refute Ethereum.verify(message, signature, address)
    end
  end
end
