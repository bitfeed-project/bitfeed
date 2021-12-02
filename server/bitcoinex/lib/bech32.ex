defmodule Bitcoinex.Bech32 do
  @moduledoc """
  Includes Bech32 serialization and validation.

  Reference: https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki#bech32
  """

  use Bitwise

  @gen [0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3]
  @data_charset_list 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'
  @data_charset_map @data_charset_list
                    |> Enum.zip(0..Enum.count(@data_charset_list))
                    |> Enum.into(%{})
  @hrp_char_code_point_upper_limit 126
  @hrp_char_code_point_lower_limit 33
  @max_overall_encoded_length 90
  @separator "1"

  @encoding_constant_map %{
    bech32: 1,
    bech32m: 0x2BC830A3
  }

  @type encoding_type :: :bech32 | :bech32m
  @type hrp :: String.t()
  @type data :: list(integer)

  @type witness_version :: Range.t(0, 16)
  @type witness_program :: list(integer)
  @type max_encoded_length :: pos_integer() | :infinity

  @type error :: atom()

  # Inspired by Ecto.Changeset. more descriptive than result tuple
  defmodule DecodeResult do
    @type t() :: %__MODULE__{
            encoded_str: String.t(),
            encoding_type: Bitcoinex.Bech32.encoding_type() | nil,
            hrp: String.t() | nil,
            data: String.t() | nil,
            error: atom() | nil
          }
    defstruct [:encoded_str, :encoding_type, :hrp, :data, :error]

    @spec add_error(t(), atom()) :: t()
    def add_error(%DecodeResult{} = decode_result, error) do
      %{
        decode_result
        | error: error
      }
    end

    @doc """
    This naming is taken from Haskell. we will treat DecodeResult a bit like an Monad
    And bind function will take a function that take DecodeResult that's only without error and return DecodeResult
    And we can skip handling same error case for all function
    """
    @spec bind(t(), (t -> t())) :: t()
    def bind(%DecodeResult{error: error} = decode_result, _fun) when not is_nil(error) do
      decode_result
    end

    def bind(%DecodeResult{} = decode_result, fun) do
      fun.(decode_result)
    end
  end

  @spec decode(String.t(), max_encoded_length()) ::
          {:ok, {encoding_type, hrp, data}} | {:error, error}
  def decode(bech32_str, max_encoded_length \\ @max_overall_encoded_length)
      when is_binary(bech32_str) do
    %DecodeResult{
      encoded_str: bech32_str
    }
    |> DecodeResult.bind(&validate_bech32_length(&1, max_encoded_length))
    |> DecodeResult.bind(&validate_bech32_case/1)
    |> DecodeResult.bind(&split_bech32_str/1)
    |> DecodeResult.bind(&validate_checksum_and_add_encoding_type/1)
    |> format_bech32_decoding_result
  end

  @spec encode(hrp, data | String.t(), encoding_type, max_encoded_length()) ::
          {:ok, String.t()} | {:error, error}
  def encode(hrp, data, encoding_type, max_encoded_length \\ @max_overall_encoded_length)

  def encode(hrp, data, encoding_type, max_encoded_length) when is_list(data) do
    hrp_charlist = hrp |> String.to_charlist()

    if is_valid_hrp?(hrp_charlist) do
      checksummed = data ++ create_checksum(hrp_charlist, data, encoding_type)
      dp = Enum.map(checksummed, &Enum.at(@data_charset_list, &1)) |> List.to_string()
      encoded_result = <<hrp::binary, @separator, dp::binary>>

      case validate_bech32_length(encoded_result, max_encoded_length) do
        :ok ->
          {:ok, String.downcase(encoded_result)}

        {:error, error} ->
          {:error, error}
      end
    else
      {:error, :hrp_char_out_opf_range}
    end
  end

  # Here we assume caller pass raw ASCII string
  def encode(hrp, data, encoding_type, max_encoded_length) when is_binary(data) do
    data_integers = data |> String.to_charlist() |> Enum.map(&Map.get(@data_charset_map, &1))

    case check_data_charlist_validity(data_integers) do
      :ok ->
        encode(hrp, data_integers, encoding_type, max_encoded_length)

      {:error, error} ->
        {:error, error}
    end
  end

  # Big endian conversion of a list of integer from base 2^frombits to base 2^tobits.
  # ref https://github.com/sipa/bech32/blob/master/ref/python/segwit_addr.py#L80

  @spec convert_bits(list(integer), integer(), integer(), boolean()) ::
          {:error, :invalid_data} | {:ok, list(integer)}
  def convert_bits(data, from_bits, to_bits, padding \\ true) when is_list(data) do
    max_v = (1 <<< to_bits) - 1
    max_acc = (1 <<< (from_bits + to_bits - 1)) - 1

    result =
      Enum.reduce_while(data, {0, 0, []}, fn val, {acc, bits, ret} ->
        if val < 0 or val >>> from_bits != 0 do
          {:halt, {:error, :invalid_data}}
        else
          acc = (acc <<< from_bits ||| val) &&& max_acc
          bits = bits + from_bits
          {bits, ret} = convert_bits_loop(to_bits, max_v, acc, bits, ret)
          {:cont, {acc, bits, ret}}
        end
      end)

    case result do
      {acc, bits, ret} ->
        if padding && bits > 0 do
          {:ok, ret ++ [acc <<< (to_bits - bits) &&& max_v]}
        else
          if bits >= from_bits || (acc <<< (to_bits - bits) &&& max_v) > 0 do
            {:error, :invalid_data}
          else
            {:ok, ret}
          end
        end

      {:error, :invalid_data} = e ->
        e
    end
  end

  defp convert_bits_loop(to, max_v, acc, bits, ret) do
    if bits >= to do
      bits = bits - to
      ret = ret ++ [acc >>> bits &&& max_v]
      convert_bits_loop(to, max_v, acc, bits, ret)
    else
      {bits, ret}
    end
  end

  defp validate_checksum_and_add_encoding_type(
         %DecodeResult{
           data: data,
           hrp: hrp
         } = decode_result
       ) do
    case bech32_polymod(bech32_hrp_expand(hrp) ++ data) do
      unquote(@encoding_constant_map.bech32) ->
        %DecodeResult{decode_result | encoding_type: :bech32}

      unquote(@encoding_constant_map.bech32m) ->
        %DecodeResult{decode_result | encoding_type: :bech32m}

      _ ->
        DecodeResult.add_error(decode_result, :invalid_checksum)
    end
  end

  defp create_checksum(hrp, data, encoding_type) do
    values = bech32_hrp_expand(hrp) ++ data ++ [0, 0, 0, 0, 0, 0]
    mod = bech32_polymod(values) ^^^ @encoding_constant_map[encoding_type]
    for p <- 0..5, do: mod >>> (5 * (5 - p)) &&& 31
  end

  defp bech32_polymod(values) do
    Enum.reduce(
      values,
      1,
      fn value, acc ->
        b = acc >>> 25
        acc = ((acc &&& 0x1FFFFFF) <<< 5) ^^^ value

        Enum.reduce(0..length(@gen), acc, fn i, in_acc ->
          in_acc ^^^
            if (b >>> i &&& 1) != 0 do
              Enum.at(@gen, i)
            else
              0
            end
        end)
      end
    )
  end

  defp bech32_hrp_expand(chars) when is_list(chars) do
    Enum.map(chars, &(&1 >>> 5)) ++ [0 | Enum.map(chars, &(&1 &&& 31))]
  end

  defp format_bech32_decoding_result(%DecodeResult{
         error: nil,
         hrp: hrp,
         data: data,
         encoding_type: encoding_type
       })
       when not is_nil(hrp) and not is_nil(data) do
    {:ok, {encoding_type, to_string(hrp), Enum.drop(data, -6)}}
  end

  defp format_bech32_decoding_result(%DecodeResult{
         error: error
       }) do
    {:error, error}
  end

  defp split_bech32_str(
         %DecodeResult{
           encoded_str: encoded_str
         } = decode_result
       ) do
    # the bech 32 is at most 90 chars
    # so it's ok to do 3 time reverse here
    # otherwise we can use binary pattern matching with index for better performance
    downcase_encoded_str = encoded_str |> String.downcase()

    with {_, [data, hrp]} when hrp != "" and data != "" <-
           {:split_by_separator,
            downcase_encoded_str |> String.reverse() |> String.split(@separator, parts: 2)},
         hrp = hrp |> String.reverse() |> String.to_charlist(),
         {_, true} <- {:check_hrp_validity, is_valid_hrp?(hrp)},
         data <-
           data
           |> String.reverse()
           |> String.to_charlist()
           |> Enum.map(&Map.get(@data_charset_map, &1)),
         {_, :ok} <- {:check_data_validity, check_data_charlist_validity(data)} do
      %DecodeResult{
        decode_result
        | hrp: hrp,
          data: data
      }
    else
      {:split_by_separator, [_]} ->
        DecodeResult.add_error(decode_result, :no_separator_character)

      {:split_by_separator, ["", _]} ->
        DecodeResult.add_error(decode_result, :empty_data)

      {:split_by_separator, [_, ""]} ->
        DecodeResult.add_error(decode_result, :empty_hrp)

      {:check_hrp_validity, false} ->
        DecodeResult.add_error(decode_result, :hrp_char_out_opf_range)

      {:check_data_validity, {:error, error}} ->
        DecodeResult.add_error(decode_result, error)
    end
  end

  defp validate_bech32_length(
         %DecodeResult{
           encoded_str: encoded_str
         } = decode_result,
         max_length
       ) do
    case validate_bech32_length(encoded_str, max_length) do
      :ok ->
        decode_result

      {:error, error} ->
        DecodeResult.add_error(decode_result, error)
    end
  end

  defp validate_bech32_length(encoded_str, :infinity) when is_binary(encoded_str) do
    :ok
  end

  defp validate_bech32_length(
         encoded_str,
         max_length
       )
       when is_binary(encoded_str) and byte_size(encoded_str) > max_length do
    {:error, :overall_max_length_exceeded}
  end

  defp validate_bech32_length(
         encoded_str,
         _max_length
       )
       when is_binary(encoded_str) do
    :ok
  end

  defp validate_bech32_case(
         %DecodeResult{
           encoded_str: encoded_str
         } = decode_result
       ) do
    case String.upcase(encoded_str) == encoded_str or String.downcase(encoded_str) == encoded_str do
      true ->
        decode_result

      false ->
        DecodeResult.add_error(decode_result, :mixed_case)
    end
  end

  defp check_data_charlist_validity(charlist) do
    if length(charlist) >= 6 do
      if Enum.all?(charlist, &(!is_nil(&1))) do
        :ok
      else
        {:error, :contain_invalid_data_char}
      end
    else
      {:error, :too_short_checksum}
    end
  end

  defp is_valid_hrp?(hrp) when is_list(hrp), do: Enum.all?(hrp, &is_valid_hrp_char?/1)

  defp is_valid_hrp_char?(char) do
    char <= @hrp_char_code_point_upper_limit and char >= @hrp_char_code_point_lower_limit
  end
end
