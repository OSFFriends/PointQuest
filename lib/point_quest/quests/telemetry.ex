defmodule PointQuest.Quests.Telemetry do
  import PointQuest.Telemetry

  @prefix [:point_quest, :quest]

  defevent(:attack, @prefix ++ [:attack])
end
