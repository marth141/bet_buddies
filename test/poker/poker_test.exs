ExUnit.start()

defmodule Poker.PokerTest do
  use ExUnit.Case, async: true

  alias Ecto.UUID
  alias Poker.GameState
  alias Poker.Player

  describe "create_game/2" do
    test "successfully create a game" do
      game_id = UUID.generate()

      player = %Player{
        player_id: UUID.generate(),
        name: "test_player_a"
      }

      assert {:ok, _pid} = Poker.create_game(game_id, player)
    end
  end

  describe "start_game/1" do
    test "successfully start a game" do
      game_id = UUID.generate()

      player_a = %Player{
        player_id: UUID.generate(),
        name: "test_player_a"
      }

      player_b = %Player{
        player_id: UUID.generate(),
        name: "test_player_b"
      }

      assert {:ok, _pid} = Poker.create_game(game_id, player_a)

      Poker.join_game(game_id, player_b)

      assert %GameState{} = Poker.start_game(game_id)
    end
  end

  describe "all_in/2" do
    setup do
      players = [
        %Player{
          player_id: UUID.generate(),
          name: "test_player_a",
          wallet: 2000
        },
        %Player{
          player_id: UUID.generate(),
          name: "test_player_b",
          wallet: 2000
        },
        %Player{
          player_id: UUID.generate(),
          name: "test_player_c",
          wallet: 2000
        },
        %Player{
          player_id: UUID.generate(),
          name: "test_player_d",
          wallet: 2000
        }
      ]

      [player_a | players_to_add] = players

      game_id = UUID.generate()
      Poker.create_game(game_id, player_a)

      players_to_add
      |> Enum.each(&Poker.join_game(game_id, &1))

      %{
        game_id: game_id,
        players: players
      }
    end

    test "player successfully all ins", %{game_id: game_id, players: players} do
      Poker.start_game(game_id)

      [player_a = %Player{} | _tail] = players

      assert %GameState{} = Poker.all_in(game_id, player_a.player_id)
    end
  end

  test "create a sidepot" do
    # Create a game
    # Player 1 should have 1000
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id_a",
               name: "test_player_a",
               wallet: 2000
             })

    # Have three players join a game
    # Player 2 should have 1000
    assert %GameState{} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b",
               wallet: 2000
             })

    # Player 3 should have 275
    assert %GameState{} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_c",
               name: "test_player_c",
               wallet: 275
             })

    # Start game
    assert %GameState{players: players} = Poker.start_game("test_game_id")
    # Player 1 bets 1000
    assert %Player{player_id: player_id} = Enum.at(players, 0)
    %GameState{} = Poker.bet("test_game_id", player_id, "1000")
    # Player 2 calls for 1000
    assert %Player{player_id: player_id} = Enum.at(players, 1)
    %GameState{} = Poker.call("test_game_id", player_id, "1000")
    # Player 3 all-ins for 275
    assert %Player{player_id: player_id} = Enum.at(players, 2)
    %GameState{} = Poker.all_in("test_game_id", player_id)
    # Main pot gains 825 from 275 * 3
    # Side pot is created with the remainder 1175
    # Terminate game
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
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
    assert %Player{player_id: player_id} = List.first(players)
    assert :not_players_turn = Poker.call("test_game_id", player_id, "200")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
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
    assert %Player{player_id: player_id} = List.first(players)
    assert :not_players_turn = Poker.bet("test_game_id", player_id, "200")
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
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

  @tag run: true
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

  @tag run: true
  test "joined player is not host" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert %GameState{players: players} =
             Poker.join_game("test_game_id", %Player{
               player_id: "test_player_id_b",
               name: "test_player_b"
             })

    assert %Player{is_host?: is_host} = List.first(players)
    assert false == is_host
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
  test "first player added is host" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert %Poker.GameState{players: players} = Poker.GameSession.read(pid)
    assert %Player{is_host?: is_host} = List.first(players)
    assert true == is_host
    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
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

  @tag run: true
  test "game can be created" do
    assert {:ok, pid} =
             Poker.create_game("test_game_id", %Player{
               player_id: "test_player_id",
               name: "test_player"
             })

    assert :ok = DynamicSupervisor.terminate_child(Poker.GameSupervisor, pid)
  end

  @tag run: true
  test "Two shuffled decks are not the same" do
    assert Poker.new_shuffled_deck() != Poker.new_shuffled_deck()
  end

  @tag run: true
  test "Draw two cards" do
    %{drawn_cards: drawn_cards, new_deck: new_deck} =
      Poker.new_shuffled_deck()
      |> Poker.draw(2)

    assert length(drawn_cards) == 2
    assert length(new_deck) == 50
  end
end
