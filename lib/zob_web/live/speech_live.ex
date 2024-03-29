defmodule ZobWeb.SpeechLive do
  use ZobWeb, :live_view

  @buzzwords [
    "30,000 ft. view",
    "actionable",
    "advertainment",
    "agile",
    "aligned",
    "alignment",
    "all hands on deck",
    "analytics",
    "artificial intelligence",
    "asap",
    "ask",
    "at the end of the day",
    "automation",
    "bandwidth",
    "best in class",
    "best of breed",
    "best practice",
    "big data",
    "bio-break",
    "bleeding edge",
    "blockchain",
    "blue sky",
    "boil the ocean",
    "bottom line",
    "bring to the table",
    "business intelligence",
    "buy-in",
    "circle back",
    "cloud, and cloud-based",
    "collaboration",
    "competitive intelligence",
    "content",
    "core competency",
    "corporate values",
    "culture",
    "customer journey",
    "customer-centric",
    "data-driven",
    "deep dive",
    "devops",
    "digital transformation",
    "disruptive",
    "disruptor",
    "diversity",
    "double click",
    "drill down",
    "driving value",
    "ducks in a row",
    "efficiency",
    "empower",
    "engagement",
    "fail fast",
    "fail forward",
    "freemium",
    "full plate",
    "fyi",
    "game-changer",
    "give you back some time",
    "giving 110%",
    "giving back your time ",
    "growth hacking",
    "hard stop",
    "holistic",
    "ideate",
    "ideation",
    "in the weeds",
    "influencer",
    "innovative",
    "integration",
    "intuitive",
    "iot",
    "keep me in the loop",
    "kpi",
    "kpi",
    "lean-in",
    "learnings",
    "level up",
    "leverage",
    "loop back",
    "low-hanging fruit",
    "machine learning",
    "market intelligence",
    "metrics",
    "mindfulness",
    "mindshare ",
    "move the needle",
    "moving forward",
    "net-net",
    "next level",
    "next-gen",
    "omni-channel",
    "on the same page",
    "on your plate",
    "on your radar",
    "onboarding",
    "open the kimono",
    "optics",
    "optimize",
    "organic",
    "pain point",
    "paradigm",
    "partner",
    "per se",
    "ping",
    "pivot",
    "platform",
    "put a pin in it",
    "quick win",
    "reach out",
    "right",
    "rockstar",
    "roi",
    "roi",
    "scalable",
    "scrum",
    "single pane of glass",
    "socialize",
    "space",
    "stakeholders",
    "story",
    "strategic",
    "swimlane",
    "synergy",
    "table stakes",
    "table that for later",
    "take it offline",
    "team players",
    "team-building",
    "teamwork",
    "think outside the box",
    "thought leader",
    "top of mind",
    "touch base",
    "unpack",
    "uplevel",
    "value add",
    "value proposition",
    "value",
    "verticals",
    "wheelhouse",
    "win-win",
    "you don't know what you don't know",
  ]

  def mount(_params, _session, socket) do
    words =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Zob.PubSub, "new_word")

        [a, b, c, d, e, f, g, h, i, j, k, l | rest] =
        @buzzwords
        |> Enum.shuffle()
        |> Enum.take(24)

        [a, b, c, d, e, f, g, h, i, j, k, l | ["FREE" | rest]]
      else
        []
      end

    socket =
      socket
      |> assign(words: words, matches: MapSet.new(["FREE"]))
      |> stream(:inputs, [])

    {:ok, socket}
  end

  def handle_info({:new_word, new_word}, socket) do
    IO.inspect(new_word, label: "whisper input")

    tokens =
      new_word
      |> String.replace(~r/[^-a-z' ]/i, "")
      |> String.split()

    socket =
      case find_match(tokens) do
        nil ->
          IO.puts("no match")
          socket

        match ->
          IO.inspect(match, label: "MATCH")
          assign(socket, matches: MapSet.put(socket.assigns.matches, match))
      end

    socket = Enum.reduce(tokens, socket, &stream_insert(&2, :inputs, %{id: System.unique_integer([:positive, :monotonic]) , value: &1}, at: 0))

    {:noreply, socket}
  end

  defp find_match(tokens) do
    Enum.find(@buzzwords, fn phrase ->
      phrase
      |> String.split()
      |> is_sublist?(tokens)
    end)
  end

  defp is_sublist?([], _), do: true
  defp is_sublist?(_, []), do: false
  defp is_sublist?([h | needle], [h | haystack]), do: is_sublist?(needle, haystack)
  defp is_sublist?(needle, [_ | haystack]), do: is_sublist?(needle, haystack)

  def render(assigns) do
    ~H"""
    <div>
      <h1>Your buzzwords</h1>

      <div class="grid grid-cols-5 text-center">
        <.word word={word} :for={word <- @words} matched={MapSet.member?(@matches, word)}/>
      </div>

      <div id="inputs" phx-update="stream">
        <div :for={{id, input} <- @streams.inputs} id={id}>
          <%= input.value %>
        </div>
      </div>
    </div>
    """
  end

  def word(%{matched: true} = assigns) do
    ~H"""
    <div class="bg-yellow-200 border-2 h-32"><%= @word %></div>
    """
  end

  def word(assigns) do
    ~H"""
    <div class="border-2 h-32"><%= @word %></div>
    """
  end
end
