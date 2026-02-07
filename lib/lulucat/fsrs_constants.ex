defmodule Fsrs.Constants do
  @moduledoc """
  Constants for FSRS-6 behavior.

  Includes default parameters, parameter bounds, and fuzzing ranges.

  中文说明：集中定义 FSRS-6 默认参数、边界与 fuzz 范围。
  """

  @doc """
  Minimum stability value allowed.

  中文说明：稳定性下限。
  """
  def stability_min, do: 0.001

  @doc """
  Maximum initial stability value allowed.

  中文说明：初始稳定性的上限。
  """
  def initial_stability_max, do: 100.0

  @doc """
  Default FSRS-6 parameter tuple.

  Baseline: `py-fsrs v6.3.0`.
  中文说明：与 py-fsrs v6.3.0 对齐的默认参数。
  """
  def default_parameters do
    {
      0.212,
      1.2931,
      2.3065,
      8.2956,
      6.4133,
      0.8334,
      3.0194,
      0.001,
      1.8722,
      0.1666,
      0.796,
      1.4835,
      0.0614,
      0.2629,
      1.6483,
      0.6014,
      1.8729,
      0.5425,
      0.0912,
      0.0658,
      0.1542
    }
  end

  @doc """
  Lower bounds for FSRS parameters.

  中文说明：参数下界。
  """
  def lower_bounds_parameters do
    {
      stability_min(),
      stability_min(),
      stability_min(),
      stability_min(),
      1.0,
      0.001,
      0.001,
      0.001,
      0.0,
      0.0,
      0.001,
      0.001,
      0.001,
      0.001,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.1
    }
  end

  @doc """
  Upper bounds for FSRS parameters.

  中文说明：参数上界。
  """
  def upper_bounds_parameters do
    {
      initial_stability_max(),
      initial_stability_max(),
      initial_stability_max(),
      initial_stability_max(),
      10.0,
      4.0,
      4.0,
      0.75,
      4.5,
      0.8,
      3.5,
      5.0,
      0.25,
      0.9,
      4.0,
      1.0,
      6.0,
      2.0,
      2.0,
      0.8,
      0.8
    }
  end

  @doc """
  Fuzz ranges used for interval calculation.

  中文说明：用于区间模糊处理的范围表。
  """
  def fuzz_ranges do
    [
      %{
        start: 2.5,
        end: 7.0,
        factor: 0.15
      },
      %{
        start: 7.0,
        end: 20.0,
        factor: 0.1
      },
      %{
        start: 20.0,
        end: :infinity,
        factor: 0.05
      }
    ]
  end
end
