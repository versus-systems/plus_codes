defmodule PlusCodes.CodeArea do
  @moduledoc """
  Contains coordinates of a decoded Open Location Code(Plus+Codes).
  The coordinates include the latitude and longitude of the lower left and
  upper right corners and the center of the bounding box for the area the
  code represents.
  """

  @type t :: %__MODULE__{}

  defstruct [
    :south_latitude,
    :west_longitude,
    :north_latitude,
    :east_longitude,
    :latitude_height,
    :longitude_width,
    :latitude_center,
    :longitude_center
  ]

  def new({south_latitude, west_longitude, latitude_height, longitude_width}) do
    new(south_latitude, west_longitude, latitude_height, longitude_width)
  end

  def new(south_latitude, west_longitude, latitude_height, longitude_width) do
    %__MODULE__{
      south_latitude: south_latitude,
      west_longitude: west_longitude,
      north_latitude: south_latitude + latitude_height,
      east_longitude: west_longitude + longitude_width,
      latitude_height: latitude_height,
      longitude_width: longitude_width,
      latitude_center: south_latitude + latitude_height / 2.0,
      longitude_center: west_longitude + longitude_width / 2.0
    }
  end
end
