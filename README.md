# QDFMS
The Quick and Dirty Freezer Management System 

## Intro 
QDFMS manages items in containers. Items can have categories. Item history is tracked so if you scan something it's seen before, you'll get the data. It also tracks how often an item has been added/removed over a barcode's lifetime, but this trending data isn't exposed in the app UI yet (but you can query Inventory.HistoricalItems in e.g iex) 

This code is pre-pre-pre-alpha, and most certainly contains many bugs. It is not yet packagable as an application but that's up next :P 
This was a fun project to learn about Phoenix Live View, but also because we got sick of not being able to easily recall what's in our chest freezer in the basement. 
The goal was to create an app that would have minimal non-BEAM dependencies.
Eventually, I'll clean it up so you can build a BEAM file that just runs the thing, but now it only works running via mix.


It is an ELixir Umbrella app containing
* Inventory: A Mnesia-backed inventory manager application that supports basic operations on Items, Containers, etc
* Qdfms_web: A web interface for Inventory 

## Use
To use: 
You'll need to configure SSL in app config: 
e.g. run mix phx.gen.cert and update the config in def/config.exs
or update config/config.exs 
Camera access is only allowed via localhost and HTTPS so yeah, you'll need this for barcode to work

To run the webapp:
cd to apps/qdfms_web
run iex -S mix phx.server

go to https://hostname:port/admin to configure:
* Containers - these are the basic categorizations of Items. Items live in a container. A container can be named anything (e.g. "Basement Shelf" or "Box #214") 
* Categories - these are tags that can be applied to an Item. They have a name and an icon. Icons must be .svg format. 
* Devices - Not implemented yet, but will eventually feature into auth (there is no auth!!!)

go to https://hostname:port and choose which container you want to manage. You can scan in barcodes (uses the html5QRCodeScanner JS library) or enter without scanning. If an UPC or barcode identifier isn't found, one will be generated by hashing the name. 

## UI Screen Shots
NOTE: Icons aren't included, but I used the [Lexicon Food Icons pack](https://www.thelexicon.org/foodicons/). 
Category icons are configured at /admin

Admin Category Screen: 
![Category management screen](/blob/master/doc_images/adminCats.png?raw=true "Category Management")

Search Screen: 
![Item search screen](/blob/master/doc_images/Search.png?raw=true "Search Items")

Add Item Screen: 
![Item add screen](/blob/master/doc_images/AddNew.png?raw=true "Add Item")


## Known issues
* You have to click "search" after adding an item, or else the UI gets sad. 
* Sometimes, scanning to add an item won't bring up the add box.
* Can save multiple copies of an item by just continuing to click the save button, this should be an explicit "Create N copies" operation, not a non-validated submit operation. 
* Wight can only be entered in whole numbers 
* Expiry date is required but not validated to exist on the form
* No way to generate QR codes for printing for generated (manually entered) items. This is a TODO so you can print codes for things and manage them easier. Workaround is to generate codes for the item using another tool FIRST then scan them in. 
* Previously entered items don't sync their categories correctly in UI.
