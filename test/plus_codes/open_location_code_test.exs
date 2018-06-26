defmodule PlusCodes.OpenLocationCodeTest do
  use ExUnit.Case
  doctest PlusCodes.OpenLocationCode

  describe "PlusCodes.OpenLocationCode.encode!/3" do
    setup [:encode_decode_data]

    test "it can encode a variety of codes", %{data: data} do
      Enum.all?(data, fn {code, lat, lng, digits, _, _, _, _} ->
        assert(PlusCodes.OpenLocationCode.encode!(lat, lng, digits) == code)
      end)
    end
  end

  describe "PlusCodes.OpenLocationCode.decode!/1" do
    setup [:encode_decode_data]

    test "it can decode a variety of codes", %{data: data} do
      Enum.all?(data, fn {code, _, _, _, lat_lo, lng_lo, lat_hi, lng_hi} ->
        area = PlusCodes.OpenLocationCode.decode!(code)
        assert(abs(area.south_latitude - lat_lo) < 0.001)
        assert(abs(area.west_longitude - lng_lo) < 0.001)
        assert(abs(area.north_latitude - lat_hi) < 0.001)
        assert(abs(area.east_longitude - lng_hi) < 0.001)
      end)
    end
  end

  describe("PlusCodes.OpenLocationCode.valid?/1") do
    setup [:validity_data]

    test "it can determine the validity of codes", %{data: data} do
      Enum.all?(data, fn {code, valid, _, _} ->
        assert(PlusCodes.OpenLocationCode.valid?(code) == valid)
      end)
    end
  end

  describe("PlusCodes.OpenLocationCode.short?/1") do
    setup [:validity_data]

    test "it can determine the validity of codes", %{data: data} do
      Enum.all?(data, fn {code, _, short, _} ->
        assert(PlusCodes.OpenLocationCode.short?(code) == short)
      end)
    end
  end

  describe("PlusCodes.OpenLocationCode.full?/1") do
    setup [:validity_data]

    test "it can determine the validity of codes", %{data: data} do
      Enum.all?(data, fn {code, _, _, full} ->
        assert(PlusCodes.OpenLocationCode.full?(code) == full)
      end)
    end
  end

  describe("PlusCodes.OpenLocationCode.shorten!/3") do
    setup [:recovery_data]

    test "it can shorten codes given a reference location", %{data: data} do
      data
      |> Enum.filter(fn {_, _, _, _, t} -> t == "B" || t == "S" end)
      |> Enum.all?(fn {long, lat, lng, short, _} ->
        assert(PlusCodes.OpenLocationCode.shorten!(long, lat, lng) == short)
      end)
    end
  end

  describe("PlusCodes.OpenLocationCode.recover_nearest!/3") do
    setup [:recovery_data]

    test "it can shorten codes given a reference location", %{data: data} do
      data
      |> Enum.filter(fn {_, _, _, _, t} -> t == "B" || t == "R" end)
      |> Enum.all?(fn {long, lat, lng, short, _} ->
        assert(PlusCodes.OpenLocationCode.recover_nearest!(short, lat, lng) == long)
      end)
    end
  end

  def encode_decode_data(context) do
    Map.merge(context, %{
      data: [
        {"7FG49Q00+", 20.375, 2.775, 6, 20.35, 2.75, 20.4, 2.8},
        {"7FG49QCJ+2V", 20.3700625, 2.7821875, 10, 20.37, 2.782125, 20.370125, 2.78225},
        {"7FG49QCJ+2VX", 20.3701125, 2.782234375, 11, 20.3701, 2.78221875, 20.370125, 2.78225},
        {"7FG49QCJ+2VXGJ", 20.3701135, 2.78223535156, 13, 20.370113, 2.782234375, 20.370114,
         2.78223632813},
        {"8FVC2222+22", 47.0000625, 8.0000625, 10, 47.0, 8.0, 47.000125, 8.000125},
        {"4VCPPQGP+Q9", -41.2730625, 174.7859375, 10, -41.273125, 174.785875, -41.273, 174.786},
        {"62G20000+", 0.5, -179.5, 4, 0.0, -180.0, 1, -179},
        {"22220000+", -89.5, -179.5, 4, -90, -180, -89, -179},
        {"7FG40000+", 20.5, 2.5, 4, 20.0, 2.0, 21.0, 3.0},
        {"22222222+22", -89.9999375, -179.9999375, 10, -90.0, -180.0, -89.999875, -179.999875},
        {"6VGX0000+", 0.5, 179.5, 4, 0, 179, 1, 180},
        {"6FH32222+222", 1, 1, 11, 1, 1, 1.000025, 1.00003125},
        {"CFX30000+", 90, 1, 4, 89, 1, 90, 2},
        {"CFX30000+", 92, 1, 4, 89, 1, 90, 2},
        {"62H20000+", 1, 180, 4, 1, -180, 2, -179},
        {"62H30000+", 1, 181, 4, 1, -179, 2, -178},
        {"CFX3X2X2+X2", 90, 1, 10, 89.9998750, 1, 90, 1.0001250}
      ]
    })
  end

  def validity_data(context) do
    Map.merge(context, %{
      data: [
        {"8FWC2345+G6", true, false, true},
        {"8FWC2345+G6G", true, false, true},
        {"8fwc2345+", true, false, true},
        {"8FWCX400+", true, false, true},
        {"WC2345+G6g", true, true, false},
        {"2345+G6", true, true, false},
        {"45+G6", true, true, false},
        {"+G6", true, true, false},
        {"G+", false, false, false},
        {"+", false, false, false},
        {"8FWC2345+G", false, false, false},
        {"8FWC2_45+G6", false, false, false},
        {"8FWC2η45+G6", false, false, false},
        {"8FWC2345+G6+", false, false, false},
        {"8FWC2300+G6", false, false, false},
        {"WC2300+G6g", false, false, false},
        {"WC2345+G", false, false, false}
      ]
    })
  end

  def recovery_data(context) do
    Map.merge(context, %{
      data: [
        {"9C3W9QCJ+2VX", 51.3701125, -1.217765625, "+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3708675, -1.217765625, "CJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3693575, -1.217765625, "CJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3701125, -1.218520625, "CJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3701125, -1.217010625, "CJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3852125, -1.217765625, "9QCJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3550125, -1.217765625, "9QCJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3701125, -1.232865625, "9QCJ+2VX", "B"},
        {"9C3W9QCJ+2VX", 51.3701125, -1.202665625, "9QCJ+2VX", "B"},
        {"8FJFW222+", 42.899, 9.012, "22+", "B"},
        {"796RXG22+", 14.95125, -23.5001, "22+", "B"},
        {"8FVC2GGG+GG", 46.976, 8.526, "2GGG+GG", "B"},
        {"8FRCXGGG+GG", 47.026, 8.526, "XGGG+GG", "B"},
        {"8FR9GXGG+GG", 46.526, 8.026, "GXGG+GG", "B"},
        {"8FRCG2GG+GG", 46.526, 7.976, "G2GG+GG", "B"},
        {"CFX22222+22", 89.6, 0.0, "2222+22", "R"},
        {"2CXXXXXX+XX", -81.0, 0.0, "XXXXXX+XX", "R"}
      ]
    })
  end
end
