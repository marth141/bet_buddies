ExUnit.start()

defmodule Poker.PokerTest do
  alias Poker.GameState
  alias Poker.Player
  use ExUnit.Case, async: true

  test "create a sidepot" do
    # Create a game
    # Have three players join a game
    # Player 1 should have 1000
    # Player 2 should have 1000
    # Player 3 should have 275
    # Player 1 bets 1000
    # Player 2 calls for 1000
    # Player 3 all-ins for 275
    # Main pot gains 825 from 275 * 3
    # Side pot is created with the remainder 1175
  end

  test "player cannot call while not their turn" do
    # Add test and logic to prevent players from acting while it's not their turn
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id_a",
               name: "test_player_a"
             })

    assert %GameState{} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b"
             })

    assert %GameState{players: players} = Poker.start_game("test_game_id")
    assert %Player{player_id: player_id} = List.last(players)
    assert :not_players_turn = Poker.call("test_game_id", player_id, "200")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "player cannot bet while not their turn" do
    # Add test and logic to prevent players from acting while it's not their turn
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id_a",
               name: "test_player_a"
             })

    assert %GameState{} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b"
             })

    assert %GameState{players: players} = Poker.start_game("test_game_id")
    assert %Player{player_id: player_id} = List.last(players)
    assert :not_players_turn = Poker.bet("test_game_id", player_id, "200")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "player cannot call while game is not started" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id_a",
               name: "test_player_a"
             })

    assert %GameState{players: players} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b"
             })

    assert %Player{player_id: player_id} = List.first(players)
    assert :game_not_active = Poker.call("test_game_id", player_id, "200")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
  test "player cannot bet while game is not started" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id_a",
               name: "test_player_a"
             })

    assert %GameState{players: players} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b"
             })

    assert %Player{player_id: player_id} = List.first(players)
    assert :game_not_active = Poker.bet("test_game_id", player_id, "20000")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "player starts with 20,000" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert %Poker.GameState{players: [%Poker.Player{wallet: wallet}]} =
             Poker.GameSession.read(pid)

    assert 20000 = wallet
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "player is added to game when game is created" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert %Poker.GameState{players: players} = Poker.GameSession.read(pid)
    assert 1 = length(players)
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "game can be created" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  test "Two shuffled decks are not the same" do
    assert Poker.new_shuffled_deck() != Poker.new_shuffled_deck()
  end

  test "Draw two cards" do
    %{drawn_cards: drawn_cards, new_deck: new_deck} =
      Poker.new_shuffled_deck()
      |> Poker.draw(2)

    assert length(drawn_cards) == 2
    assert length(new_deck) == 50
  end
end
