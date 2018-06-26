defmodule PlusCodes.OpenLocationCode do
  require Integer

  @moduledoc """
  Implements the Google Open Location Code(Plus+Codes) algorithm.
  """

  @separator '+'
  @separator_position 8
  @pair_code_length 10
  @padding '0'
  @code_alphabet '23456789CFGHJMPQRVWX'

  defguard valid_code_length?(value)
           when not (value < 2 or (value < @pair_code_length and rem(value, 2) != 0))

  @doc """
  Determines if a string is a valid sequence of Open Location Code(Plus+Codes) characters.

  ## Examples

      iex> PlusCodes.OpenLocationCode.valid?("8553XJH4+HF")
      true

      iex> PlusCodes.OpenLocationCode.valid?("Not a valid code")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(code) do
    valid_length?(code) && valid_separator?(code) && valid_padding?(code) &&
      valid_character?(code)
  end

  @doc """
  Determines if a string is a valid short Open Location Code(Plus+Codes).

  ## Examples

      iex> PlusCodes.OpenLocationCode.short?("XJH4+HF")
      true

      iex> PlusCodes.OpenLocationCode.short?("8553XJH4+HF")
      false

  """
  @spec short?(String.t()) :: boolean()
  def short?(code) do
    valid?(code) && separator_index(code) < @separator_position
  end

  @doc """
  Determines if a string is a valid full Open Location Code(Plus+Codes).

  ## Examples

      iex> PlusCodes.OpenLocationCode.full?("8553XJH4+HF")
      true

      iex> PlusCodes.OpenLocationCode.full?("XJH4+HF")
      false

  """
  @spec full?(String.t()) :: boolean()
  def full?(code) do
    valid?(code) && !short?(code)
  end

  @doc """
  Converts a latitude and longitude into a Open Location Code(Plus+Codes).
  Raises an exception on argument error.

  ## Examples

      iex> PlusCodes.OpenLocationCode.encode!(33.978938, -118.393812)
      "8553XJH4+HF"

  """
  @spec encode!(float(), float(), integer()) :: String.t()
  def encode!(latitude, longitude, code_length \\ @pair_code_length)

  def encode!(latitude, longitude, code_length) when valid_code_length?(code_length) do
    latitude = latitude |> clip_latitude() |> equatorial_adjustment(code_length)
    longitude = normalize_longitude(longitude)
    to_string(build_code(latitude + 90, longitude + 180, code_length, 0, ''))
  end

  def encode!(_, _, code_length) do
    raise "Invalid Open Location Code(Plus+Codes) length: #{code_length}"
  end

  @doc """
  Converts a latitude and longitude into a Open Location Code(Plus+Codes).
  Returns an :ok/:error tuple

  ## Examples

      iex> PlusCodes.OpenLocationCode.encode(33.978938, -118.393812)
      {:ok, "8553XJH4+HF"}

  """
  @spec encode(float(), float(), integer()) :: {:ok, String.t()} | {:error, String.t()}
  def encode(latitude, longitude, code_length \\ @pair_code_length)

  def encode(latitude, longitude, code_length) when valid_code_length?(code_length) do
    {:ok, encode!(latitude, longitude, code_length)}
  end

  def encode(_, _, code_length) do
    {:error, "Invalid Open Location Code(Plus+Codes) length: #{code_length}"}
  end

  @doc """
  Decodes an Open Location Code(Plus+Codes) into a PlusCodes.CodeArea struct.
  Raises an exception on argument error.

  """
  @spec decode!(String.t()) :: PlusCodes.CodeArea.t()
  def decode!(code) do
    case full?(code) do
      true ->
        code
        |> prepare_for_decode
        |> parse_code(-90.0, -180.0, 400.0, 400.0, 0)
        |> PlusCodes.CodeArea.new()

      false ->
        raise "Open Location Code(Plus+Codes) is not a valid full code: #{code}"
    end
  end

  @doc """
  Decodes an Open Location Code(Plus+Codes) into a PlusCodes.CodeArea struct.
  Returns an :ok/:error tuple

  """
  @spec decode(String.t()) :: {:ok, PlusCodes.CodeArea.t()} | {:error, String.t()}
  def decode(code) do
    case full?(code) do
      true -> {:ok, decode!(code)}
      false -> {:error, "Open Location Code(Plus+Codes) is not a valid full code: #{code}"}
    end
  end

  @doc """
  Recovers a full Open Location Code(Plus+Codes) from a short code and a reference location.
  Raises an exception on argument error.

  ## Examples

      iex> PlusCodes.OpenLocationCode.recover_nearest!("XJH4+HF", 33.978938, -118.393812)
      "8553XJH4+HF"

  """
  @spec recover_nearest!(String.t(), float, float) :: String.t()
  def recover_nearest!(short_code, ref_latitude, ref_longitude) do
    cond do
      full?(short_code) ->
        short_code

      !short?(short_code) ->
        raise "Open Location Code(Plus+Codes) is not valid: #{short_code}"

      true ->
        ref_latitude = clip_latitude(ref_latitude)
        ref_longitude = normalize_longitude(ref_longitude)
        prefix_len = @separator_position - separator_index(short_code)

        code =
          prefix_by_reference(ref_latitude, ref_longitude, prefix_len) ++ to_charlist(short_code)

        area = decode!(to_string(code))
        resolution = precision_by_length(prefix_len)
        half_res = resolution / 2
        latitude = recover_latitude(area.latitude_center, ref_latitude, resolution, half_res)
        longitude = recover_longitude(area.longitude_center, ref_longitude, resolution, half_res)

        encode!(latitude, longitude, length(code) - length(@separator))
    end
  end

  @doc """
  Recovers a full Open Location Code(Plus+Codes) from a short code and a reference location.
  Returns an :ok/:error tuple

  ## Examples

      iex> PlusCodes.OpenLocationCode.recover_nearest("XJH4+HF", 33.978938, -118.393812)
      {:ok, "8553XJH4+HF"}

  """
  @spec recover_nearest(String.t(), float(), float()) :: {:ok, String.t()} | {:error, String.t()}
  def recover_nearest(short_code, ref_latitude, ref_longitude) do
    cond do
      full?(short_code) ->
        {:ok, short_code}

      !short?(short_code) ->
        {:error, "Open Location Code(Plus+Codes) is not valid: #{short_code}"}

      true ->
        {:ok, recover_nearest!(short_code, ref_latitude, ref_longitude)}
    end
  end

  @doc """
  Removes four, six or eight digits from the front of an Open Location Code(Plus+Codes) given a reference location.
  Raises an exception on argument error.

  ## Examples

      iex> PlusCodes.OpenLocationCode.shorten!("8553XJH4+HF", 33.978938, -118.393812)
      "+HF"

      iex> PlusCodes.OpenLocationCode.shorten!("8553XJH4+HF", 33.978, -118.393)
      "H4+HF"

      iex> PlusCodes.OpenLocationCode.shorten!("8553XJH4+HF", 33.9, -118.3)
      "XJH4+HF"

  """
  @spec shorten!(String.t(), float, float) :: String.t()
  def shorten!(code, ref_latitude, ref_longitude) do
    cond do
      !full?(code) ->
        raise "Open Location Code(Plus+Codes) is not a valid full code: #{code}"

      Enum.any?(to_charlist(code), fn c -> [c] == [@padding] end) ->
        raise "Cannot shorten padded codes: #{code}"

      true ->
        code_area = decode!(code)
        lat_diff = abs(ref_latitude - code_area.latitude_center)
        lng_diff = abs(ref_longitude - code_area.longitude_center)
        max_diff = Enum.max([lat_diff, lng_diff])

        code
        |> to_charlist()
        |> shorten_with_precision(8, precision_by_length(8), max_diff)
        |> to_string()
        |> String.upcase()
    end
  end

  @doc """
  Removes four, six or eight digits from the front of an Open Location Code(Plus+Codes) given a reference location.
  Returns an :ok/:error tuple

  ## Examples

      iex> PlusCodes.OpenLocationCode.shorten("8553XJH4+HF", 33.978938, -118.393812)
      {:ok, "+HF"}

      iex> PlusCodes.OpenLocationCode.shorten("8553XJH4+HF", 33.978, -118.393)
      {:ok, "H4+HF"}

      iex> PlusCodes.OpenLocationCode.shorten("8553XJH4+HF", 33.9, -118.3)
      {:ok, "XJH4+HF"}

  """
  @spec shorten(String.t(), float, float) :: {:ok, String.t()} | {:error, String.t()}
  def shorten(code, ref_latitude, ref_longitude) do
    cond do
      !full?(code) ->
        {:error, "Open Location Code(Plus+Codes) is not a valid full code: #{code}"}

      Enum.any?(to_charlist(code), fn c -> [c] == [@padding] end) ->
        {:error, "Cannot shorten padded codes: #{code}"}

      true ->
        {:ok, shorten!(code, ref_latitude, ref_longitude)}
    end
  end

  # Private

  defp shorten_with_precision(code, removal_len, precision, max_diff)
       when max_diff < precision * 0.3 and removal_len > 2 do
    code
    |> Enum.reverse()
    |> Enum.take(length(code) - removal_len)
    |> Enum.reverse()
  end

  defp shorten_with_precision(code, removal_len, _, max_diff) when removal_len > 2 do
    shorten_with_precision(code, removal_len - 2, precision_by_length(removal_len - 2), max_diff)
  end

  defp shorten_with_precision(code, _, _, _), do: code

  defp prefix_by_reference(latitude, longitude, prefix_len) do
    precision = precision_by_length(prefix_len)
    rounded_latitude = Float.floor(latitude / precision) * precision
    rounded_longitude = Float.floor(longitude / precision) * precision

    encode!(rounded_latitude, rounded_longitude)
    |> to_charlist()
    |> Enum.take(prefix_len)
  end

  defp recover_latitude(latitude, ref_latitude, resolution, half_res)
       when ref_latitude + half_res < latitude and latitude - resolution >= -90 do
    latitude - resolution
  end

  defp recover_latitude(latitude, ref_latitude, resolution, half_res)
       when ref_latitude - half_res > latitude and latitude + resolution <= 90 do
    latitude + resolution
  end

  defp recover_latitude(latitude, _, _, _), do: latitude

  defp recover_longitude(longitude, ref_longitude, resolution, half_res)
       when ref_longitude + half_res < longitude do
    longitude - resolution
  end

  defp recover_longitude(longitude, ref_longitude, resolution, half_res)
       when ref_longitude - half_res > longitude do
    longitude + resolution
  end

  defp recover_longitude(longitude, _, _, _), do: longitude

  defp prepare_for_decode(code) do
    code
    |> String.replace(to_string(@separator), "")
    |> String.replace(to_string(@padding), "")
    |> String.upcase()
    |> to_charlist()
  end

  defp parse_code(code, south_lat, west_lng, lat_res, lng_res, digit) when digit < length(code) do
    {south_lat, west_lng, lat_res, lng_res, digit} =
      decode_digit(code, south_lat, west_lng, lat_res, lng_res, digit)

    parse_code(code, south_lat, west_lng, lat_res, lng_res, digit)
  end

  defp parse_code(_code, south_lat, west_lng, lat_res, lng_res, _digit) do
    {south_lat, west_lng, lat_res, lng_res}
  end

  defp decode_digit(code, south_lat, west_lng, lat_res, lng_res, digit)
       when digit < @pair_code_length do
    lat_res = lat_res / 20
    lng_res = lng_res / 20
    south_lat = south_lat + lat_res * code_at(Enum.at(code, digit))
    west_lng = west_lng + lng_res * code_at(Enum.at(code, digit + 1))
    digit = digit + 2
    {south_lat, west_lng, lat_res, lng_res, digit}
  end

  defp decode_digit(code, south_lat, west_lng, lat_res, lng_res, digit) do
    lat_res = lat_res / 5
    lng_res = lng_res / 4
    row = div(code_at(Enum.at(code, digit)), 4)
    col = rem(code_at(Enum.at(code, digit)), 4)
    south_lat = south_lat + lat_res * row
    west_lng = west_lng + lng_res * col
    digit = digit + 1
    {south_lat, west_lng, lat_res, lng_res, digit}
  end

  defp build_code(latitude, longitude, code_length, digit, code) when digit < code_length do
    {latitude, longitude} = narrow_region(digit, latitude, longitude)
    {encoded, digit, latitude, longitude} = encode_pairs(digit, latitude, longitude)
    build_code(latitude, longitude, code_length, digit, code ++ encoded ++ separate(digit))
  end

  defp build_code(_, _, _, digit, code) when digit < @separator_position do
    code ++
      to_charlist(String.duplicate(to_string(@padding), @separator_position - length(code))) ++
      @separator
  end

  defp build_code(_, _, _, _, code), do: code

  defp separate(digit) when digit == @separator_position, do: @separator
  defp separate(_digit), do: ''

  defp encode_pairs(digit, latitude, longitude) when digit < @pair_code_length do
    {[code_for(trunc(latitude)), code_for(trunc(longitude))], digit + 2,
     latitude - trunc(latitude), longitude - trunc(longitude)}
  end

  defp encode_pairs(digit, latitude, longitude) do
    {[code_for(4 * trunc(latitude) + trunc(longitude))], digit + 1, latitude - trunc(latitude),
     longitude - trunc(longitude)}
  end

  defp narrow_region(digit, latitude, longitude) when digit == 0 do
    {magnatize_int(latitude / 20), magnatize_int(longitude / 20)}
  end

  defp narrow_region(digit, latitude, longitude) when digit < @pair_code_length do
    {magnatize_int(latitude * 20), magnatize_int(longitude * 20)}
  end

  defp narrow_region(_digit, latitude, longitude) do
    {magnatize_int(latitude * 5), magnatize_int(longitude * 4)}
  end

  defp separator_index(code) do
    code
    |> to_charlist()
    |> Enum.find_index(fn c -> [c] == @separator end)
  end

  defp clip_latitude(latitude) do
    Enum.min([90.0, Enum.max([-90.0, latitude])])
  end

  defp normalize_longitude(longitude) when longitude >= 180 do
    normalize_longitude(longitude - 360)
  end

  defp normalize_longitude(longitude) when longitude < -180 do
    normalize_longitude(longitude + 360)
  end

  defp normalize_longitude(longitude), do: longitude

  defp equatorial_adjustment(latitude, code_length) when latitude == 90 do
    latitude - precision_by_length(code_length)
  end

  defp equatorial_adjustment(latitude, _), do: latitude

  defp precision_by_length(code_length) when code_length <= @pair_code_length do
    :math.pow(20, trunc(code_length / -2) + 2)
  end

  defp precision_by_length(code_length) do
    :math.pow(20, -3) / :math.pow(5, code_length - @pair_code_length)
  end

  defp code_for(n) do
    Enum.at(@code_alphabet, n)
  end

  defp code_at(n) do
    Enum.find_index(@code_alphabet, fn c -> c == n end)
  end

  defp valid_length?(code) do
    code != nil && length(to_charlist(code)) >= 2 + length(@separator) &&
      code
      |> String.split(to_string(@separator))
      |> Enum.reverse()
      |> List.first()
      |> to_charlist()
      |> length() != 1
  end

  defp valid_separator?(code) do
    Enum.count(to_charlist(code), fn c -> [c] == @separator end) == 1 &&
      separator_index(code) <= @separator_position && Integer.is_even(separator_index(code))
  end

  defp valid_padding?(code) do
    paddings = Regex.scan(~r/0+/, code) |> List.flatten()

    paddings == [] ||
      (!String.starts_with?(code, to_string(@padding)) &&
         String.starts_with?(String.reverse(code), to_string([@separator, @padding])) &&
         (length(paddings) == 1 &&
            paddings |> List.first() |> to_charlist() |> length() |> Integer.is_even()) &&
         paddings |> List.first() |> to_charlist() |> length() <= @separator_position - 2)
  end

  defp valid_character?(code) do
    code
    |> String.upcase()
    |> to_charlist()
    |> Enum.all?(fn c -> Enum.member?(@code_alphabet ++ @separator ++ @padding, c) end)
  end

  defp magnatize_int(n) do
    case near_int?(n) do
      true -> Float.round(n)
      false -> n
    end
  end

  defp near_int?(n) do
    trunc(n) != trunc(n + 0.0000000001)
  end
end
