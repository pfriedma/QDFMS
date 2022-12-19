defmodule Inventory.Category do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.Item
  require Database.Category
  require Database.ItemCategory

  alias Database.Item
  alias Database.Category
  alias Database.ItemCategory

  def create_category(name, icon) do
    Amnesia.transaction do
      %Category{name: name, image: icon}
      |> Category.write()
    end
  end


  def get_category(id) do
    Amnesia.transaction do
      Category.read(id)
    end
    |> case do
      %Category{} = category-> category
      _ -> {:error, :not_found}
    end
  end

  def find_category_by_name(c_name) do
    Amnesia.transaction do
      Category.where(name == c_name)
      |> Amnesia.Selection.values()
    end
  end



end
