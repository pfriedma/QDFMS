# Qdfms

**TODO: Add description**

Data model for Inventory: 
```
%Database.Item{
  container_id: 1,
  date_added: ~D[2022-12-18],
  description: "String",
  id: 2,
  mfr_exp_date: ~D[2022-12-19],
  name: "String",
  photo: base64EncodedData,
  upc: "B7F274EC1D1C9A1483A213737807CB69",
  weight: %ExUc.Value{kind: :mass, unit: :kg, value: 1.0}
}

%Database.Container{id: 1, name: "That annoying shelf"}

%Database.Category{
  id: 1,
  image: base64EncodedPNGData
  name: string
}

%Database.ItemCategory{category_id: 1, item_id: 1}
 
%Database.HistoricalItem{
  categories: [
    %Database.ItemCategory{category_id: 1, item_id: 1},
    %Database.ItemCategory{category_id: 3, item_id: 1}
  ],
  description: "string",
  id: 1,
  name: "string",
  photo: base64EncodedPNGdata,
  times_added: 3,
  times_removed: 4,
  upc: "string",
  weight: %ExUc.Value{kind: :mass, unit: :kg, value: 100.0}
}
```

