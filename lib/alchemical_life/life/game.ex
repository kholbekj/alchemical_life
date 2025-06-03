defmodule AlchemicalLife.Life.Game do
  use GenServer

  @grid_size 35
  def grid_size, do: @grid_size

  # Acorn
  @default_grid [[15, 15], [16, 15], [16, 13], [18, 14], [19, 15], [20, 15], [21, 15]]
  def default_grid, do: @default_grid

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_grid do
    GenServer.call(__MODULE__, :get_grid)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def start do
    GenServer.call(__MODULE__, :start)
  end

  def init(args) do
    {:ok, %{grid: args[:grid] || [], running: false}}
  end

  def handle_call(:get_grid, _from, state) do
    {:reply, state.grid, state}
  end

  def handle_call(:reset, _from, _state) do
    # Reset the grid to an empty state
    new_state = %{grid: @default_grid, running: false}
    Phoenix.PubSub.broadcast(AlchemicalLife.PubSub, "game_of_life:updates", {:grid_updated, new_state.grid})
    {:reply, :ok, new_state}
  end

  def handle_call(:start, _from, state) when state.running do
    # If already running, just return
    {:reply, :ok, state}
  end
  def handle_call(:start, _from, state) do
    # Start the game by ticking every second
    Process.send_after(self(), :tick, 1000)
    new_state = %{state | running: true}
    {:reply, :ok, new_state}
  end

  def handle_info(:tick, state) when not state.running do
    # If not ticking, just return without doing anything
    {:noreply, state}
  end
  def handle_info(:tick, state) do

    # Logic to evolve the grid state
    new_grid = evolve_grid(state.grid)

    # Schedule the next tick
    Process.send_after(self(), :tick, 1000)

    # Update the state with the new grid
    new_state = %{state | grid: new_grid}

    Phoenix.PubSub.broadcast(AlchemicalLife.PubSub, "game_of_life:updates", {:grid_updated, new_grid})

    {:noreply, new_state}
  end


  def evolve_grid(grid) do
    # Conways Game of Life rules:
    # 1. Any live cell with fewer than two live neighbors dies (underpopulation).
    # 2. Any live cell with two or three live neighbors lives on to the next generation.
    # 3. Any live cell with more than three live neighbors dies (overpopulation).
    # 4. Any dead cell with exactly three live neighbors becomes a live cell (reproduction).

    neighbors = fn [x, y] ->
      for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0 do
                               [x + dx, y + dy]
      end
    end

    live_neighbors = fn cell ->
      Enum.count(neighbors.(cell), fn n -> Enum.member?(grid, n) end)
    end

    for x <- 0..(@grid_size - 1), y <- 0..(@grid_size - 1) do
      cell = [x, y]
      live_count = live_neighbors.(cell)

      cond do
        Enum.member?(grid, cell) and (live_count < 2 or live_count > 3) -> nil # Cell dies
        Enum.member?(grid, cell) -> cell # Cell lives on
        live_count == 3 -> cell # Cell becomes alive
        true -> nil # Cell remains dead
      end
    end
    |> Enum.reject(&is_nil/1) # Remove nils
  end
end
