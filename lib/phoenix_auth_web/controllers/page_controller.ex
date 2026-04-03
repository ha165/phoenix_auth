defmodule PhoenixAuthWeb.PageController do
  use PhoenixAuthWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
