defmodule GridroomWeb.PageControllerTest do
  use GridroomWeb.ConnCase

  test "GET / renders terminal page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "terminal-container"
  end
end
