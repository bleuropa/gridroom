defmodule Gridroom.Resonance do
  @moduledoc """
  Context for managing user resonance (energy/reputation system).

  Resonance is earned through positive contributions and lost through
  negative behavior. Low resonance users face consequences like being
  removed from conversations.

  ## Resonance Levels
  - 0-10: Depleted (kicked from busy nodes, dimmed glyph)
  - 11-30: Low (cannot enter popular nodes)
  - 31-70: Normal (full access)
  - 71-100: Elevated (subtle glow, priority entry)
  - 100+: Radiant (warm aura, trusted status)

  ## Earning Resonance
  - affirm_received: +2 (someone affirmed your message)
  - message_replied: +1 (your message sparked a reply)
  - node_visited: +1 (someone visited your node)
  - node_chat: +2 (conversation in your node)
  - remembered: +5 (someone remembered you)
  - icebreaker: +2 (first to speak in quiet node)
  - exploration: +1 (visiting new nodes)
  - daily_return: +3 (returning after absence)

  ## Losing Resonance
  - dismiss_received: -3 (someone dismissed your message)
  - spam_detected: -5 (rapid-fire messages)
  - abandoned_node: -2 (created node never visited)
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Accounts.User
  alias Gridroom.Resonance.{Transaction, FeedbackCooldown}

  # Resonance amounts for different actions
  @amounts %{
    affirm_received: 2,
    dismiss_received: -3,
    message_replied: 1,
    node_visited: 1,
    node_chat: 2,
    remembered: 5,
    icebreaker: 2,
    exploration: 1,
    daily_return: 3,
    spam_detected: -5,
    abandoned_node: -2
  }

  # Cooldown between feedback on same user (in seconds)
  @feedback_cooldown_seconds 60

  # Resonance thresholds
  @depleted_threshold 10
  @low_threshold 30
  @elevated_threshold 71
  @radiant_threshold 100

  # Min/max resonance
  @min_resonance 0
  @max_resonance 150

  @doc """
  Returns the user's resonance level as an atom.
  """
  def resonance_level(%User{resonance: r}), do: resonance_level_for_value(r)
  def resonance_level(%{resonance: r}), do: resonance_level_for_value(r)

  defp resonance_level_for_value(r) when r <= @depleted_threshold, do: :depleted
  defp resonance_level_for_value(r) when r <= @low_threshold, do: :low
  defp resonance_level_for_value(r) when r < @elevated_threshold, do: :normal
  defp resonance_level_for_value(r) when r < @radiant_threshold, do: :elevated
  defp resonance_level_for_value(_), do: :radiant

  @doc """
  Returns a descriptive string for the user's resonance state.
  For UI display: "Your resonance feels: [state]"
  """
  def resonance_state(%User{} = user) do
    case resonance_level(user) do
      :depleted -> "unstable"
      :low -> "wavering"
      :normal -> "steady"
      :elevated -> "strong"
      :radiant -> "radiant"
    end
  end

  @doc """
  Returns the resonance as a percentage (0-100) for the meter UI.
  Caps at 100 for display purposes even if actual resonance is higher.
  """
  def resonance_percentage(%User{resonance: r}) do
    min(r, 100)
  end

  @doc """
  Affirm a user's message. Gives them +2 resonance.
  Returns {:ok, updated_user} or {:error, reason}.
  """
  def affirm_message(from_user, message) do
    give_feedback(from_user, message, :affirm_received)
  end

  @doc """
  Dismiss a user's message. Costs them -3 resonance.
  Returns {:ok, updated_user} or {:error, reason}.
  """
  def dismiss_message(from_user, message) do
    give_feedback(from_user, message, :dismiss_received)
  end

  defp give_feedback(%User{} = from_user, message, reason) do
    target_user_id = message.user_id

    # Can't give feedback to yourself
    if from_user.id == target_user_id do
      {:error, :cannot_feedback_self}
    else
      # Check cooldown
      case check_feedback_cooldown(from_user.id, target_user_id) do
        :ok ->
          # Apply the resonance change
          amount = @amounts[reason]

          result = Repo.transaction(fn ->
            # Update target user's resonance
            target_user = Repo.get!(User, target_user_id)
            new_resonance = clamp_resonance(target_user.resonance + amount)

            {:ok, updated_user} =
              target_user
              |> Ecto.Changeset.change(resonance: new_resonance)
              |> Repo.update()

            # Record transaction
            %Transaction{}
            |> Transaction.changeset(%{
              user_id: target_user_id,
              amount: amount,
              reason: Atom.to_string(reason),
              source_user_id: from_user.id,
              message_id: message.id,
              node_id: message.node_id
            })
            |> Repo.insert!()

            # Update cooldown
            update_feedback_cooldown(from_user.id, target_user_id)

            updated_user
          end)

          # Broadcast resonance change to the node and to the user personally
          case result do
            {:ok, updated_user} ->
              broadcast_resonance_change(updated_user, message.node_id)
              broadcast_personal_resonance_change(updated_user, amount, reason)
              {:ok, updated_user}

            error ->
              error
          end

        {:error, :cooldown_active} ->
          {:error, :cooldown_active}
      end
    end
  end

  @doc """
  Broadcasts resonance change to a specific node.
  Used to update presence and trigger kick checks.
  """
  def broadcast_resonance_change(%User{} = user, node_id) do
    Phoenix.PubSub.broadcast(
      Gridroom.PubSub,
      "node:#{node_id}",
      {:resonance_changed, user}
    )
  end

  @doc """
  Broadcasts resonance change to the user's personal topic.
  Used to update UI across all their sessions (grid view, etc).
  """
  def broadcast_personal_resonance_change(%User{} = user, amount, reason) do
    Phoenix.PubSub.broadcast(
      Gridroom.PubSub,
      "user:#{user.id}:resonance",
      {:resonance_changed, %{user: user, amount: amount, reason: reason}}
    )
  end

  defp check_feedback_cooldown(user_id, target_user_id) do
    cooldown =
      FeedbackCooldown
      |> where([c], c.user_id == ^user_id and c.target_user_id == ^target_user_id)
      |> Repo.one()

    case cooldown do
      nil ->
        :ok

      %FeedbackCooldown{last_feedback_at: last_at} ->
        seconds_since = DateTime.diff(DateTime.utc_now(), last_at)

        if seconds_since >= @feedback_cooldown_seconds do
          :ok
        else
          {:error, :cooldown_active}
        end
    end
  end

  defp update_feedback_cooldown(user_id, target_user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %FeedbackCooldown{}
    |> FeedbackCooldown.changeset(%{
      user_id: user_id,
      target_user_id: target_user_id,
      last_feedback_at: now
    })
    |> Repo.insert(
      on_conflict: {:replace, [:last_feedback_at]},
      conflict_target: [:user_id, :target_user_id]
    )
  end

  @doc """
  Award resonance for a specific reason.
  Used for non-feedback events like node visits, being remembered, etc.
  """
  def award(%User{} = user, reason, opts \\ []) when is_atom(reason) do
    amount = @amounts[reason] || 0

    if amount == 0 do
      {:ok, user}
    else
      source_user_id = Keyword.get(opts, :source_user_id)
      node_id = Keyword.get(opts, :node_id)

      new_resonance = clamp_resonance(user.resonance + amount)

      {:ok, updated_user} =
        user
        |> Ecto.Changeset.change(resonance: new_resonance)
        |> Repo.update()

      # Record transaction
      %Transaction{}
      |> Transaction.changeset(%{
        user_id: user.id,
        amount: amount,
        reason: Atom.to_string(reason),
        source_user_id: source_user_id,
        node_id: node_id
      })
      |> Repo.insert()

      {:ok, updated_user}
    end
  end

  @doc """
  Penalize user's resonance for a specific reason.
  """
  def penalize(%User{} = user, reason, opts \\ []) when is_atom(reason) do
    # Penalties use the same award function, amounts are already negative
    award(user, reason, opts)
  end

  @doc """
  Check if user's resonance is too low to participate in a node.
  Returns :ok or {:error, :resonance_too_low}
  """
  def can_participate?(%User{} = user) do
    if user.resonance <= @depleted_threshold do
      {:error, :resonance_too_low}
    else
      :ok
    end
  end

  @doc """
  Check if user should be kicked from node due to depleted resonance.
  """
  def should_kick?(%User{resonance: r}), do: r <= @depleted_threshold

  @doc """
  Get recent resonance transactions for a user.
  """
  def recent_transactions(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    Transaction
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], desc: t.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Get user IDs that the given user is currently on feedback cooldown with.
  Returns a MapSet of user IDs.
  """
  def users_on_cooldown(user_id) do
    cutoff = DateTime.utc_now() |> DateTime.add(-@feedback_cooldown_seconds, :second)

    FeedbackCooldown
    |> where([c], c.user_id == ^user_id and c.last_feedback_at > ^cutoff)
    |> select([c], c.target_user_id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Get message IDs that the user has given feedback on in a specific node.
  Returns a map of %{message_id => feedback_type} where feedback_type is "affirm" or "dismiss".
  """
  def user_feedback_in_node(user_id, node_id) do
    Transaction
    |> where([t], t.source_user_id == ^user_id and t.node_id == ^node_id)
    |> where([t], t.reason in ["affirm_received", "dismiss_received"])
    |> where([t], not is_nil(t.message_id))
    |> select([t], {t.message_id, t.reason})
    |> Repo.all()
    |> Map.new(fn {msg_id, reason} ->
      type = if reason == "affirm_received", do: :affirm, else: :dismiss
      {msg_id, type}
    end)
  end

  @doc """
  Get the resonance thresholds for UI display.
  """
  def thresholds do
    %{
      depleted: @depleted_threshold,
      low: @low_threshold,
      elevated: @elevated_threshold,
      radiant: @radiant_threshold,
      max: @max_resonance
    }
  end

  defp clamp_resonance(value) do
    value
    |> max(@min_resonance)
    |> min(@max_resonance)
  end
end
