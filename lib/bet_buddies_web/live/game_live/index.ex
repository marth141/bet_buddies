defmodule BetBuddiesWeb.GameLive.Index do
  use Phoenix.LiveView
  use Phoenix.Component
  alias Phoenix.PubSub
  use BetBuddiesWeb, :html

  def mount(
        %{"game_id" => game_id} = _params,
        %{"player_id" => player_id} = _session,
        socket
      ) do
    PubSub.subscribe(BetBuddies.PubSub, game_id)

    %Poker.GameState{players: players, game_stage: game_stage, player_turn: player_turn} = Poker.get_game_state(game_id)

    player = find_player(players, player_id)

    other_players = players -- [player]

    socket =
      assign(socket, :game_id, game_id)
      |> assign(:game_stage, game_stage)
      |> assign(:player, player)
      |> assign(:other_players, other_players)
      |> assign(:ante, 0)
      |> assign(:player_turn, player_turn)

    {:ok, socket}
  end

  def handle_event("start-game", _params, socket) do
    Poker.start_game(socket.assigns.game_id)
    {:noreply, socket}
  end

  def handle_event("ante-changed", %{"ante-value" => ante_value} = _params, socket) do
    socket = assign(socket, :ante, ante_value)
    {:noreply, socket}
  end

  def handle_info(:update, socket) do
    game_id = socket.assigns.game_id
    player = socket.assigns.player

    %Poker.GameState{players: players, game_stage: game_stage, player_turn: player_turn} = Poker.get_game_state(game_id)

    player = find_player(players, player.player_id)
    other_players = players -- [player]

    socket =
      assign(socket, :game_id, game_id)
      |> assign(:game_stage, game_stage)
      |> assign(:player, player)
      |> assign(:other_players, other_players)
      |> assign(:player_turn , player_turn)

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    IO.puts("hi")
    {:noreply, socket}
  end

  def find_player(players, player_id) do
    Enum.find(players, fn %Poker.Player{} = player -> player.player_id == player_id end)
  end

  def render(assigns) do
    ~H"""
    <div style={
      "background-position: center;
      background-image: url(#{~p"/images/background.jpg"});"}>
      <div class="flex flex-col justify-between h-screen p-2">
        <.other_players players={@other_players} game_stage={@game_stage} />
        <%= case assigns do %>
        <% %{game_stage: "LOBBY", player: %{is_host?: true}} -> %>
          <.game_start game_id={@game_id} />
        <% %{game_stage: "LOBBY", player: %{is_host?: false}} -> %>
        <div class="flex justify-center">
          <div class="bg-white p-4 rounded text-center max-w-xs">
            <p class="animate-bounce">Waiting for host to start game...</p>
          </div>
        </div>
        <% _ -> %>
          <.dealer />
        <% end %>
        <.player player={@player} ante={@ante} game_stage={@game_stage} player_turn={@player_turn} />
      </div>
    </div>
    """
  end

  def game_start(assigns) do
    ~H"""
    <form phx-submit="start-game" class="flex justify-center">
      <button
        type="submit"
        name="start-game-button"
        id="start-game-button"
        class="bg-purple-500 p-4 rounded-3xl text-white"
        value={@game_id}
      >
        Start Game
      </button>
    </form>
    """
  end

  def other_players(assigns) do
    ~H"""
    <div class="flex flex-row justify-start sm:justify-center space-x-2 overflow-auto">
      <%= for player <- assigns.players do %>
        <.other_player player={player} game_stage={@game_stage} />
      <% end %>
    </div>
    """
  end

  def card(assigns) do
    card =
      case Map.get(assigns, :card) do
        nil -> %{}
        card -> card
      end

    suit =
      case card.suit do
        nil -> ""
        "spade" -> "♠"
        "heart" -> "♥"
        "diamond" -> "♦"
        "club" -> "♣"
      end

    color =
      case card.suit do
        nil -> ""
        "spade" -> "text-[#000000]"
        "heart" -> "text-[#FF0000]"
        "club" -> "text-[#000000]"
        "diamond" -> "text-[#FF0000]"
      end

    assigns =
      assign(assigns, :color, color)
      |> assign(:suit, suit)
      |> assign(:card, card)

    ~H"""
    <div class="flex flex-col h-16 w-11 sm:w-16 sm:h-24 border shadow-lg justify-between p-1 bg-white">
      <div class="flex flex-row">
        <div class={@color}><%= @suit %><%= @card.value %></div>
      </div>
      <div class="flex flex-row-reverse">
        <div class={@color}><%= @suit %><%= @card.value %></div>
      </div>
    </div>
    """
  end

  def card_back(assigns) do
    ~H"""
    <div class="flex flex-col border shadow-lg rounded p-1.5 h-16 w-11 sm:w-16 sm:h-24 justify-center bg-red-200">
      <img src="/images/card_back.png" class="border-2 border-red-100 rounded" />
    </div>
    """
  end

  def dealer(assigns) do
    ~H"""
    <div class="flex flex-row justify-start sm:justify-center overflow-x-auto space-x-2">
      <div class="flex border shadow-lg rounded p-2 bg-white">
        <div class="flex-col space-y-2">
          <div class="flex-row text-center">Dealer</div>
          <div class="flex flex-row space-x-2 justify-center">
            <.card_back />
            <.card_back />
            <.card_back />
            <.card_back />
            <.card_back />
          </div>
          <div class="flex flex-row space-x-2 justify-evenly">
            <div class="flex flex-col">
              Pot: $12,000
            </div>
            <div class="flex flex-col">
              Side Pot: $1,000
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def player(assigns) do
    ~H"""
    <div class="flex flex-row justify-center space-x-2">
      <div class="flex border shadow-lg rounded p-2 bg-white">
        <div class="flex-col space-y-2">
          <div class="flex-row text-center"><%= @player.name %></div>
          <div class="flex-row bg-gray-300 rounded p-1 text-center">$<%= @player.wallet %></div>
          <%= case assigns do %>
          <% %{game_stage: "LOBBY"} -> %>
            <div></div>
          <% %{player_turn: player_turn} -> %>
            <%= case player_turn == @player.player_id do %>
            <% false -> %>
              <div></div>
            <% true -> %>
              <form>
                <div class="flex-row space-y-1">
                  <button class="bg-[#d1a919] text-neutral-50 w-20 rounded p-1 text-center">Fold</button>
                  <button class="bg-[#d1a919] text-neutral-50 w-20 rounded p-1 text-center">Check</button>
                  <button class="bg-[#d1a919] text-neutral-50 w-20 rounded p-1 text-center">Bet</button>
                  <button class="bg-[#d1a919] text-neutral-50 w-20 rounded p-1 text-center">Call</button>
                  <button class="bg-[#d1a919] text-neutral-50 w-20 rounded p-1 text-center">Raise</button>
                </div>
                <div class="flex flex-row justify-center space-x-2">
                  <input
                    id="ante-slider"
                    name="ante-value"
                    type="range"
                    class="w-full"
                    min="0"
                    max={@player.wallet}
                    value="0"
                    phx-change="ante-changed"
                  />
                  <p id="slider-value" class="w-16">$<%= @ante %></p>
                </div>
              </form>
            <% end %>
            <div class="flex flex-row space-x-2 justify-center">
              <.card card={List.first(@player.hand)} />
              <.card card={List.last(@player.hand)} />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def other_player(assigns) do
    ~H"""
    <div class="flex border shadow-lg rounded p-2 bg-white">
      <div class="flex-col space-y-2">
        <div class="flex-row text-center text-xs sm:text-base"><%= @player.name %></div>
        <div class="flex-row bg-gray-300 rounded p-1 text-center text-xs sm:text-base">
          $<%= @player.wallet %>
        </div>
        <%= if @game_stage == "LOBBY" do %>
        <% else %>
          <div class="flex-row bg-[#c9af8b] rounded p-1 text-center text-xs sm:text-base">
            Next Action
          </div>
          <div class="flex flex-row space-x-2 justify-center">
            <.card_back />
            <.card_back />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
