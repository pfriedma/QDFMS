use Amnesia

defdatabase Database do
  deftable(
    Item,
    [{:id, autoincrement}, :name, :description, :upc, :photo, :mfr_exp_date, :date_added, :weight, :container_id],
    type: :set,
    index: [:name]
  )
  deftable(
    Container,
    [{:id, autoincrement}, :name],
    type: :set,
    index: [:name]
  )
  deftable(
    Category,
    [{:id, autoincrement}, :name, :image,],
    type: :set,
    index: [:name]
  )
  deftable(
    ItemCategory,
    [:item_id, :category_id],
    type: :bag,
    index: [:category_id]
  )
  deftable(
    RegisteredDevice,
    [{:id, autoincrement}, :device_id, :container_id],
    type: :set,
    index: [:device_id]
  )
  deftable(
    HistoricalItem,
    [{:id, autoincrement}, :name, :description, :upc, :photo, :times_added, :times_removed, :weight, :categories],
    type: :set,
    index: [:upc]
  )
end
