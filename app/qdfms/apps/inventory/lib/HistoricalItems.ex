defmodule Inventory.HistoricalItems do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.Item
  require Database.HistoricalItem
  require Database.ItemCategory

  alias Database.Item
  alias Database.HistoricalItem
  alias Database.Category
  alias Database.ItemCategory

  #     [{:id, autoincrement}, :name, :description, :upc, :photo, :times_added, :times_removed, :weight, :categories],


  def create_from_item(item) do
    Amnesia.transaction do
        %Item{} = item
        categories = Inventory.Items.get_categories_raw(item.id)
        %HistoricalItem{name: item.name, description: item.description, upc: item.upc, photo: item.photo,
                        weight: item.weight, times_added: 0, times_removed: 0, categories: categories}
                        |> HistoricalItem.write()
    end
  end

  def decrement_count(%Item{} = item) do
    Amnesia.transaction do
      HistoricalItem.where(upc == item.upc)
      |> Amnesia.Selection.values()
      |> Enum.map( fn %HistoricalItem{} = x -> inc_remove_count(x) end)
    end
  end

  def increment_count(%Item{} = item) do
    Amnesia.transaction do
      HistoricalItem.where(upc == item.upc)
      |> Amnesia.Selection.values()
      |> case do
        [x|_] -> x
        [] -> create_from_item(item)
      end
      |> inc_seen_count()
    end
  end

  def update_item_categories(hist_item_upc, categories) do
    Amnesia.transaction do
      HistoricalItem.where(upc == hist_item_upc)
      |> Amnesia.Selection.values()
      |> Enum.map(fn %HistoricalItem{} = x -> update_categories(x, categories) end)
    end
  end

  def delete_record(id) do
    Amnesia.transaction do
      get_historical_item(id)
      |> case do
        {:error, _ } -> {:error, :item_not_found}
        %HistoricalItem{} = item -> item |> HistoricalItem.delete()
      end
    end
  end

  def get_historical_item(id) do
    Amnesia.transaction do
      HistoricalItem.read(id)
    end
    |> case do
      %HistoricalItem{} = item-> item
      _ -> {:error, :not_found}
    end
  end

  def find_item_by_upc(item_upc) do
    Amnesia.transaction do
      HistoricalItem.where(upc == item_upc)
      |> Amnesia.Selection.values()
    end
  end


  def get_categories_raw(id) do
    get_historical_item(id)
    |> case do
      {:error, _} -> {:error, :item_not_found}
      %HistoricalItem{} = item -> item.categories
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

  defp inc_remove_count(%HistoricalItem{} = item) do
    item
    |> Map.update!(:times_removed, &(&1 +1))
    |> HistoricalItem.write()
  end

  defp inc_seen_count(%HistoricalItem{} = item) do
    item
    |> Map.update!(:times_added, &(&1 +1))
    |> HistoricalItem.write()
  end

  defp update_categories(%HistoricalItem{} = item, categories) do
    item
    |> Map.update!(:categories, &(&1 = categories))
    |> HistoricalItem.write()
  end
end
