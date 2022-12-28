defmodule Inventory.Container do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.Container
  require Database.Item

  alias Database.Container
  alias Database.Item

  def create_container(name) do
    Amnesia.transaction do
      %Container{name: name}
      |> Container.write()
    end
  end

  def get_all_containers() do
    Amnesia.transaction do
      Container.stream()
      |> Enum.to_list
    end
  end

  def get_container(id) do
    Amnesia.transaction do
      Container.read(id)
    end
    |> case do
      %Container{} = container-> container
      _ -> {:error, :not_found}
    end
  end

  def get_container_by_name(c_name) do
    Amnesia.transaction do
      Container.where(name == c_name)
      |> Amnesia.Selection.values()
    end
  end

  def get_items_in_container(container) do
    Amnesia.transaction do
      Item.where(container_id == container)
      |> Amnesia.Selection.values()
    end
  end

end
