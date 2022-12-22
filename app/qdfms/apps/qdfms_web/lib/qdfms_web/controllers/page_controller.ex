defmodule QdfmsWeb.PageController do
  use QdfmsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
