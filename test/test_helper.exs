Application.load(:news_ingester)

for app <- Application.spec(:news_ingester, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
