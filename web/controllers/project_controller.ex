defmodule Triage.ProjectController do
  use Triage.Web, :controller

  alias Triage.Project

  def index(conn, _params) do
    projects = Repo.all(Project)
                |> Repo.preload(states: from(s in Triage.State, order_by: [desc: s.inserted_at]))
    render(conn, "index.html", projects: projects)
  end

  def new(conn, _params) do
    changeset = Project.changeset(%Project{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"project" => project_params}) do
    changeset = Project.changeset(%Project{}, project_params)

    case Repo.insert(changeset) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, "Project created successfully.")
        |> redirect(to: project_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)
              |> Repo.preload(states: from(s in Triage.State, order_by: [desc: s.inserted_at], limit: 1))
    render(conn, "show.html", project: project)
  end

  def edit(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project)
    render(conn, "edit.html", project: project, changeset: changeset)
  end

  def triage(conn, %{"project_id" => id }) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, %{triaged_at: Ecto.DateTime.utc})
    case Repo.update(changeset) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, "Updated triage time for #{project.organization}/#{project.name}")
        |> redirect(to: project_path(conn, :index))
      {:error, _cs} ->
        conn
        |> put_flash(:info, "Failed to set triage time for #{project.organization}/#{project.name}")
    end
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project updated successfully.")
        |> redirect(to: project_path(conn, :show, project))
      {:error, changeset} ->
        render(conn, "edit.html", project: project, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Repo.get!(Project, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(project)

    conn
    |> put_flash(:info, "Project deleted successfully.")
    |> redirect(to: project_path(conn, :index))
  end
end
