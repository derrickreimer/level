defmodule Level.Scheduler do
  @moduledoc """
  The job scheduler.
  """

  use Quantum.Scheduler,
    otp_app: :level
end
