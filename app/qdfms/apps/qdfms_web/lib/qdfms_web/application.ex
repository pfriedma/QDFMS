defmodule QdfmsWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      QdfmsWeb.Telemetry,
      # Start the Endpoint (http/https)
      QdfmsWeb.Endpoint,
      # Start a worker by calling: QdfmsWeb.Worker.start_link(arg)
      # {QdfmsWeb.Worker, arg}
      {Phoenix.PubSub, name: QdfmsWeb.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QdfmsWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QdfmsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
