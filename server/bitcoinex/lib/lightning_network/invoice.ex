defmodule Bitcoinex.LightningNetwork.Invoice do
  @moduledoc """
  Includes BOLT#11 Invoice serialization.

  Reference: https://github.com/lightningnetwork/lightning-rfc/blob/master/11-payment-encoding.md
  """

  alias Bitcoinex.{Bech32, Network, Segwit}
  alias Bitcoinex.LightningNetwork.HopHint
  alias Decimal, as: D

  use Bitwise
  # consider using https://github.com/ejpcmac/typed_struct

  @default_min_final_cltv_expiry 18
  @default_expiry 3600

  @enforce_keys [:network, :destination, :payment_hash, :timestamp]
  defstruct [
    :network,
    :destination,
    :payment_hash,
    :amount_msat,
    :timestamp,
    :description,
    :description_hash,
    :fallback_address,
    route_hints: [],
    expiry: @default_expiry,
    min_final_cltv_expiry: @default_min_final_cltv_expiry
  ]

  @type t() :: %__MODULE__{
          network: Network.network_name(),
          destination: String.t(),
          payment_hash: String.t(),
          amount_msat: non_neg_integer | nil,
          timestamp: integer(),
          expiry: integer() | nil,
          # description and description_hash are either both non-nil or nil
          description: String.t() | nil,
          description_hash: String.t() | nil,
          fallback_address: String.t() | nil,
          min_final_cltv_expiry: non_neg_integer,
          route_hints: list(HopHint.t())
        }

  @prefix "ln"
  @valid_multipliers ~w(m u n p)
  # TODO move it to bitcoin asset?
  @milli_satoshi_per_bitcoin 100_000_000_000
  # the 512 bit signature + 8 bit recovery ID.
  @signature_base32_length 104
  @timestamp_base32_length 7
  @sha256_hash_base32_length 52
  @pubkey_base32_length 53
  @hop_hint_length 51
  @type error :: atom

  @doc """
   Decode accepts a Bech32 encoded string invoice and deserializes it.
  """
  @spec decode(String.t()) :: {:ok, t} | {:error, error}
  def decode(invoice) when is_binary(invoice) do
    with {:ok, {_encoding_type, hrp, data}} <- Bech32.decode(invoice, :infinity),
         {:ok, {network, amount_msat}} <- parse_hrp(hrp),
         {invoice_data, signature_data} = split_at(data, -@signature_base32_length),
         {:ok, parsed_data} <-
           parse_invoice_data(invoice_data, network),
         {:ok, destination} <-
           validate_and_parse_signature_data(
             Map.get(parsed_data, :destination),
             hrp,
             invoice_data,
             signature_data
           ) do
      __MODULE__
      |> struct(
        Map.merge(
          parsed_data,
          %{
            network: network,
            amount_msat: amount_msat,
            destination: destination
          }
        )
      )
      |> validate_invoice()
    end
  end

  def decode(invoice) when is_binary(invoice) do
    {:error, :no_ln_prefix}
  end

  @doc """
   Returns the expiry of the invoice.
  """
  @spec expires_at(Bitcoinex.LightningNetwork.Invoice.t()) :: DateTime.t()
  def expires_at(%__MODULE__{} = invoice) do
    expiry = invoice.expiry
    Timex.from_unix(invoice.timestamp + expiry, :second)
  end

  # checking some invariant for invoice
  # TODO Could we use ecto(without SQL) for this?
  defp validate_invoice(%__MODULE__{} = invoice) do
    cond do
      is_nil(invoice.network) ->
        {:error, :network_missing}

      !is_nil(invoice.amount_msat) && invoice.amount_msat < 0 ->
        {:error, :negative_amount_msat}

      is_nil(invoice.payment_hash) ->
        {:error, :payment_hash_missing}

      is_nil(invoice.description) && is_nil(invoice.description_hash) ->
        {:error, :both_description_and_description_hash_present}

      !is_nil(invoice.description) && !is_nil(invoice.description_hash) ->
        {:error, :both_description_and_description_hash_missing}

      # lnd have this but not in Bolt11. do we need to enforce this?
      Enum.count(invoice.route_hints) > 20 ->
        {:error, :too_many_private_routes}

      String.length(invoice.payment_hash) != 64 ->
        {:error, :invalid_payment_hash_length}

      !is_nil(invoice.description_hash) && String.length(invoice.description_hash) != 64 ->
        {:error, :invalid_payment_hash}

      # String.length(invoice.destination) != 64 ->
      #   {:error, :invalid_destination_length}

      true ->
        {:ok, invoice}
    end
  end

  defp validate_and_parse_signature_data(destination, hrp, invoice_data, signature_data)
       when is_list(invoice_data) and is_list(signature_data) do
    with {:ok, signature_data_in_byte} <- Bech32.convert_bits(signature_data, 5, 8),
         {signature, [recoveryId]} = split_at(signature_data_in_byte, -1),
         {:ok, invoice_data_in_byte} <- Bech32.convert_bits(invoice_data, 5, 8) do
      to_sign = (hrp |> :erlang.binary_to_list()) ++ invoice_data_in_byte
      signature = signature |> byte_list_to_binary
      hash = to_sign |> Bitcoinex.Utils.sha256()

      # TODO if destination exist from tagged field, we dun need to recover but to verify it with signature
      # but that require convert lg sig before using secp256k1 to verify it
      # TODO refactor too nested
      case Bitcoinex.Secp256k1.ecdsa_recover_compact(hash, signature, recoveryId) do
        {:ok, pubkey} ->
          if is_nil(destination) or destination == pubkey do
            {:ok, pubkey}
          else
            {:error, :invalid_invoice_signature}
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp parse_invoice_data(data, network) when is_list(data) do
    {timstamp_data, tagged_fields_data} = split_at(data, @timestamp_base32_length)

    with {:ok, timestamp} <- parse_timestamp(timstamp_data),
         {:ok, parsed_data} <-
           parse_tagged_fields(tagged_fields_data, network) do
      {:ok, Map.put(parsed_data, :timestamp, timestamp)}
    end
  end

  defp parse_tagged_fields(data, network) when is_list(data) do
    do_parse_tagged_fields(data, %{}, network)
  end

  defp do_parse_tagged_fields([type, data_length1, data_length2 | rest], acc, network) do
    data_length = data_length1 <<< 5 ||| data_length2

    if Enum.count(rest) < data_length do
      {:error, :invalid_field_length}
    else
      {data, new_rest} = split_at(rest, data_length)

      case(parse_tagged_field(type, data, acc, network)) do
        {:ok, acc} ->
          do_parse_tagged_fields(new_rest, acc, network)

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp do_parse_tagged_fields(_, acc, _network) do
    {:ok, acc}
  end

  defp parse_tagged_field(type, data, acc, network) do
    case type do
      1 ->
        if Map.has_key?(acc, :payment_hash) do
          {:ok, acc}
        else
          case parse_payment_hash(data) do
            {:ok, payment_hash} ->
              {:ok, Map.put(acc, :payment_hash, payment_hash)}

            {:error, error} ->
              {:error, error}
          end
        end

      # r field HopHints
      3 ->
        if Map.has_key?(acc, :route_hints) do
          {:ok, acc}
        else
          case parse_hop_hints(data) do
            {:ok, hop_hints} ->
              {:ok, Map.put(acc, :route_hints, hop_hints)}

            {:error, error} ->
              {:error, error}
          end
        end

      # x field
      6 ->
        if Map.has_key?(acc, :expiry) do
          {:ok, acc}
        else
          expiry = parse_expiry(data)
          {:ok, Map.put(acc, :expiry, expiry)}
        end

      # f field fallback address
      9 ->
        if Map.has_key?(acc, :fallback_address) do
          {:ok, acc}
        else
          case parse_fallback_address(data, network) do
            {:ok, fallback_address} ->
              {:ok, Map.put(acc, :fallback_address, fallback_address)}

            {:error, error} ->
              {:error, error}
          end
        end

      # d field
      13 ->
        if Map.has_key?(acc, :description) do
          {:ok, acc}
        else
          case parse_description(data) do
            {:ok, description} ->
              {:ok, Map.put(acc, :description, description)}

            {:error, error} ->
              {:error, error}
          end
        end

      # n field destination
      19 ->
        case acc do
          %{destination: destination} when destination != nil ->
            {:ok, acc}

          _ ->
            case parse_destination(data) do
              {:ok, destination} ->
                {:ok, Map.put(acc, :destination, destination)}

              {:error, error} ->
                {:error, error}
            end
        end

      # h field description hash
      23 ->
        if Map.has_key?(acc, :description_hash) do
          {:ok, acc}
        else
          case parse_description_hash(data) do
            {:ok, description_hash} ->
              {:ok, Map.put(acc, :description_hash, description_hash)}

            {:error, error} ->
              {:error, error}
          end
        end

      # c field MINIMUM Fianl CLTV Expiry
      24 ->
        if Map.has_key?(acc, :min_final_cltv_expiry) do
          {:ok, acc}
        else
          min_final_cltv_expiry = parse_min_final_cltv_expiry(data)
          {:ok, Map.put(acc, :min_final_cltv_expiry, min_final_cltv_expiry)}
        end

      _ ->
        {:ok, acc}
    end
  end

  defp parse_timestamp(data) do
    {:ok, base32_to_integer(data)}
  end

  defp parse_payment_hash(data) when is_list(data) do
    if Enum.count(data) == @sha256_hash_base32_length do
      case Bech32.convert_bits(data, 5, 8, false) do
        {:ok, converted_data} ->
          {:ok, converted_data |> :binary.list_to_bin() |> Base.encode16(case: :lower)}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, :invalid_payment_hash_length}
    end
  end

  defp parse_description(data) do
    case Bech32.convert_bits(data, 5, 8, false) do
      {:ok, description} ->
        {:ok, :binary.list_to_bin(description)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_expiry(data) do
    base32_to_integer(data)
  end

  @spec base32_to_integer(maybe_improper_list()) :: any()
  def base32_to_integer(data) when is_list(data) do
    Enum.reduce(data, 0, fn val, acc ->
      acc <<< 5 ||| val
    end)
  end

  defp parse_destination(data) when is_list(data) do
    if Enum.count(data) == @pubkey_base32_length do
      case Bech32.convert_bits(data, 5, 8, false) do
        {:ok, data_in_bytes} ->
          {:ok, bytes_to_hex_string(data_in_bytes)}

        {:error, error} ->
          {:error, error}
      end
    else
      {:ok, nil}
    end
  end

  defp parse_description_hash(data) when is_list(data) do
    if Enum.count(data) == @sha256_hash_base32_length do
      case Bech32.convert_bits(data, 5, 8, false) do
        {:ok, data_in_bytes} ->
          {:ok, data_in_bytes |> bytes_to_hex_string}

        {:error, error} ->
          {:error, error}
      end
    else
      {:ok, nil}
    end
  end

  defp parse_fallback_address([], _network) do
    {:error, :empty_fallback_address}
  end

  defp parse_fallback_address([version | rest], network) do
    case version do
      0 ->
        case Bech32.convert_bits(rest, 5, 8, false) do
          {:ok, witness} ->
            case Enum.count(witness) do
              witness_program_lenghh when witness_program_lenghh in [20, 32] ->
                Segwit.encode_address(network, 0, witness)

              _ ->
                {:error, :invalid_witness_program_length}
            end

          err ->
            err
        end

      17 ->
        case Bech32.convert_bits(rest, 5, 8, false) do
          {:ok, pubKeyHash} ->
            {:ok,
             Bitcoinex.Address.encode(
               pubKeyHash |> :binary.list_to_bin(),
               network,
               :p2pkh
             )}

          err ->
            err
        end

      18 ->
        case Bech32.convert_bits(rest, 5, 8, false) do
          {:ok, scriptHash} ->
            {:ok,
             Bitcoinex.Address.encode(
               scriptHash |> :binary.list_to_bin(),
               network,
               :p2sh
             )}

          err ->
            err
        end

      # ignore unknown version
      _ ->
        {:ok, nil}
    end
  end

  defp parse_hop_hints(data) when is_list(data) do
    with {:ok, data_in_byte} <- Bech32.convert_bits(data, 5, 8, false),
         {_, true} <-
           {:validate_hop_hint_data_length, rem(Enum.count(data_in_byte), @hop_hint_length) == 0} do
      hop_hints =
        data_in_byte
        |> Enum.chunk_every(@hop_hint_length)
        |> Enum.map(&parse_hop_hint/1)

      {:ok, hop_hints}
    else
      {:validate_hop_hint_data_length, false} ->
        {:error, :invalid_hop_hint_data_length}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_integer_from_hex_str!(hex_str) do
    {hex_str, ""} = Integer.parse(hex_str, 16)
    hex_str
  end

  # exoect they are list of integer in byte
  defp parse_hop_hint(data) when is_list(data) do
    # 64 bits
    {node_id_data, rest} = data |> split_at(33)
    node_id = node_id_data |> bytes_to_hex_string
    # 64 bits
    {channel_id_data, rest} = rest |> split_at(8)
    channel_id = channel_id_data |> bytes_to_hex_string |> parse_integer_from_hex_str!
    # 32 bits
    {fee_base_m_sat_data, rest} = rest |> split_at(4)
    fee_base_m_sat = fee_base_m_sat_data |> bytes_to_hex_string |> parse_integer_from_hex_str!
    # 32 bits
    {fee_proportional_millionths_data, rest} = rest |> split_at(4)

    fee_proportional_millionths =
      fee_proportional_millionths_data |> bytes_to_hex_string |> parse_integer_from_hex_str!

    cltv_expiry_delta = rest |> bytes_to_hex_string |> parse_integer_from_hex_str!

    %HopHint{
      node_id: node_id,
      channel_id: channel_id,
      fee_base_m_sat: fee_base_m_sat,
      fee_proportional_millionths: fee_proportional_millionths,
      cltv_expiry_delta: cltv_expiry_delta
    }
  end

  defp parse_min_final_cltv_expiry(data) when is_list(data) do
    base32_to_integer(data)
  end

  # defp get_pubkey_to_address_magicbyte(network, script_type) do
  #   case {network, script_type} do
  #     {:mainnet, :p2pkh} ->
  #       0x00

  #     {:mainnet, :p2sh} ->
  #       0x05

  #     {network, :p2pkh} when network in [:testnet, :regtest] ->
  #       0x6F

  #     {network, :p2sh} when network in [:testnet, :regtest] ->
  #       0xC4
  #   end
  # end

  defp parse_network(@prefix <> rest_hrp) do
    case Enum.find(Network.supported_networks(), fn %{hrp_segwit_prefix: hrp_segwit_prefix} ->
           if String.starts_with?(rest_hrp, hrp_segwit_prefix) do
             size = bit_size(hrp_segwit_prefix)

             case rest_hrp do
               # without amount
               ^hrp_segwit_prefix ->
                 true

               # with amount. a valid segwit_prefix must be following with base10 digit
               # ?0..?9 means range of codepoint of 0 - 9
               # it shoudln't include 0 but that's not responsiblity of passing network function here
               <<_::size(size), i, _::binary>> when i in ?0..?9 ->
                 true

               _ ->
                 false
             end
           end
         end) do
      nil ->
        {:error, :invalid_network}

      network ->
        {:ok, network}
    end
  end

  defp parse_hrp(hrp) do
    with {_, @prefix <> rest_hrp} <- {:strip_prefix, hrp},
         {_, {:ok, %{name: network_name, hrp_segwit_prefix: hrp_segwit_prefix}}} <-
           {:parse_network, parse_network(hrp)} do
      hrp_segwit_prefix_size = byte_size(hrp_segwit_prefix)

      case rest_hrp do
        ^hrp_segwit_prefix ->
          {:ok, {network_name, nil}}

        _ ->
          amount_str = String.slice(rest_hrp, hrp_segwit_prefix_size..-1)

          case calculate_milli_satoshi(amount_str) do
            {:ok, amount} ->
              {:ok, {network_name, amount}}

            {:error, error} ->
              {:error, error}
          end
      end
    else
      {:strip_prefix, _} ->
        {:error, :no_ln_prefix}

      {:parse_network, error} ->
        {:error, error}
    end
  end

  defp calculate_milli_satoshi("0" <> _) do
    {:error, :amount_with_leading_zero}
  end

  defp calculate_milli_satoshi(amount_str) do
    result =
      case Regex.run(~r/[munp]$/, amount_str) do
        [multiplier] when multiplier in @valid_multipliers ->
          case Integer.parse(String.slice(amount_str, 0..-2)) do
            {amount, ""} ->
              {:ok, to_bitcoin(amount, multiplier)}

            _ ->
              {:error, :invalid_amount}
          end

        _ ->
          case Integer.parse(amount_str) do
            {amount_in_bitcoin, ""} ->
              {:ok, amount_in_bitcoin}

            _ ->
              {:error, :invalid_amount}
          end
      end

    case result do
      {:ok, amount_in_bitcoin} ->
        amount_msat_dec = D.mult(amount_in_bitcoin, @milli_satoshi_per_bitcoin)
        rounded_amount_msat_dec = D.round(amount_msat_dec)

        case D.equal?(rounded_amount_msat_dec, amount_msat_dec) do
          true ->
            {:ok, D.to_integer(rounded_amount_msat_dec)}

          false ->
            {:error, :sub_msat_precision_amount}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp to_bitcoin(amount, multiplier_str) when is_integer(amount) do
    multiplier =
      case multiplier_str do
        "m" ->
          0.001

        "u" ->
          0.000001

        "n" ->
          0.000000001

        "p" ->
          0.000000000001
      end

    D.mult(amount, D.from_float(multiplier))
  end

  defp bytes_to_hex_string(bytes) when is_list(bytes) do
    bytes |> :binary.list_to_bin() |> Base.encode16(case: :lower)
  end

  defp byte_list_to_binary(bytes) when is_list(bytes) do
    bytes |> :binary.list_to_bin()
  end

  @spec split_at(Enum.t(), integer()) :: {list(Enum.t()), list(Enum.t())}
  defp split_at(xs, index) when index >= 0 do
    {Enum.take(xs, index), Enum.drop(xs, index)}
  end

  defp split_at(xs, index) when index < 0 do
    {Enum.drop(xs, index), Enum.take(xs, index)}
  end
end
