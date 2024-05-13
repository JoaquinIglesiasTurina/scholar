defmodule Scholar.Linear.LinearHelpers do
  require Nx
  import Nx.Defn
  import Scholar.Shared

  @moduledoc false

  @doc false
  def build_sample_weights(x, opts) do
    x_type = to_float_type(x)
    {num_samples, _} = Nx.shape(x)
    default_sample_weights = Nx.broadcast(Nx.as_type(1.0, x_type), {num_samples})
    {sample_weights, _} = Keyword.pop(opts, :sample_weights, default_sample_weights)

    sample_weights =
      if Nx.is_tensor(sample_weights),
        do: Nx.as_type(sample_weights, x_type),
        else: Nx.tensor(sample_weights, type: x_type)

    sample_weights
  end

  @doc false
  defn preprocess_data(x, y, sample_weights, opts) do
    if opts[:sample_weights_flag],
      do:
        {Nx.weighted_mean(x, sample_weights, axes: [0]),
         Nx.weighted_mean(y, sample_weights, axes: [0])},
      else: {Nx.mean(x, axes: [0]), Nx.mean(y, axes: [0])}
  end

  @doc false
  defn set_intercept(coeff, x_offset, y_offset, fit_intercept?) do
    if fit_intercept? do
      y_offset - Nx.dot(coeff, x_offset)
    else
      Nx.tensor(0.0, type: Nx.type(coeff))
    end
  end

  # Implements sample weighting by rescaling inputs and
  # targets by sqrt(sample_weight).
  @doc false
  defn rescale(x, y, sample_weights) do
    case Nx.shape(sample_weights) do
      {} = scalar ->
        scalar = Nx.sqrt(scalar)
        {scalar * x, scalar * y}

      _ ->
        scale = sample_weights |> Nx.sqrt() |> Nx.make_diagonal()
        {Nx.dot(scale, x), Nx.dot(scale, y)}
    end
  end
end
