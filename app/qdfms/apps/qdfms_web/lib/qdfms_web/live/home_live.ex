defmodule QdfmsWeb.HomeLive do
  use QdfmsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>Hello World!</h1>
    """
  end
end
