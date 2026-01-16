defmodule GridroomWeb.PageControllerTest do
  use GridroomWeb.ConnCase

  test "GET / renders grid page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "grid-container"
  end
end
