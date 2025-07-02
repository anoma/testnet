defmodule Anoma.Ethereum do
  @moduledoc """
  Contains functionality to verify signed messages coming from MetaMask.
  """

  @doc """
  Verify a signed message from metamask.
  Checks if the given address is the one that signed the message.
  """
  @spec verify(String.t(), String.t(), String.t()) :: boolean()
  def verify(message, signature, expected_address) do
    # downcase all inputs
    signature = String.downcase(signature)
    expected_address = String.downcase(expected_address)

    # strip the prefix from the signature
    signature = String.replace_leading(signature, "0x", "")

    # add the metamask prefix to the message that was signed
    prefix = "\x19Ethereum Signed Message:\n" <> Integer.to_string(byte_size(message))
    message = prefix <> message

    with {r, s, v} <- extract_signature_components(signature),
         message_hash <- ExKeccak.hash_256(message),
         {:ok, public_key} <- recover_public_key(message_hash, r, s, v) do
      # 6. Derive the address from the public key
      address = public_key_to_address(public_key)

      String.downcase(address) == String.downcase(expected_address)
    else
      _ ->
        false
    end
  end

  # Extract r, s, v components from signature
  @spec extract_signature_components(String.t()) :: {binary(), binary(), integer()}
  defp extract_signature_components(sig) do
    r = String.slice(sig, 0..63) |> Base.decode16!(case: :mixed)
    s = String.slice(sig, 64..127) |> Base.decode16!(case: :mixed)

    # The v value might be represented differently based on the signature format
    v_hex = String.slice(sig, 128..-1//1)
    # Convert hex to integer
    v = String.to_integer(v_hex, 16)

    # Handle different v encodings (some implementations add 27)
    v = if v < 27, do: v + 27, else: v

    {r, s, v}
  end

  # Recover public key from signature components
  @spec recover_public_key(binary(), binary(), binary(), integer()) ::
          {:ok, binary()} | {:error, term()}
  defp recover_public_key(message_hash, r, s, v) do
    # This is the complex part that requires implementing the secp256k1 ECDSA recovery
    # We need to use :crypto.verify functions with the right parameters

    # Note: In a real implementation, you would need to call the actual elliptic curve recovery function
    # This is a placeholder for the actual implementation
    # :crypto.ec_public_key_recover(message_hash, {r, s, v}, :secp256k1)
    v = v - 27
    ExSecp256k1.recover(message_hash, r, s, v)
  end

  # Derive address from public key
  @spec public_key_to_address(binary()) :: String.t()
  defp public_key_to_address(public_key) do
    # Remove the first byte (0x04) which indicates uncompressed point format
    key_without_prefix = binary_part(public_key, 1, byte_size(public_key) - 1)

    # Take the keccak256 hash and use the last 20 bytes as the address
    "0x" <>
      (ExKeccak.hash_256(key_without_prefix)
       |> binary_part(12, 20)
       |> Base.encode16(case: :lower))
  end
end
