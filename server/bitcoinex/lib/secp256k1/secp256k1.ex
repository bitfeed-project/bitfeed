defmodule Bitcoinex.Secp256k1 do
  @moduledoc """
  ECDSA Secp256k1 curve operations.
  libsecp256k1: https://github.com/bitcoin-core/secp256k1

  Currently supports ECDSA public key recovery.

  In the future, we will NIF for critical operations. However, it is more portable to have a native elixir version.
  """
  use Bitwise, only_operators: true
  alias Bitcoinex.Secp256k1.{Math, Params, Point}

  @generator_point %Point{
    x: Params.curve().g_x,
    y: Params.curve().g_y
  }

  defmodule Signature do
    @moduledoc """
    Contains r,s in signature.
    """

    @type t :: %__MODULE__{
            r: pos_integer(),
            s: pos_integer()
          }

    @enforce_keys [
      :r,
      :s
    ]
    defstruct [:r, :s]

    @spec parse_signature(binary) ::
            {:ok, t()} | {:error, String.t()}
    @doc """
    accepts a compact signature and returns a Signature containing r,s
    """
    def parse_signature(<<r::binary-size(32), s::binary-size(32)>>) do
      # Get r,s from signature.
      r = :binary.decode_unsigned(r)
      s = :binary.decode_unsigned(s)

      # Verify that r,s are integers in [1, n-1] where n is the integer order of G.
      cond do
        r < 1 ->
          {:error, "invalid signature"}

        r > Params.curve().n - 1 ->
          {:error, "invalid signature"}

        s < 1 ->
          {:error, "invalid signature"}

        s > Params.curve().n - 1 ->
          {:error, "invalid signature"}

        true ->
          {:ok, %Signature{r: r, s: s}}
      end
    end

    def parse_signature(compact_sig) when is_binary(compact_sig),
      do: {:error, "invalid signature size"}
  end

  @doc """
  ecdsa_recover_compact does ECDSA public key recovery.
  """
  @spec ecdsa_recover_compact(binary, binary, integer) ::
          {:ok, binary} | {:error, String.t()}
  def ecdsa_recover_compact(msg, compact_sig, recoveryId) do
    # Parse r and s from the signature.
    case Signature.parse_signature(compact_sig) do
      {:ok, sig} ->
        # Find the iteration.

        # R(x) = (n * i) + r
        # where n is the order of the curve and R is from the signature.
        r_x = Params.curve().n * Integer.floor_div(recoveryId, 2) + sig.r

        # Check that R(x) is on the curve.
        if r_x > Params.curve().p do
          {:error, "R(x) is not on the curve"}
        else
          # Decompress to get R(y).
          case get_y(r_x, rem(recoveryId, 2) == 1) do
            {:ok, r_y} ->
              # R(x,y)
              point_r = %Point{x: r_x, y: r_y}

              # Point Q is the recovered public key.
              # We satisfy this equation: Q = r^-1(sR-eG)
              inv_r = Math.inv(sig.r, Params.curve().n)
              inv_r_s = (inv_r * sig.s) |> Math.modulo(Params.curve().n)

              # R*s
              point_sr = Math.multiply(point_r, inv_r_s)

              # Find e using the message hash.
              e =
                :binary.decode_unsigned(msg)
                |> Kernel.*(-1)
                |> Math.modulo(Params.curve().n)
                |> Kernel.*(inv_r |> Math.modulo(Params.curve().n))

              # G*e
              point_ge = Math.multiply(@generator_point, e)

              # R*e * G*e
              point_q = Math.add(point_sr, point_ge)

              # Returns serialized compressed public key.
              {:ok, Point.serialize_public_key(point_q)}

            {:error, error} ->
              {:error, error}
          end
        end

      {:error, e} ->
        {:error, e}
    end
  end

  @doc """
  Returns the y-coordinate of a secp256k1 curve point (P) using the x-coordinate.
  To get P(y), we solve for y in this equation: y^2 = x^3 + 7.
  """
  @spec get_y(integer, boolean) :: {:ok, integer} | {:error, String.t()}
  def get_y(x, is_y_odd) do
    # x^3 + 7
    y_sq =
      :crypto.mod_pow(x, 3, Params.curve().p)
      |> :binary.decode_unsigned()
      |> Kernel.+(7 |> Math.modulo(Params.curve().p))

    # Solve for y.
    y =
      :crypto.mod_pow(y_sq, Integer.floor_div(Params.curve().p + 1, 4), Params.curve().p)
      |> :binary.decode_unsigned()

    y =
      case rem(y, 2) == 1 do
        ^is_y_odd ->
          y

        _ ->
          Params.curve().p - y
      end

    # Check.
    if y_sq != :crypto.mod_pow(y, 2, Params.curve().p) |> :binary.decode_unsigned() do
      {:error, "invalid sq root"}
    else
      {:ok, y}
    end
  end
end
