# QDFMS
The Quick and Dirty Freezer Management System 

## Quickstart (Docker)
This will get you up and running in a container using a self-signed cert 

1. Download the Dockerfile 
1.  `docker build -t qdfms .`
1. `docker run -it -p 8443:443 --name qdfms qdfms` 
1. Point your browser to `https://localhost:8443 `
1. Follow along with the [User Guide](/UserGuide.md) (Do the admin step)

To restart the container (and get an iex shell, if you don't want that omit the `i`), 
`  docker start -ai qdfms`


## Intro 
QDFMS manages items in containers. Items can have categories. Item history is tracked so if you scan something it's seen before, you'll get the data. It also tracks how often an item has been added/removed over a barcode's lifetime, but this trending data isn't exposed in the app UI yet (but you can query Inventory.HistoricalItems in e.g iex - see [Other Data Operatoins](#other-data-operations)

This code is pre-pre-pre-alpha, and most certainly contains many bugs. It is not yet packagable as an application but that's up next :P 
This was a fun project to learn about Phoenix Live View, but also because we got sick of not being able to easily recall what's in our chest freezer in the basement. See the [Known Issues](#known-issues) section.

The goal was to create an app that would have minimal non-BEAM dependencies, which is why mnesia was chosen for persistance - it's part of the Erlang/OTP release. 

QDFMS uses the [mebjas-html5-qrcode library](https://github.com/mebjas/html5-qrcode) in the client to support barcode scanning. It's not linked in particularly well because I ran into an issue including it in app.js that I haven't spent time resolving :P 

Eventually, I'll clean it up so you can build a BEAM file that just runs the thing, but now its only tested running via mix.


#### About the app 
This app was built on Erlang/OTP 25 and Elixir 1.13

It is an ELixir Umbrella app containing
* [Inventory](/app/qdfms/apps/inventory): A Mnesia-backed inventory manager application that supports basic operations on Items, Containers, etc
* [qdfms_web](/app/qdfms/apps/qdfms_web): A web interface for Inventory 

[Data Model](/app/qdfms) 

## Use and Setup
### Elixir Dependencies 
QDFMS needs Elixir 1.13+ and has been tested with Erlang/OTP 25. How you install Elixir/Erlang is up to you; I'm running on a RaspberryPI using the Erlang Solutions repositories and its `esl-erlang` and `elixir` packages. If you're on debian/raspian:

```
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update
sudo apt install esl-erlang
sudo apt install elixir
```
should get you up and running! 

QDFMS needs a few dependencies (mainly phoenix and its dependencies) in order to run. To fetch them do:
```
cd app/qdfms/
mix deps.get 
```
### Config
You'll need to do some small setup items to run it... 
#### Database
QDFMS uses mnesia, which is part of the Erlang/OTP distribution. Before running you'll need to tell the app where to find/create the database disk files. This is the first config option in  /app/qdfms/config/config.esx
```
config :mnesia, dir: to_charlist("/var/qdfms/db/Mnesia.nonode@nohost")
```

**Make sure this directory is writable by whatever user/group you'll be running the app as**

Then cd to /app/qdfms/apps/inventory and run 
`mix amnesia.create -d Database --disk` 
This will create the disk-backed tables for the app 

#### SSL 
You'll need to configure SSL in app config. 

Camera access is only allowed via localhost and HTTPS so yeah, you'll need this for barcode scanning to work. (you could also throw it behind a proxy... but that would add an external component) 

See: [Using SSL](https://hexdocs.pm/phoenix/using_ssl.html)

If you don't minnd a self-signed cert

cd to `/apps/qdfms_web` and run `mix phx.gen.cert` and update the config in def/config.exs like:
```
...
  https: [
    port: 4001,
    cipher_suite: :strong,
    keyfile: "priv/cert/selfsigned_key.pem",
    certfile: "priv/cert/selfsigned.pem"
  ]
```
Finally, copy the html5-qrcode from `/assets/vendor/html5-qrcode.min.js` to `/priv/static/assets`. 

That's it for the non-in-app configuration. The next bits will be done within the webapp: 

### Running
To run the webapp:

cd to `app/qdfms/apps/qdfms_web`

run `iex -S mix phx.server`

This operation may take a while the first time as files are compiled and checked. 


#### Setting up Containers and Categories 
go to https://hostname:port/admin to configure:
* Containers - these are the basic categorizations of Items. Items live in a container. A container can be named anything (e.g. "Basement Shelf" or "Box #214") 
* Categories - these are tags that can be applied to an Item. They have a name and an icon. Icons must be .svg format. 
* Devices - Not implemented yet, but will eventually feature into auth (there is no auth!!!)

#### Managing Containers 
go to https://hostname:port and choose which container you want to manage. You can scan in barcodes (uses the html5QRCodeScanner JS library) or enter without scanning. If an UPC or barcode identifier isn't found, one will be generated by hashing the name. 

## User Guide
The [User Guide](/UserGuide.md) should give you a good idea how the system is used. 

## UI Screen Shots
NOTE: Icons aren't included, but I used the [Lexicon Food Icons pack](https://www.thelexicon.org/foodicons/). 
Category icons are configured at /admin

Admin Category Screen: 
![Category management screen](/doc_images/adminCats.png?raw=true "Category Management")

Search Screen: 
![Item search screen](/doc_images/Search.png?raw=true "Search Items")

Add Item Screen: 
![Item add screen](/doc_images/AddNew.png?raw=true "Add Item")

## Backup and Restore
Since QDFMS uses mnesia, you can do backups and restores by calling mnesia's builtin functions from an IEX session. 

To backup the database to `/tmp/backup.db` do `:mnesia.backup('/tmp/backup.db')` 

To restore the database, do: `:mnesia.restore('/tmp/backup.db',[{:default_op,:clear_tables}])`

The restore command assumes the database exists. 

If you're starting over completely, you'll need to run a `mix amnesia.create -d Database --disk` first in the Inventory app. 
```
cd /apps/inventory
mix amnesia.create -d Database --disk
...
iex -S mix
iex(1)> :mnesia.restore('/tmp/backup.db',[{:default_op,:clear_tables}])
{:atomic,
 [Database.HistoricalItem, Database.RegisteredDevice, Database.Item,
  Database.Category, Database.Container, Database.ItemCategory, Database]}
  
```

For more info see the [mnesia documentation](https://www.erlang.org/doc/man/mnesia.html#restore-2)

## Known issues
* You have to click "search" after adding an item, or else the UI gets sad. (Believe this may be fixed?)
* Sometimes, scanning to add an item won't bring up the add box. (Believe this may be fixed )
* Can save multiple copies of an item by just continuing to click the save button, this should be an explicit "Create N copies" operation, not a non-validated submit operation. 
* Wight can only be entered in whole numbers 
* Expiry date is required but not validated to exist on the form
* No way to generate QR codes for printing for generated (manually entered) items. This is a TODO so you can print codes for things and manage them easier. Workaround is to generate codes for the item using another tool FIRST then scan them in. You can also view an item to get it's "UPC" (generic field name for any scanned barcode, even if it's not actually a UPC) and use whatever tool you want to generate a barcode you like (and is [supported](https://github.com/mebjas/html5-qrcode#supported-code-formats) by the scanning library) 
* Previously entered items don't sync their categories correctly in UI. (fixed in bfb64d3)
* Some features in the backend such as searching by weight (with auto-conversion) aren't exposed in the webUI. 
* On desktop devices, scanning things that aren't QR codes might not work see below:

### Desktop scanning and non QR codes
in `app\qdfms\apps\qdfms_web\lib\qdfms_web\live\home_live.ex` you'll want to find all instances of the `let html5QrcodeScanner = new Html5QrcodeScanner(` block and change:

```
showTorchButtonIfSupported: true
```
to 
```
showTorchButtonIfSupported: true,
useBarCodeDetectorIfSupported: false
```
to force use of non browser decoding 

## Examples of using the backend 
If you're running the app using `iex -S mix phx.server`, you can query some things that aren't available via the web UI
### Mass Search
If you want to do things that aren't yet in the UI, like searching by mass, 
You can do this operation by calling `filter_items_by_category_weight(category, weight, container, comp)` where:
` category` is the category ID as an integer, `weight` is the weight as an `%ExUc.Value{}`, `container` is the container ID as an integer and `comp` is a comparison atom like `:lt` or `:gt`
So `filter_items_by_category_weight(1,%ExUc.Value{kind: :mass, unit: :oz, value: 16},2,:gt)` will give you all items that are associated with the cateogry whoose ID is 1, and in container 2, and have a weight more than 16Oz. This oepration converts the item weight and the input weight to grams before doing the comparison, so it's theoritically unit-aware. 

### Trend / History
The Inventory.HistoricalItems module keeps track of seen items, their categories, and how often they've been added or removed. 
```
Inventory.HistoricalItems.
create_from_item/1          decrement_count/1
delete_record/1             find_item_by_upc/1
get_categories/1            get_categories_raw/1
get_historical_item/1       increment_count/1
update_item_categories/2
```
The object looks like:
```
%Database.HistoricalItem{
  categories: [
    %Database.ItemCategory{category_id: 1, item_id: 1},
    %Database.ItemCategory{category_id: 3, item_id: 1}
  ],
  description: "Item Description",
  id: 1,
  name: "Item Name",
  photo: base64Encodedblob,
  times_added: 3,
  times_removed: 4,
  upc: "FOOBARBAZ",
  weight: %ExUc.Value{kind: :mass, unit: :kg, value: 100.0}
}
```
Updating the categories /should/ happen automatically, but you can call `Inventory.Items.sync_categories_history(id)` to sync the item with ID to its HistoricalItem record. 

### Moving items between containers
This is ugly and should be part of the webapp, but it's not yet. 
This example takes all items from container 3, with an ID > 14 and changes their container_id to 2
```
items_mod = Inventory.Items.get_items_in_container(3) |> Enum.filter(&(&1.id > 14)) |> Enum.map(fn x -> %{x | container_id: 2} end)
for item <- items_mod, do: item |> Database.Item.write!()
```
### Other data operations
The data is all maps, basically, so you can do some pretty powerful manipulation of the data if you want. 

If you have a list of items that you want to change the categories of, `update_categories_items(item, list_of_category_ids)` let's you do that.  

To get category names and IDs, use `Inventory.Category.get_all_categories |> Enum.map(&({&1.id, &1.name}))` and pick the IDs to populate a list of category_ids you want to assign, then: 
```
category_ids = [1,2,3]
for item <- items, do: Inventory.Items.update_categories_items(item, list_of_category_ids)
```
or, perhaps you want to change anything in container 3 with the name containing "frozen ground beef" to have a UPC of "DEAD00BEEF":
```
items_mod = Inventory.Items.get_items_in_container(3) |> Enum.filter(&(String.contains?(&1.name, "frozen ground beef")) |> Enum.map(fn x -> %{x | upc: "DEAD00BEEF"} end)
for item <- items_mod, do: item |> Database.Item.write!()
```
etc. 

Remember - this bypasses HistoricalItems so you may need make calls to `Inventory.HistoricalItems.create_from_item(item)` or other functions to reconcile your manual changes. 
