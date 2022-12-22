defmodule Inventory.Items do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.Item
  require Database.Category
  require Database.ItemCategory

  alias Database.Item
  alias Database.Category
  alias Database.ItemCategory

  def create_item(container, upc, name, description, mfr_exp_date, date_added, weight, photo) do
    item = Amnesia.transaction do
      date_added = if is_nil(date_added), do: Date.utc_today, else: date_added
      upc = if is_nil(upc), do: :crypto.hash(:md5, name) |> Base.encode16(), else: upc
      mfr_exp_date = if is_nil(mfr_exp_date), do: Date.add(date_added, 30), else: mfr_exp_date
      item = %Item{name: name, description: description, upc: upc, photo: photo, mfr_exp_date: mfr_exp_date, date_added: date_added, weight: weight, container_id: container}
      |> Item.write()
    end
    Inventory.HistoricalItems.increment_count(item)
    item
  end

  def create_item(%Database.Item{} = item) do
    create_item(item.container_id, item.upc, item.name, item.description, item.mfr_exp_date, item.date_added, item.weight, item.photo)
  end

  def remove_item(id) do
    Amnesia.transaction do
      get_item(id)
      |> case do
        {:error, _ } -> {:error, :item_not_found}
        %Item{} = item ->
          item |> Item.delete()
          Inventory.HistoricalItems.decrement_count(item)
          item
      end
    end
  end

  def get_item(id) do
    Amnesia.transaction do
      Item.read(id)
    end
    |> case do
      %Item{} = item-> item
      _ -> {:error, :not_found}
    end
  end

  def find_item_by_upc(item_upc) do
    Amnesia.transaction do
      Item.where(upc == item_upc)
      |> Amnesia.Selection.values()
    end
  end

  def find_exp_items() do
    Amnesia.transaction do
      Item.stream
      |> Enum.filter(fn %Database.Item{} = x -> Date.compare(x.mfr_exp_date, Date.utc_today) == :lt end)
    end
  end

  def find_exp_items(container) do
    Amnesia.transaction do
      Item.stream
      |> Enum.filter(fn %Database.Item{} = x -> x.container_id == container)
      |> Enum.filter(fn %Database.Item{} = x -> Date.compare(x.mfr_exp_date, Date.utc_today) == :lt end)
    end
  end

  def find_items_older_than(days) do
    Amnesia.transaction do
      target_date = Date.add(Date.utc_today, -1* days)
      Item.stream
      |> Enum.filter(fn %Database.Item{} = x -> Date.compare(x.date_added, target_date) == :lt end)
    end
  end

  def find_items_older_than(days, container) do
    Amnesia.transaction do
      target_date = Date.add(Date.utc_today, -1* days)
      Item.stream
      |> Enum.filter(fn %Database.Item{} = x -> x.container_id == container)
      |> Enum.filter(fn %Database.Item{} = x -> Date.compare(x.date_added, target_date) == :lt end)
    end
  end

  def find_items_by_category(cat_id) do
    Amnesia.transaction do
      ItemCategory.where(category_id == cat_id)
      |> Amnesia.Selection.values()
      |> Enum.map(fn %Database.ItemCategory{} = x -> get_item(x.item_id) end )
    end
  end

  def add_category_item(item, category) do
    cat = Amnesia.transaction do
      ItemCategory.where(item_id == item)
      |> Amnesia.Selection.values()
      |> Enum.filter(fn %Database.ItemCategory{} = x -> x.category_id == category end)
      |> case do
        [x|_] -> :ok
        [] ->  %ItemCategory{item_id: item, category_id: category} |> ItemCategory.write()
      end
    end
    sync_categories_history(item)
    cat
  end

  def sync_categories_history(id) do
    item = get_item(id)
    categories = get_categories_raw(id)
    Inventory.HistoricalItems.update_item_categories(item.upc, categories)
  end

  def remove_category_item(item,category) do
    cat = Amnesia.transaction do
      %ItemCategory{item_id: item, category_id: category}
      |> ItemCategory.delete()
    end
    sync_categories_history(item)
    cat
  end

  def get_items_in_container(container) do
    Amnesia.transaction do
      Item.where(container_id == container)
      |> Amnesia.Selection.values()
    end
  end

  def get_item_container(item_id) do
    get_item(item_id)
    |> case do
      {:error, _} -> {:error, :item_not_found}
      %Item{} = item-> Inventory.Container.get_container(item.container_id)
    end
  end

  def get_categories_raw(item) do
    Amnesia.transaction do
      ItemCategory.where(item_id == item)
      |> Amnesia.Selection.values()
    end
  end

  def get_categories(item) do
    get_categories_raw(item)
    |> Enum.map(
      fn %Database.ItemCategory{} = x ->
        Inventory.Category.get_category(x.category_id)
      end
    )
  end

end
