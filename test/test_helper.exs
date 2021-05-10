Application.ensure_all_started(:bypass)
Application.ensure_all_started(:mox)

ExUnit.start()

defmodule TestHelpers do
  def bypass_ping_ok(bypass, qtime \\ 0) do
    Bypass.expect_once(bypass, "GET", "/solr/test/admin/ping", fn conn ->
      Plug.Conn.put_resp_header(conn, "content-type", "application/json")
      |> Plug.Conn.resp(200, ~s({"responseHeader":{"QTime":#{qtime}},"status":"OK"}))
    end)
  end
end
