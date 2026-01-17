defmodule Gridroom.Folders do
  @moduledoc """
  The Folders context - manages MDR-style category folders for discussions.

  Folders organize discussions into categorical bins that users can refine through.
  Each folder has its own Oban job for daily topic fetching and tracks per-user
  completion progress.
  """

  import Ecto.Query
  alias Gridroom.Repo
  alias Gridroom.Folders.{Folder, UserFolderProgress}
  alias Gridroom.Grid.Node

  # Folder queries

  @doc """
  Lists all active folders in sort order.
  """
  def list_active_folders do
    Folder
    |> where([f], f.active == true)
    |> order_by([f], f.sort_order)
    |> Repo.all()
  end

  @doc """
  Gets a folder by slug.
  """
  def get_folder_by_slug(slug) do
    Repo.get_by(Folder, slug: slug)
  end

  @doc """
  Gets a folder by ID.
  """
  def get_folder(id), do: Repo.get(Folder, id)

  @doc """
  Creates a new folder.
  """
  def create_folder(attrs) do
    %Folder{}
    |> Folder.changeset(attrs)
    |> Repo.insert()
  end

  # Node-folder relationships

  @doc """
  Lists nodes for a folder on a specific date.
  """
  def list_folder_nodes(folder_id, date) do
    Node
    |> where([n], n.folder_id == ^folder_id and n.folder_date == ^date)
    |> Repo.all()
    |> Repo.preload(:created_by)
  end

  @doc """
  Lists nodes for a folder on today's date.
  """
  def list_todays_folder_nodes(folder_id) do
    list_folder_nodes(folder_id, Date.utc_today())
  end

  @doc """
  Counts nodes in a folder for a specific date.
  """
  def count_folder_nodes(folder_id, date) do
    Node
    |> where([n], n.folder_id == ^folder_id and n.folder_date == ^date)
    |> Repo.aggregate(:count, :id)
  end

  # User progress tracking

  @doc """
  Gets or creates a user's progress record for a folder on a date.
  """
  def get_or_create_progress(user_id, folder_id, date \\ Date.utc_today()) do
    case Repo.get_by(UserFolderProgress, user_id: user_id, folder_id: folder_id, date: date) do
      nil ->
        total = count_folder_nodes(folder_id, date)

        %UserFolderProgress{}
        |> UserFolderProgress.changeset(%{
          user_id: user_id,
          folder_id: folder_id,
          date: date,
          total_count: total,
          refined_count: 0
        })
        |> Repo.insert()

      progress ->
        {:ok, progress}
    end
  end

  @doc """
  Increments the refined count for a user's folder progress.
  Returns {:ok, progress} or {:completed, progress} if folder is now complete.
  """
  def increment_progress(user_id, folder_id, date \\ Date.utc_today()) do
    {:ok, progress} = get_or_create_progress(user_id, folder_id, date)

    new_count = progress.refined_count + 1
    completed? = new_count >= progress.total_count

    attrs =
      if completed? do
        %{refined_count: new_count, completed_at: DateTime.utc_now() |> DateTime.truncate(:second)}
      else
        %{refined_count: new_count}
      end

    case progress
         |> UserFolderProgress.changeset(attrs)
         |> Repo.update() do
      {:ok, updated} ->
        if completed?, do: {:completed, updated}, else: {:ok, updated}

      error ->
        error
    end
  end

  @doc """
  Gets user's progress for all folders on a date.
  Returns a map of folder_id => progress record.
  """
  def get_user_progress_for_date(user_id, date \\ Date.utc_today()) do
    UserFolderProgress
    |> where([p], p.user_id == ^user_id and p.date == ^date)
    |> Repo.all()
    |> Map.new(fn p -> {p.folder_id, p} end)
  end

  @doc """
  Gets folders with user's progress for today.
  Returns list of {folder, progress} tuples where progress may be nil.
  """
  def list_folders_with_progress(user_id, date \\ Date.utc_today()) do
    folders = list_active_folders()
    progress_map = get_user_progress_for_date(user_id, date)

    Enum.map(folders, fn folder ->
      progress = Map.get(progress_map, folder.id)

      # Calculate total if no progress yet
      total =
        if progress do
          progress.total_count
        else
          count_folder_nodes(folder.id, date)
        end

      refined = if progress, do: progress.refined_count, else: 0
      completed? = progress && progress.completed_at != nil

      %{
        folder: folder,
        progress: progress,
        total: total,
        refined: refined,
        completed: completed?
      }
    end)
  end

  @doc """
  Checks if a user has completed a folder for a date.
  """
  def folder_completed?(user_id, folder_id, date \\ Date.utc_today()) do
    UserFolderProgress
    |> where([p], p.user_id == ^user_id and p.folder_id == ^folder_id and p.date == ^date)
    |> where([p], not is_nil(p.completed_at))
    |> Repo.exists?()
  end

  @doc """
  Checks if all folders are completed for a user on a date.
  """
  def all_folders_completed?(user_id, date \\ Date.utc_today()) do
    folder_count =
      Folder
      |> where([f], f.active == true)
      |> Repo.aggregate(:count, :id)

    completed_count =
      UserFolderProgress
      |> where([p], p.user_id == ^user_id and p.date == ^date and not is_nil(p.completed_at))
      |> Repo.aggregate(:count, :id)

    folder_count > 0 and folder_count == completed_count
  end
end
