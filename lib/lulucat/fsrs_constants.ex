defmodule Fsrs.Constants do
  @moduledoc """
  Constants used by the FSRS system.
  FSRS 系统使用的常量。
  """

  @doc """
  Minimum stability value allowed
  允许的最小稳定性值
  """
  def stability_min, do: 0.001

  @doc """
  Maximum initial stability value allowed
  允许的初始稳定性最大值
  """
  def initial_stability_max, do: 100.0

  @doc """
  Default parameters for the FSRS algorithm
  FSRS 算法的默认参数
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
  FSRS 参数下界。
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
  FSRS 参数上界。
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
  Fuzz ranges used for interval calculation
  用于间隔计算的模糊范围
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
